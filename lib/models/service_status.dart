/// Represents the status of a service (yabai or skhd)
enum ServiceState {
  running,
  stopped,
  unknown,
}

/// Status information for yabai and skhd services
class ServiceStatus {
  final ServiceState yabaiState;
  final ServiceState skhdState;
  final String? yabaiVersion;
  final String? skhdVersion;
  final DateTime lastChecked;

  const ServiceStatus({
    this.yabaiState = ServiceState.unknown,
    this.skhdState = ServiceState.unknown,
    this.yabaiVersion,
    this.skhdVersion,
    required this.lastChecked,
  });

  ServiceStatus copyWith({
    ServiceState? yabaiState,
    ServiceState? skhdState,
    String? yabaiVersion,
    String? skhdVersion,
    DateTime? lastChecked,
  }) {
    return ServiceStatus(
      yabaiState: yabaiState ?? this.yabaiState,
      skhdState: skhdState ?? this.skhdState,
      yabaiVersion: yabaiVersion ?? this.yabaiVersion,
      skhdVersion: skhdVersion ?? this.skhdVersion,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  bool get isYabaiRunning => yabaiState == ServiceState.running;
  bool get isSkhdRunning => skhdState == ServiceState.running;
  bool get allServicesRunning => isYabaiRunning && isSkhdRunning;
}

/// Dashboard statistics
class DashboardStats {
  final int ruleCount;
  final int shortcutCount;
  final int signalCount;
  final DateTime? lastBackupTime;
  final String? lastBackupPath;

  const DashboardStats({
    this.ruleCount = 0,
    this.shortcutCount = 0,
    this.signalCount = 0,
    this.lastBackupTime,
    this.lastBackupPath,
  });

  DashboardStats copyWith({
    int? ruleCount,
    int? shortcutCount,
    int? signalCount,
    DateTime? lastBackupTime,
    String? lastBackupPath,
  }) {
    return DashboardStats(
      ruleCount: ruleCount ?? this.ruleCount,
      shortcutCount: shortcutCount ?? this.shortcutCount,
      signalCount: signalCount ?? this.signalCount,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
    );
  }

  String get lastBackupFormatted {
    if (lastBackupTime == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastBackupTime!);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
