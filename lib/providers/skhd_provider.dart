import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/skhd_config.dart';
import '../models/keyboard_shortcut.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';
import 'settings_provider.dart';
import 'yabai_provider.dart';

// ============================================================================
// Status Providers
// ============================================================================

/// Stream provider that monitors skhd running status
final skhdStatusProvider = StreamProvider<bool>((ref) {
  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => _checkSkhdRunning(),
  ).asyncMap((future) => future);
});

/// Check if skhd is running
Future<bool> _checkSkhdRunning() async {
  try {
    // Use full path to pgrep for macOS desktop app environment
    final result = await Process.run('/usr/bin/pgrep', ['-x', 'skhd']);
    if (result.exitCode == 0) {
      return true;
    }

    // Fallback: check using ps command
    final psResult = await Process.run(
      '/bin/ps',
      ['aux'],
      environment: {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin'},
    );
    if (psResult.exitCode == 0) {
      final output = psResult.stdout as String;
      return output.contains('/skhd') || output.contains('skhd');
    }

    return false;
  } catch (e) {
    return false;
  }
}

/// One-time check for skhd running status
final skhdIsRunningProvider = FutureProvider<bool>((ref) async {
  return _checkSkhdRunning();
});

// ============================================================================
// Config File Service
// ============================================================================

/// Service for reading/writing skhd config files
class SkhdConfigFileService {
  final BackupService _backupService;

  SkhdConfigFileService(this._backupService);

  /// Get the home directory path
  String get _homeDirectory {
    return Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
  }

  /// Read and parse the skhd config file
  Future<SkhdConfig> readConfig(String? customPath) async {
    final path = customPath?.isNotEmpty == true
        ? customPath!
        : '$_homeDirectory/.skhdrc';
    final file = File(path);

    if (!await file.exists()) {
      // Return default config if file doesn't exist
      return const SkhdConfig();
    }

    final content = await file.readAsString();
    return SkhdConfig.fromSkhdrc(content);
  }

  /// Write the skhd config to file
  Future<void> writeConfig(SkhdConfig config, String? customPath, {bool createBackup = true}) async {
    final path = customPath?.isNotEmpty == true
        ? customPath!
        : '$_homeDirectory/.skhdrc';
    final file = File(path);

    // Create backup before writing
    if (createBackup && await file.exists()) {
      await _backupService.createBackup(path, description: 'Auto-backup before save');
    }

    final content = config.toSkhdrc();
    await file.writeAsString(content);
  }
}

/// Provider for the skhd config file service
final skhdConfigFileServiceProvider = Provider<SkhdConfigFileService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return SkhdConfigFileService(backupService);
});

// ============================================================================
// Config State Notifier
// ============================================================================

