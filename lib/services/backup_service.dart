import 'dart:io';
import '../models/backup_info.dart';

/// Service for managing configuration file backups
class BackupService {
  /// Default backup directory suffix
  static const String backupDirName = '.yabai-config-backups';

  /// Maximum number of backups to keep per file
  final int maxBackups;

  /// Whether to use a dedicated backup directory
  final bool useBackupDirectory;

  /// Custom backup directory path
  final String? backupDirectory;

  BackupService({
    this.maxBackups = 10,
    this.useBackupDirectory = false,
    this.backupDirectory,
  });

  /// Get the backup directory path
  String get _backupDir {
    if (backupDirectory != null) return backupDirectory!;
    final home = Platform.environment['HOME'] ?? '/tmp';
    return '$home/$backupDirName';
  }

  /// Ensure backup directory exists
  Future<void> _ensureBackupDirExists() async {
    if (useBackupDirectory) {
      final dir = Directory(_backupDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Create a backup of a file
  /// Returns the BackupInfo for the created backup
  Future<BackupInfo> createBackup(String filePath, {String? description}) async {
    final sourceFile = File(filePath);
    
    if (!await sourceFile.exists()) {
      throw BackupException('Source file does not exist: $filePath');
    }

    await _ensureBackupDirExists();

    final timestamp = DateTime.now();
    final backupPath = _generateBackupPath(filePath, timestamp);

    try {
      // Copy the file to backup location
      await sourceFile.copy(backupPath);

      // Get file size
      final stat = await File(backupPath).stat();

      final backupInfo = BackupInfo(
        path: backupPath,
        timestamp: timestamp,
        originalPath: filePath,
        description: description,
        sizeBytes: stat.size,
      );

      // Clean up old backups if we exceed the limit
      await _cleanupOldBackups(filePath);

      return backupInfo;
    } catch (e) {
      throw BackupException('Failed to create backup: $e');
    }
  }

  /// Generate backup file path
  String _generateBackupPath(String originalPath, DateTime timestamp) {
    if (useBackupDirectory) {
      // Store in backup directory with full original path encoded
      final fileName = originalPath.split('/').last;
      final tsStr = _formatTimestamp(timestamp);
      return '$_backupDir/$fileName.backup.$tsStr';
    } else {
      // Store alongside original file
      return BackupInfo.generateBackupPath(originalPath, timestamp);
    }
  }

  /// Format timestamp for backup filename
  String _formatTimestamp(DateTime ts) {
    return '${ts.year}${_pad(ts.month)}${_pad(ts.day)}_'
        '${_pad(ts.hour)}${_pad(ts.minute)}${_pad(ts.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// List all backups for a given original file
  Future<List<BackupInfo>> listBackups(String originalPath) async {
    final backups = <BackupInfo>[];
    final fileName = originalPath.split('/').last;

    // Check backup directory if using one
    if (useBackupDirectory) {
      final dir = Directory(_backupDir);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = entity.path.split('/').last;
            if (name.startsWith('$fileName.backup.')) {
              final info = await _parseBackupFile(entity.path, originalPath);
              if (info != null) {
                backups.add(info);
              }
            }
          }
        }
      }
    }

    // Also check for backups alongside original file
    final dir = Directory(originalPath.substring(0, originalPath.lastIndexOf('/')));
    if (await dir.exists()) {
      final pattern = RegExp(r'^\.' + RegExp.escape(fileName) + r'\.backup\.\d{8}_\d{6}$');
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (pattern.hasMatch(name)) {
            final info = await _parseBackupFile(entity.path, originalPath);
            if (info != null && !backups.any((b) => b.path == info.path)) {
              backups.add(info);
            }
          }
        }
      }
    }

