/// Type of configuration file that was backed up
enum BackupFileType {
  yabairc('.yabairc', 'Yabai Config'),
  skhdrc('.skhdrc', 'SKHD Config');

  final String filename;
  final String displayName;

  const BackupFileType(this.filename, this.displayName);

  static BackupFileType fromFilename(String filename) {
    if (filename.contains('yabairc')) {
      return BackupFileType.yabairc;
    } else if (filename.contains('skhdrc')) {
      return BackupFileType.skhdrc;
    }
    return BackupFileType.yabairc;
  }
}

/// Model representing a backup of a configuration file
class ConfigBackup {
  final String id;
  final String filename;
  final BackupFileType fileType;
  final DateTime timestamp;
  final int sizeBytes;
  final String? content;
  final String? description;

  const ConfigBackup({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.timestamp,
    required this.sizeBytes,
    this.content,
    this.description,
  });

  ConfigBackup copyWith({
    String? id,
    String? filename,
    BackupFileType? fileType,
    DateTime? timestamp,
    int? sizeBytes,
    String? content,
    String? description,
  }) {
    return ConfigBackup(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      fileType: fileType ?? this.fileType,
      timestamp: timestamp ?? this.timestamp,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      content: content ?? this.content,
      description: description ?? this.description,
    );
  }

  /// Get human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  factory ConfigBackup.fromJson(Map<String, dynamic> json) {
    return ConfigBackup(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      filename: json['filename'] as String? ?? '',
      fileType: BackupFileType.fromFilename(json['filename'] as String? ?? ''),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      content: json['content'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'fileType': fileType.filename,
      'timestamp': timestamp.toIso8601String(),
      'sizeBytes': sizeBytes,
      'content': content,
      'description': description,
    };
  }
}

/// Model for diff comparison result
class DiffLine {
  final String content;
  final DiffLineType type;
  final int? oldLineNumber;
  final int? newLineNumber;

  const DiffLine({
    required this.content,
    required this.type,
    this.oldLineNumber,
    this.newLineNumber,
  });
}

/// Type of diff line
enum DiffLineType {
  unchanged,
  added,
  removed,
  header,
}
