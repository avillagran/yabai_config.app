import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

// ============================================================================
// Shared Preferences Provider
// ============================================================================

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ============================================================================
// Settings Storage Service
// ============================================================================

/// Service for persisting app settings
class SettingsStorageService {
  static const String _settingsKey = 'app_settings';
  static const String _settingsFileName = 'settings.json';

  /// Get the settings file path
  Future<File> get _settingsFile async {
    final appSupport = await getApplicationSupportDirectory();
    return File('${appSupport.path}/$_settingsFileName');
  }

  /// Load settings from storage
  Future<AppSettings> loadSettings() async {
    try {
      // Try loading from file first (more reliable for complex data)
      final file = await _settingsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      // Return default settings on error
    }

    return const AppSettings();
  }

  /// Save settings to storage
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());

      // Save to file
      final file = await _settingsFile;
      await file.writeAsString(json);

      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json);
    } catch (e) {
      // Silently fail - settings will be loaded with defaults next time
      rethrow;
    }
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (e) {
      // Silently fail
    }
  }
}

/// Provider for the settings storage service
final settingsStorageServiceProvider = Provider<SettingsStorageService>((ref) {
  return SettingsStorageService();
});

// ============================================================================
// Settings Notifier
// ============================================================================

/// State notifier for managing application settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  bool _isInitialized = false;

  SettingsNotifier(this._ref) : super(const AppSettings()) {
    _init();
  }

  /// Get the storage service
  SettingsStorageService get _storageService => _ref.read(settingsStorageServiceProvider);

  /// Whether settings have been loaded
  bool get isInitialized => _isInitialized;

  /// Initialize by loading settings
  Future<void> _init() async {
    try {
      final settings = await _storageService.loadSettings();
      state = settings;
      _isInitialized = true;
    } catch (e) {
      // Use default settings on error
      _isInitialized = true;
    }
  }

  /// Save the current settings
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(state);
    } catch (e) {
      // Handle save error - could emit an error state
    }
  }

  /// Update the yabai config path
  void setYabaiConfigPath(String path) {
    state = state.copyWith(yabaiConfigPath: path);
    _saveSettings();
  }

  /// Update the skhd config path
  void setSkhdConfigPath(String path) {
    state = state.copyWith(skhdConfigPath: path);
    _saveSettings();
  }

  /// Reset config paths to defaults
  void resetConfigPaths() {
    state = state.copyWith(
      yabaiConfigPath: '',
      skhdConfigPath: '',
    );
    _saveSettings();
  }

  /// Toggle auto-save
  void setAutoSave(bool enabled) {
    state = state.copyWith(autoSave: enabled);
    _saveSettings();
  }

  /// Set auto-save delay in milliseconds
  void setAutoSaveDelay(int delayMs) {
    // Clamp to reasonable values (100ms - 10s)
    final clampedDelay = delayMs.clamp(100, 10000);
    state = state.copyWith(autoSaveDelay: clampedDelay);
    _saveSettings();
  }

  /// Toggle backup creation on save
  void setCreateBackupOnSave(bool enabled) {
    state = state.copyWith(createBackupOnSave: enabled);
    _saveSettings();
  }

  /// Set the theme
  void setTheme(String theme) {
    // Validate theme value
    const validThemes = ['system', 'light', 'dark'];
    if (!validThemes.contains(theme)) {
      theme = 'system';
    }
    state = state.copyWith(theme: theme);
    _saveSettings();
  }

  /// Toggle line numbers in editor
  void setShowLineNumbers(bool show) {
    state = state.copyWith(showLineNumbers: show);
    _saveSettings();
  }

  /// Toggle syntax highlighting
  void setSyntaxHighlighting(bool enabled) {
    state = state.copyWith(syntaxHighlighting: enabled);
    _saveSettings();
  }

  /// Update multiple settings at once
  void updateSettings({
    String? yabaiConfigPath,
    String? skhdConfigPath,
    bool? autoSave,
    int? autoSaveDelay,
    bool? createBackupOnSave,
    String? theme,
    bool? showLineNumbers,
    bool? syntaxHighlighting,
  }) {
    state = state.copyWith(
      yabaiConfigPath: yabaiConfigPath,
      skhdConfigPath: skhdConfigPath,
      autoSave: autoSave,
      autoSaveDelay: autoSaveDelay,
      createBackupOnSave: createBackupOnSave,
      theme: theme,
      showLineNumbers: showLineNumbers,
      syntaxHighlighting: syntaxHighlighting,
    );
    _saveSettings();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _storageService.clearSettings();
    state = const AppSettings();
  }

  /// Export settings as JSON string
  String exportSettings() {
    return jsonEncode(state.toJson());
  }

  /// Import settings from JSON string
  Future<bool> importSettings(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      state = AppSettings.fromJson(json);
      await _saveSettings();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for application settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

// ============================================================================
// Derived Providers
// ============================================================================

/// Provider for effective yabai config path
final effectiveYabaiConfigPathProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.effectiveYabaiConfigPath;
});

/// Provider for effective skhd config path
final effectiveSkhdConfigPathProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.effectiveSkhdConfigPath;
});

/// Provider for auto-save enabled status
final autoSaveEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoSave;
});

/// Provider for auto-save delay
final autoSaveDelayProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).autoSaveDelay;
});

/// Provider for backup on save enabled status
final createBackupOnSaveProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).createBackupOnSave;
});

/// Provider for current theme
final themeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).theme;
});

/// Provider for checking if config files exist
final configFilesExistProvider = FutureProvider<Map<String, bool>>((ref) async {
  final settings = ref.watch(settingsProvider);

  final yabaiPath = settings.effectiveYabaiConfigPath;
  final skhdPath = settings.effectiveSkhdConfigPath;

  final yabaiExists = await File(yabaiPath).exists();
  final skhdExists = await File(skhdPath).exists();

  return {
    'yabai': yabaiExists,
    'skhd': skhdExists,
  };
});

/// Provider for home directory path
final homeDirectoryProvider = Provider<String>((ref) {
  return Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
});

// ============================================================================
// Theme Mode Provider (for Flutter ThemeMode)
// ============================================================================

/// Enum for theme mode matching Flutter's ThemeMode
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Provider for the current theme mode
final themeModeProvider = Provider<AppThemeMode>((ref) {
  final theme = ref.watch(themeProvider);
  switch (theme) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    default:
      return AppThemeMode.system;
  }
});