    // Sort by timestamp, newest first
    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return backups;
  }

  /// Parse backup file to get BackupInfo
  Future<BackupInfo?> _parseBackupFile(String backupPath, String originalPath) async {
    final file = File(backupPath);
    if (!await file.exists()) return null;

    final info = BackupInfo.fromBackupPath(backupPath, originalPath);
    if (info == null) return null;

    // Get file size
    final stat = await file.stat();
    return info.copyWith(sizeBytes: stat.size);
  }

  /// Restore a backup to its original location
  Future<void> restoreBackup(BackupInfo backup, {bool createBackupFirst = true}) async {
    final backupFile = File(backup.path);
    
    if (!await backupFile.exists()) {
      throw BackupException('Backup file does not exist: ${backup.path}');
    }

    final originalFile = File(backup.originalPath);

    try {
      // Optionally create a backup of current file before restoring
      if (createBackupFirst && await originalFile.exists()) {
        await createBackup(backup.originalPath, description: 'Pre-restore backup');
      }

      // Copy backup to original location
      await backupFile.copy(backup.originalPath);
    } catch (e) {
      throw BackupException('Failed to restore backup: $e');
    }
  }

  /// Delete a specific backup
  Future<void> deleteBackup(BackupInfo backup) async {
    final file = File(backup.path);
    
    if (!await file.exists()) {
      return; // Already deleted
    }

    try {
      await file.delete();
    } catch (e) {
      throw BackupException('Failed to delete backup: $e');
    }
  }

  /// Delete all backups for a given original file
  Future<int> deleteAllBackups(String originalPath) async {
    final backups = await listBackups(originalPath);
    int deleted = 0;

    for (final backup in backups) {
      try {
        await deleteBackup(backup);
        deleted++;
      } catch (e) {
        // Continue with other deletions
      }
    }

    return deleted;
  }

  /// Clean up old backups, keeping only the most recent ones
  Future<void> _cleanupOldBackups(String originalPath) async {
    if (maxBackups <= 0) return; // No limit

    final backups = await listBackups(originalPath);
    
    if (backups.length > maxBackups) {
      // Sort by timestamp, newest first (already sorted by listBackups)
      final toDelete = backups.skip(maxBackups);
      
      for (final backup in toDelete) {
        try {
          await deleteBackup(backup);
        } catch (e) {
          // Continue with other deletions
        }
      }
    }
  }

  /// Get the most recent backup for a file
  Future<BackupInfo?> getLatestBackup(String originalPath) async {
    final backups = await listBackups(originalPath);
    return backups.isNotEmpty ? backups.first : null;
  }

  /// Compare a backup with the current file
  Future<BackupDiff> compareWithCurrent(BackupInfo backup) async {
    final backupFile = File(backup.path);
    final currentFile = File(backup.originalPath);

    if (!await backupFile.exists()) {
      throw BackupException('Backup file does not exist');
    }

    if (!await currentFile.exists()) {
      return BackupDiff(
        backup: backup,
        backupContent: await backupFile.readAsString(),
        currentContent: null,
        identical: false,
      );
    }

    final backupContent = await backupFile.readAsString();
    final currentContent = await currentFile.readAsString();

    return BackupDiff(
      backup: backup,
      backupContent: backupContent,
      currentContent: currentContent,
      identical: backupContent == currentContent,
    );
  }

  /// Get total size of all backups for a file
  Future<int> getTotalBackupSize(String originalPath) async {
    final backups = await listBackups(originalPath);
    return backups.fold<int>(0, (sum, b) => sum + (b.sizeBytes ?? 0));
  }

  /// Get summary of all backups
  Future<BackupSummary> getBackupSummary() async {
    final dir = Directory(useBackupDirectory ? _backupDir : Platform.environment['HOME']!);
    
    int totalBackups = 0;
    int totalSize = 0;
    DateTime? oldestBackup;
    DateTime? newestBackup;

    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: !useBackupDirectory)) {
        if (entity is File && entity.path.contains('.backup.')) {
          totalBackups++;
          final stat = await entity.stat();
          totalSize += stat.size;
          
          // Try to parse timestamp
          final info = BackupInfo.fromBackupPath(entity.path, '');
          if (info != null) {
            if (oldestBackup == null || info.timestamp.isBefore(oldestBackup)) {
              oldestBackup = info.timestamp;
            }
            if (newestBackup == null || info.timestamp.isAfter(newestBackup)) {
              newestBackup = info.timestamp;
            }
          }
        }
      }
    }

    return BackupSummary(
      totalBackups: totalBackups,
      totalSizeBytes: totalSize,
      oldestBackup: oldestBackup,
      newestBackup: newestBackup,
    );
  }
}

/// Exception for backup operations
class BackupException implements Exception {
  final String message;
  
  BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}

/// Result of comparing a backup with current file
class BackupDiff {
  final BackupInfo backup;
  final String backupContent;
  final String? currentContent;
  final bool identical;

  const BackupDiff({
    required this.backup,
    required this.backupContent,
    required this.currentContent,
    required this.identical,
  });

  /// Check if current file exists
  bool get currentExists => currentContent != null;

  /// Get line-by-line diff (simple implementation)
  List<DiffLine> getLineDiff() {
    if (currentContent == null) {
      return backupContent
          .split('\n')
          .map((line) => DiffLine(line, DiffType.removed))
          .toList();
    }

    final backupLines = backupContent.split('\n');
    final currentLines = currentContent!.split('\n');
    final diff = <DiffLine>[];

    // Simple line-by-line comparison
    final maxLines = backupLines.length > currentLines.length
        ? backupLines.length
        : currentLines.length;

    for (int i = 0; i < maxLines; i++) {
      final backupLine = i < backupLines.length ? backupLines[i] : null;
      final currentLine = i < currentLines.length ? currentLines[i] : null;

      if (backupLine == currentLine) {
        diff.add(DiffLine(currentLine!, DiffType.unchanged));
      } else if (backupLine == null) {
        diff.add(DiffLine(currentLine!, DiffType.added));
      } else if (currentLine == null) {
        diff.add(DiffLine(backupLine, DiffType.removed));
      } else {
        diff.add(DiffLine(backupLine, DiffType.removed));
        diff.add(DiffLine(currentLine, DiffType.added));
      }
    }

    return diff;
  }
}

/// A line in a diff
class DiffLine {
  final String content;
  final DiffType type;

  const DiffLine(this.content, this.type);
}

/// Type of diff line
enum DiffType {
  unchanged,
  added,
  removed,
}

/// Summary of backup storage
class BackupSummary {
  final int totalBackups;
  final int totalSizeBytes;
  final DateTime? oldestBackup;
  final DateTime? newestBackup;

  const BackupSummary({
    required this.totalBackups,
    required this.totalSizeBytes,
    this.oldestBackup,
    this.newestBackup,
  });

  String get totalSizeString {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
