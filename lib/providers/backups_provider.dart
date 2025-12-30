import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backup_info.dart';
import '../services/backup_service.dart';

/// Provider for BackupService
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    maxBackups: 20,
    useBackupDirectory: true,
  );
});

/// State class for backups
class BackupsState {
  final List<BackupInfo> yabaiBackups;
  final List<BackupInfo> skhdBackups;
  final bool isLoading;
  final String? error;
  final BackupInfo? selectedBackup;
  final BackupDiff? currentDiff;
  final bool isComparing;

  const BackupsState({
    this.yabaiBackups = const [],
    this.skhdBackups = const [],
    this.isLoading = false,
    this.error,
    this.selectedBackup,
    this.currentDiff,
    this.isComparing = false,
  });

  BackupsState copyWith({
    List<BackupInfo>? yabaiBackups,
    List<BackupInfo>? skhdBackups,
    bool? isLoading,
    String? error,
    BackupInfo? selectedBackup,
    BackupDiff? currentDiff,
    bool? isComparing,
    bool clearSelectedBackup = false,
    bool clearDiff = false,
  }) {
    return BackupsState(
      yabaiBackups: yabaiBackups ?? this.yabaiBackups,
      skhdBackups: skhdBackups ?? this.skhdBackups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedBackup: clearSelectedBackup ? null : (selectedBackup ?? this.selectedBackup),
      currentDiff: clearDiff ? null : (currentDiff ?? this.currentDiff),
      isComparing: isComparing ?? this.isComparing,
    );
  }

  /// Get all backups combined and sorted by timestamp (newest first)
  List<BackupInfo> get allBackups {
    final all = [...yabaiBackups, ...skhdBackups];
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  /// Get total backup count
  int get totalCount => yabaiBackups.length + skhdBackups.length;
}

/// Notifier for managing backups state
class BackupsNotifier extends StateNotifier<BackupsState> {
  final BackupService _backupService;

  BackupsNotifier(this._backupService) : super(const BackupsState()) {
    refresh();
  }

  /// Get the home directory
  String get _homeDir => Platform.environment['HOME'] ?? '/Users';

  /// Yabai config path
  String get _yabaiConfigPath => '$_homeDir/.yabairc';

  /// SKHD config path
  String get _skhdConfigPath => '$_homeDir/.skhdrc';

  /// Refresh the list of backups
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _backupService.listBackups(_yabaiConfigPath),
        _backupService.listBackups(_skhdConfigPath),
      ]);

      state = state.copyWith(
        yabaiBackups: results[0],
        skhdBackups: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load backups: $e',
      );
    }
  }

  /// Create a new backup for yabairc
  Future<bool> createYabaiBackup({String? description}) async {
    return _createBackup(_yabaiConfigPath, description: description);
  }

  /// Create a new backup for skhdrc
  Future<bool> createSkhdBackup({String? description}) async {
    return _createBackup(_skhdConfigPath, description: description);
  }

  /// Create a backup for a specific file
  Future<bool> _createBackup(String filePath, {String? description}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _backupService.createBackup(filePath, description: description);
      await refresh();
      return true;
    } on BackupException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create backup: $e',
      );
      return false;
    }
  }

  /// Restore a backup
  Future<bool> restoreBackup(BackupInfo backup, {bool createBackupFirst = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _backupService.restoreBackup(backup, createBackupFirst: createBackupFirst);
      await refresh();
      return true;
    } on BackupException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore backup: $e',
      );
      return false;
    }
  }

  /// Delete a backup
  Future<bool> deleteBackup(BackupInfo backup) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _backupService.deleteBackup(backup);
      await refresh();
      return true;
    } on BackupException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete backup: $e',
      );
      return false;
    }
  }

  /// Select a backup for preview
  void selectBackup(BackupInfo? backup) {
    state = state.copyWith(
      selectedBackup: backup,
      clearSelectedBackup: backup == null,
      clearDiff: true,
      isComparing: false,
    );
  }

  /// Compare backup with current config
  Future<void> compareWithCurrent(BackupInfo backup) async {
    state = state.copyWith(isComparing: true, selectedBackup: backup);

    try {
      final diff = await _backupService.compareWithCurrent(backup);
      state = state.copyWith(currentDiff: diff, isComparing: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        isComparing: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isComparing: false,
        error: 'Failed to compare: $e',
      );
    }
  }

  /// Clear comparison view
  void clearComparison() {
    state = state.copyWith(
      clearDiff: true,
      clearSelectedBackup: true,
    );
  }

  /// Get backup content
  Future<String?> getBackupContent(BackupInfo backup) async {
    try {
      final file = File(backup.path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Provider for backups state
final backupsProvider = StateNotifierProvider<BackupsNotifier, BackupsState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupsNotifier(backupService);
});
