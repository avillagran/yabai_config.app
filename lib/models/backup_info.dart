/// Represents information about a backup file
class BackupInfo {
  /// Full path to the backup file
  final String path;

  /// Timestamp when the backup was created
  final DateTime timestamp;

  /// Path to the original file that was backed up
  final String originalPath;

  /// Optional description or note about the backup
  final String? description;

  /// Size of the backup file in bytes
  final int? sizeBytes;

  const BackupInfo({
    required this.path,
    required this.timestamp,
    required this.originalPath,
    this.description,
    this.sizeBytes,
  });

  BackupInfo copyWith({
    String? path,
    DateTime? timestamp,
    String? originalPath,
    String? description,
    int? sizeBytes,
  }) {
    return BackupInfo(
      path: path ?? this.path,
      timestamp: timestamp ?? this.timestamp,
      originalPath: originalPath ?? this.originalPath,
      description: description ?? this.description,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  /// Get a human-readable timestamp string
  String get timestampString {
    return '${timestamp.year}-${_pad(timestamp.month)}-${_pad(timestamp.day)} '
        '${_pad(timestamp.hour)}:${_pad(timestamp.minute)}:${_pad(timestamp.second)}';
  }

  /// Get a relative time description (e.g., "2 hours ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 30) {
      final months = difference.inDays ~/ 30;
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get file size in human-readable format
  String get sizeString {
    if (sizeBytes == null) return 'Unknown';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get the filename from the path
  String get fileName {
    return path.split('/').last;
  }

  /// Get the original filename
  String get originalFileName {
    return originalPath.split('/').last;
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  String toString() {
    return 'BackupInfo(path: $path, timestamp: $timestampString, original: $originalPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupInfo && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  /// Parse backup info from a backup filename
  /// Expected format: .filename.backup.YYYYMMDD_HHMMSS
  static BackupInfo? fromBackupPath(String backupPath, String originalPath) {
    final fileName = backupPath.split('/').last;
    final timestampPattern = RegExp(r'\.backup\.(\d{8}_\d{6})$');
    final match = timestampPattern.firstMatch(fileName);

    if (match == null) return null;

    final timestampStr = match.group(1)!;
    try {
      final year = int.parse(timestampStr.substring(0, 4));
      final month = int.parse(timestampStr.substring(4, 6));
      final day = int.parse(timestampStr.substring(6, 8));
      final hour = int.parse(timestampStr.substring(9, 11));
      final minute = int.parse(timestampStr.substring(11, 13));
      final second = int.parse(timestampStr.substring(13, 15));

      return BackupInfo(
        path: backupPath,
        timestamp: DateTime(year, month, day, hour, minute, second),
        originalPath: originalPath,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generate a backup filename for a given original path
  static String generateBackupPath(String originalPath, [DateTime? timestamp]) {
    final ts = timestamp ?? DateTime.now();
    final dir = originalPath.substring(0, originalPath.lastIndexOf('/'));
    final fileName = originalPath.split('/').last;
    final tsStr = '${ts.year}${_padStatic(ts.month)}${_padStatic(ts.day)}_'
        '${_padStatic(ts.hour)}${_padStatic(ts.minute)}${_padStatic(ts.second)}';
    return '$dir/.$fileName.backup.$tsStr';
  }

  static String _padStatic(int n) => n.toString().padLeft(2, '0');
}