/// State notifier for managing skhd configuration
class SkhdConfigNotifier extends StateNotifier<AsyncValue<SkhdConfig>> {
  final Ref _ref;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  SkhdConfigNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadConfig();
  }

  /// Get the config file service
  SkhdConfigFileService get _configService => _ref.read(skhdConfigFileServiceProvider);

  /// Get the current settings
  AppSettings get _settings => _ref.read(settingsProvider);

  /// Whether there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Load configuration from file
  Future<void> loadConfig() async {
    state = const AsyncValue.loading();
    try {
      final config = await _configService.readConfig(_settings.skhdConfigPath);
      state = AsyncValue.data(config);
      _hasUnsavedChanges = false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Save configuration to file
  Future<void> saveConfig() async {
    final currentConfig = state.valueOrNull;
    if (currentConfig == null) return;

    try {
      await _configService.writeConfig(
        currentConfig,
        _settings.skhdConfigPath,
        createBackup: _settings.createBackupOnSave,
      );
      _hasUnsavedChanges = false;
      _autoSaveTimer?.cancel();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Schedule auto-save with debounce
  void _scheduleAutoSave() {
    if (!_settings.autoSave) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      Duration(milliseconds: _settings.autoSaveDelay),
      () => saveConfig(),
    );
  }

  /// Update the configuration
  void _updateConfig(SkhdConfig Function(SkhdConfig) updater) {
    final currentConfig = state.valueOrNull;
    if (currentConfig == null) return;

    state = AsyncValue.data(updater(currentConfig));
    _hasUnsavedChanges = true;
    _scheduleAutoSave();
  }

  /// Add a new shortcut
  void addShortcut(Shortcut shortcut) {
    _updateConfig((config) => config.addShortcut(shortcut));
  }

  /// Add a keyboard shortcut from the KeyboardShortcut model
  void addKeyboardShortcut(KeyboardShortcut keyboardShortcut) {
    final parts = keyboardShortcut.keyCombo.split('-');
    final key = parts.last.trim();
    final modifiersPart = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('-').trim() : '';

    final modifiers = modifiersPart.isEmpty
        ? <String>[]
        : modifiersPart
            .split('+')
            .map((m) => m.trim().toLowerCase())
            .toList();

    final shortcut = Shortcut(
      id: keyboardShortcut.id,
      modifiers: modifiers,
      key: key,
      action: keyboardShortcut.action,
      description: keyboardShortcut.description,
      category: keyboardShortcut.category.name,
      enabled: keyboardShortcut.isEnabled,
    );

    addShortcut(shortcut);
  }

  /// Update an existing shortcut
  void updateShortcut(Shortcut updatedShortcut) {
    _updateConfig((config) => config.updateShortcut(updatedShortcut));
  }

  /// Remove a shortcut by id
  void removeShortcut(String shortcutId) {
    _updateConfig((config) => config.removeShortcut(shortcutId));
  }

  /// Toggle a shortcut (enable/disable)
  void toggleShortcut(String shortcutId) {
    _updateConfig((config) {
      final shortcut = config.findById(shortcutId);
      if (shortcut != null) {
        return config.updateShortcut(
          shortcut.copyWith(enabled: !shortcut.enabled),
        );
      }
      return config;
    });
  }

  /// Load default preset shortcuts
  void loadPresets() {
    _updateConfig((config) {
      // Get vim-style preset shortcuts
      final presets = PresetShortcuts.vimStylePreset;

      // Convert KeyboardShortcuts to Shortcuts
      final presetShortcuts = presets.map((ps) {
        final parts = ps.keyCombo.split('-');
        final key = parts.last.trim();
        final modifiersPart = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('-').trim() : '';

        final modifiers = modifiersPart.isEmpty
            ? <String>[]
            : modifiersPart
                .split('+')
                .map((m) => m.trim().toLowerCase())
                .toList();

        return Shortcut(
          id: ps.id,
          modifiers: modifiers,
          key: key,
          action: ps.action,
          description: ps.description,
          category: ps.category.name,
          enabled: ps.isEnabled,
        );
      }).toList();

      // Merge with existing shortcuts (avoid duplicates)
      final existingKeys = config.shortcuts.map((s) => s.toSkhdHotkey()).toSet();
      final newShortcuts = [
        ...config.shortcuts,
        ...presetShortcuts.where((s) => !existingKeys.contains(s.toSkhdHotkey())),
      ];

      return config.copyWith(shortcuts: newShortcuts);
    });
  }

  /// Get shortcuts grouped by category
  Map<String, List<Shortcut>> getShortcutsByCategory() {
    final config = state.valueOrNull;
    if (config == null) return {};

    final result = <String, List<Shortcut>>{};

    for (final shortcut in config.shortcuts) {
      String category;
      if (shortcut.action.contains('--focus')) {
        category = 'Focus';
      } else if (shortcut.action.contains('--swap') || shortcut.action.contains('--warp')) {
        category = 'Move';
      } else if (shortcut.action.contains('--resize')) {
        category = 'Resize';
      } else if (shortcut.action.contains('--layout') || shortcut.action.contains('--toggle')) {
        category = 'Layout';
      } else if (shortcut.action.contains('--space')) {
        category = 'Spaces';
      } else {
        category = 'Custom';
      }

      result.putIfAbsent(category, () => []).add(shortcut);
    }

    return result;
  }

  /// Reload skhd service
  Future<bool> reloadSkhd() async {
    try {
      final result = await Process.run('skhd', ['--reload']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// Provider for the skhd config state
final skhdConfigProvider = StateNotifierProvider<SkhdConfigNotifier, AsyncValue<SkhdConfig>>((ref) {
  return SkhdConfigNotifier(ref);
});

// ============================================================================
// Derived Providers
// ============================================================================

/// Provider for all shortcuts
final skhdShortcutsProvider = Provider<List<Shortcut>>((ref) {
  return ref.watch(skhdConfigProvider).whenData((config) => config.shortcuts).valueOrNull ?? [];
});

/// Provider for shortcuts grouped by category
final skhdShortcutsByCategoryProvider = Provider<Map<String, List<Shortcut>>>((ref) {
  return ref.watch(skhdConfigProvider.notifier).getShortcutsByCategory();
});

/// Provider for yabai-specific shortcuts
final skhdYabaiShortcutsProvider = Provider<List<Shortcut>>((ref) {
  final shortcuts = ref.watch(skhdShortcutsProvider);
  return shortcuts.where((s) => s.isYabaiShortcut).toList();
});

/// Provider for unsaved changes status
final skhdHasUnsavedChangesProvider = Provider<bool>((ref) {
  return ref.watch(skhdConfigProvider.notifier).hasUnsavedChanges;
});

/// Provider for shortcut conflicts (same hotkey, different command)
final skhdConflictsProvider = Provider<List<List<Shortcut>>>((ref) {
  final shortcuts = ref.watch(skhdShortcutsProvider);
  final conflicts = <List<Shortcut>>[];

  // Group by hotkey string
  final byHotkey = <String, List<Shortcut>>{};
  for (final shortcut in shortcuts) {
    final key = shortcut.toSkhdHotkey();
    byHotkey.putIfAbsent(key, () => []).add(shortcut);
  }

  // Find conflicts (multiple shortcuts with same hotkey)
  for (final group in byHotkey.values) {
    if (group.length > 1) {
      conflicts.add(group);
    }
  }

  return conflicts;
});
