import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_status.dart';

/// Provider for service status
final serviceStatusProvider =
    StateNotifierProvider<ServiceStatusNotifier, ServiceStatus>((ref) {
  return ServiceStatusNotifier();
});

/// Provider for dashboard stats
final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStats>((ref) {
  return DashboardStatsNotifier();
});

/// Notifier for managing service status
class ServiceStatusNotifier extends StateNotifier<ServiceStatus> {
  Timer? _refreshTimer;

  ServiceStatusNotifier()
      : super(ServiceStatus(lastChecked: DateTime.now())) {
    // Initial check
    checkStatus();
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Check the status of yabai and skhd services
  Future<void> checkStatus() async {
    final yabaiState = await _checkYabaiStatus();
    final skhdState = await _checkSkhdStatus();
    final yabaiVersion = await _getYabaiVersion();
    final skhdVersion = await _getSkhdVersion();

    state = state.copyWith(
      yabaiState: yabaiState,
      skhdState: skhdState,
      yabaiVersion: yabaiVersion,
      skhdVersion: skhdVersion,
      lastChecked: DateTime.now(),
    );
  }

  Future<ServiceState> _checkYabaiStatus() async {
    try {
      // Use bash to run pgrep - more reliable in sandboxed environments
      final result = await Process.run(
        '/bin/bash',
        ['-c', 'pgrep -x yabai'],
      );
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        return ServiceState.running;
      }
      return ServiceState.stopped;
    } catch (e) {
      return ServiceState.unknown;
    }
  }

  Future<ServiceState> _checkSkhdStatus() async {
    try {
      // Use bash to run pgrep - more reliable in sandboxed environments
      final result = await Process.run(
        '/bin/bash',
        ['-c', 'pgrep -x skhd'],
      );
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        return ServiceState.running;
      }
      return ServiceState.stopped;
    } catch (e) {
      return ServiceState.unknown;
    }
  }

  Future<String?> _getYabaiVersion() async {
    try {
      // Try common paths for yabai
      for (final path in ['/opt/homebrew/bin/yabai', '/usr/local/bin/yabai', 'yabai']) {
        try {
          final result = await Process.run(path, ['--version']);
          if (result.exitCode == 0) {
            return (result.stdout as String).trim();
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getSkhdVersion() async {
    try {
      // Try common paths for skhd
      for (final path in ['/opt/homebrew/bin/skhd', '/usr/local/bin/skhd', 'skhd']) {
        try {
          final result = await Process.run(path, ['--version']);
          if (result.exitCode == 0) {
            return (result.stdout as String).trim();
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the yabai executable path
  String _getYabaiPath() {
    // Check common Homebrew locations
    if (File('/opt/homebrew/bin/yabai').existsSync()) {
      return '/opt/homebrew/bin/yabai';
    } else if (File('/usr/local/bin/yabai').existsSync()) {
      return '/usr/local/bin/yabai';
    }
    return 'yabai';
  }

  /// Get the skhd executable path
  String _getSkhdPath() {
    // Check common Homebrew locations
    if (File('/opt/homebrew/bin/skhd').existsSync()) {
      return '/opt/homebrew/bin/skhd';
    } else if (File('/usr/local/bin/skhd').existsSync()) {
      return '/usr/local/bin/skhd';
    }
    return 'skhd';
  }

  /// Restart yabai service
  Future<bool> restartYabai() async {
    try {
      final yabaiPath = _getYabaiPath();
      // Stop yabai
      await Process.run(yabaiPath, ['--stop-service']);
      await Future.delayed(const Duration(milliseconds: 500));
      // Start yabai
      final result = await Process.run(yabaiPath, ['--start-service']);
      await checkStatus();
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Restart skhd service
  Future<bool> restartSkhd() async {
    try {
      final skhdPath = _getSkhdPath();
      // Stop skhd
      await Process.run(skhdPath, ['--stop-service']);
      await Future.delayed(const Duration(milliseconds: 500));
      // Start skhd
      final result = await Process.run(skhdPath, ['--start-service']);
      await checkStatus();
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Stop all services
  Future<void> stopAll() async {
    try {
      final yabaiPath = _getYabaiPath();
      final skhdPath = _getSkhdPath();
      await Process.run(yabaiPath, ['--stop-service']);
      await Process.run(skhdPath, ['--stop-service']);
      await checkStatus();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Start all services
  Future<void> startAll() async {
    try {
      final yabaiPath = _getYabaiPath();
      final skhdPath = _getSkhdPath();
      await Process.run(yabaiPath, ['--start-service']);
      await Process.run(skhdPath, ['--start-service']);
      await Future.delayed(const Duration(milliseconds: 500));
      await checkStatus();
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Notifier for managing dashboard statistics
class DashboardStatsNotifier extends StateNotifier<DashboardStats> {
  DashboardStatsNotifier() : super(const DashboardStats()) {
    loadStats();
  }

  /// Load statistics from configuration files
  Future<void> loadStats() async {
    final ruleCount = await _countRules();
    final shortcutCount = await _countShortcuts();
    final signalCount = await _countSignals();
    final backupInfo = await _getLastBackupInfo();

    state = state.copyWith(
      ruleCount: ruleCount,
      shortcutCount: shortcutCount,
      signalCount: signalCount,
      lastBackupTime: backupInfo?.$1,
      lastBackupPath: backupInfo?.$2,
    );
  }

  Future<int> _countRules() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');
      if (await yabairc.exists()) {
        final content = await yabairc.readAsString();
        final lines = content.split('\n');
        return lines.where((line) => line.contains('yabai -m rule')).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _countShortcuts() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final skhdrc = File('$home/.skhdrc');
      if (await skhdrc.exists()) {
        final content = await skhdrc.readAsString();
        final lines = content.split('\n');
        return lines
            .where((line) =>
                line.trim().isNotEmpty &&
                !line.trim().startsWith('#') &&
                line.contains(':'))
            .length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _countSignals() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');
      if (await yabairc.exists()) {
        final content = await yabairc.readAsString();
        final lines = content.split('\n');
        return lines.where((line) => line.contains('yabai -m signal')).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<(DateTime, String)?> _getLastBackupInfo() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final backupDir = Directory('$home/.yabai_config_backups');
      if (!await backupDir.exists()) return null;

      final backups = await backupDir
          .list()
          .where((entity) => entity is Directory)
          .toList();

      if (backups.isEmpty) return null;

      // Sort by modification time
      backups.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      final lastBackup = backups.first;
      final stat = await lastBackup.stat();
      return (stat.modified, lastBackup.path);
    } catch (e) {
      return null;
    }
  }

  void updateRuleCount(int count) {
    state = state.copyWith(ruleCount: count);
  }

  void updateShortcutCount(int count) {
    state = state.copyWith(shortcutCount: count);
  }

  void updateSignalCount(int count) {
    state = state.copyWith(signalCount: count);
  }

  void recordBackup(String path) {
    state = state.copyWith(
      lastBackupTime: DateTime.now(),
      lastBackupPath: path,
    );
  }
}
