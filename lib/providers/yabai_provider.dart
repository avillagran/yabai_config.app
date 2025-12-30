import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/yabai_config.dart';
import '../models/window_rule.dart';
import '../models/signal.dart';
import '../models/app_settings.dart';
import '../services/yabai_service.dart';
import '../services/backup_service.dart';
import 'settings_provider.dart';

// ============================================================================
// Services
// ============================================================================

/// Provider for the Yabai service
final yabaiServiceProvider = Provider<YabaiService>((ref) {
  return YabaiService();
});

/// Provider for the Backup service
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

// ============================================================================
// Status Providers
// ============================================================================

/// Stream provider that monitors yabai running status
final yabaiStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(yabaiServiceProvider);

  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => service.isRunning(),
  ).asyncMap((future) => future);
});

/// One-time check for yabai running status
final yabaiIsRunningProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(yabaiServiceProvider);
  return service.isRunning();
});

// ============================================================================
// Config File Service
// ============================================================================

/// Service for reading/writing yabai config files
class YabaiConfigFileService {
  final BackupService _backupService;

  YabaiConfigFileService(this._backupService);

  /// Get the home directory path
  String get _homeDirectory {
    return Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
  }

  /// Read and parse the yabai config file
  Future<YabaiConfig> readConfig(String? customPath) async {
    final path = customPath?.isNotEmpty == true
        ? customPath!
        : '$_homeDirectory/.yabairc';
    final file = File(path);

    if (!await file.exists()) {
      // Return default config if file doesn't exist
      return const YabaiConfig();
    }

    final content = await file.readAsString();
    return _parseConfig(content);
  }

  /// Parse yabai config file content
  YabaiConfig _parseConfig(String content) {
    final lines = content.split('\n');

    String layout = 'bsp';
    int windowGap = 6;
    int topPadding = 6;
    int bottomPadding = 6;
    int leftPadding = 6;
    int rightPadding = 6;
    String windowPlacement = 'second_child';
    String? externalBar;
    bool mouseFollowsFocus = false;
    String focusFollowsMouse = 'off';
    String mouseModifier = 'alt';
    String mouseAction1 = 'move';
    String mouseAction2 = 'resize';
    String mouseDropAction = 'swap';
    bool autoBalance = false;
    double splitRatio = 0.5;
    String splitType = 'auto';
    bool windowOpacity = false;
    double activeWindowOpacity = 1.0;
    double normalWindowOpacity = 0.9;
    String windowShadow = 'on';
    bool windowBorder = false;
    int windowBorderWidth = 4;
    String activeWindowBorderColor = '0xff775759';
    String normalWindowBorderColor = '0xff555555';
    String insertFeedbackColor = '0xffd75f5f';
    double windowAnimationDuration = 0.0;
    final rules = <WindowRule>[];
    final signals = <YabaiSignal>[];

    int ruleCounter = 0;
    int signalCounter = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      // Parse yabai config commands
      if (trimmed.contains('yabai -m config')) {
        final configMatch = RegExp(r'yabai\s+-m\s+config\s+(\S+)\s+(.+)$')
            .firstMatch(trimmed);
        if (configMatch != null) {
          final key = configMatch.group(1)!;
          final valueStr = configMatch.group(2)!.trim();

          switch (key) {
            case 'layout':
              layout = valueStr;
              break;
            case 'window_gap':
              windowGap = int.tryParse(valueStr) ?? windowGap;
              break;
            case 'top_padding':
              topPadding = int.tryParse(valueStr) ?? topPadding;
              break;
            case 'bottom_padding':
              bottomPadding = int.tryParse(valueStr) ?? bottomPadding;
              break;
            case 'left_padding':
              leftPadding = int.tryParse(valueStr) ?? leftPadding;
              break;
            case 'right_padding':
              rightPadding = int.tryParse(valueStr) ?? rightPadding;
              break;
            case 'window_placement':
              windowPlacement = valueStr;
              break;
            case 'external_bar':
              externalBar = valueStr;
              break;
            case 'mouse_follows_focus':
              mouseFollowsFocus = valueStr == 'on';
              break;
            case 'focus_follows_mouse':
              focusFollowsMouse = valueStr;
              break;
            case 'mouse_modifier':
              mouseModifier = valueStr;
              break;
            case 'mouse_action1':
              mouseAction1 = valueStr;
              break;
            case 'mouse_action2':
              mouseAction2 = valueStr;
              break;
            case 'mouse_drop_action':
              mouseDropAction = valueStr;
              break;
            case 'auto_balance':
              autoBalance = valueStr == 'on';
              break;
            case 'split_ratio':
              splitRatio = double.tryParse(valueStr) ?? splitRatio;
              break;
            case 'split_type':
              splitType = valueStr;
              break;
            case 'window_opacity':
              windowOpacity = valueStr == 'on';
              break;
            case 'active_window_opacity':
              activeWindowOpacity = double.tryParse(valueStr) ?? activeWindowOpacity;
              break;
            case 'normal_window_opacity':
              normalWindowOpacity = double.tryParse(valueStr) ?? normalWindowOpacity;
              break;
            case 'window_shadow':
              windowShadow = valueStr;
              break;
            case 'window_border':
              windowBorder = valueStr == 'on';
              break;
            case 'window_border_width':
              windowBorderWidth = int.tryParse(valueStr) ?? windowBorderWidth;
              break;
            case 'active_window_border_color':
              activeWindowBorderColor = valueStr;
              break;
            case 'normal_window_border_color':
              normalWindowBorderColor = valueStr;
              break;
            case 'insert_feedback_color':
              insertFeedbackColor = valueStr;
              break;
            case 'window_animation_duration':
              windowAnimationDuration = double.tryParse(valueStr) ?? windowAnimationDuration;
              break;
          }
        }
      }

      // Parse rule
      if (trimmed.contains('yabai -m rule --add')) {
        final rule = _parseRule(trimmed, 'rule_${ruleCounter++}');
        if (rule != null) {
          rules.add(rule);
        }
      }

      // Parse signal
      if (trimmed.contains('yabai -m signal --add')) {
        final signal = _parseSignal(trimmed, 'signal_${signalCounter++}');
        if (signal != null) {
          signals.add(signal);
        }
      }
    }

    return YabaiConfig(
      layout: layout,
      windowGap: windowGap,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      leftPadding: leftPadding,
      rightPadding: rightPadding,
      windowPlacement: windowPlacement,
      externalBar: externalBar,
      mouseFollowsFocus: mouseFollowsFocus,
      focusFollowsMouse: focusFollowsMouse,
      mouseModifier: mouseModifier,
      mouseAction1: mouseAction1,
      mouseAction2: mouseAction2,
      mouseDropAction: mouseDropAction,
      autoBalance: autoBalance,
      splitRatio: splitRatio,
      splitType: splitType,
      windowOpacity: windowOpacity,
      activeWindowOpacity: activeWindowOpacity,
      normalWindowOpacity: normalWindowOpacity,
      windowShadow: windowShadow,
      windowBorder: windowBorder,
      windowBorderWidth: windowBorderWidth,
      activeWindowBorderColor: activeWindowBorderColor,
      normalWindowBorderColor: normalWindowBorderColor,
      insertFeedbackColor: insertFeedbackColor,
      windowAnimationDuration: windowAnimationDuration,
      rules: rules,
      signals: signals,
    );
  }

  /// Parse a rule from yabai command
  WindowRule? _parseRule(String line, String id) {
    String? appName;
    String? title;
    bool manage = true;
    bool? sticky;
    String? layer;
    int? space;

    // Parse app
    final appMatch = RegExp(r'app="([^"]+)"').firstMatch(line);
    if (appMatch != null) {
      appName = appMatch.group(1);
    }

    // Parse title
    final titleMatch = RegExp(r'title="([^"]+)"').firstMatch(line);
    if (titleMatch != null) {
      title = titleMatch.group(1);
    }

    // Parse manage
    final manageMatch = RegExp(r'manage=(on|off)').firstMatch(line);
    if (manageMatch != null) {
      manage = manageMatch.group(1) == 'on';
    }

    // Parse sticky
    final stickyMatch = RegExp(r'sticky=(on|off)').firstMatch(line);
    if (stickyMatch != null) {
      sticky = stickyMatch.group(1) == 'on';
    }

    // Parse layer
    final layerMatch = RegExp(r'layer=(\w+)').firstMatch(line);
    if (layerMatch != null) {
      layer = layerMatch.group(1);
    }

    // Parse space
    final spaceMatch = RegExp(r'space=(\d+)').firstMatch(line);
    if (spaceMatch != null) {
      space = int.tryParse(spaceMatch.group(1)!);
    }

    if (appName == null && title == null) {
      return null;
    }

    return WindowRule(
      id: id,
      appName: appName,
      title: title,
      manage: manage,
      sticky: sticky,
      layer: layer,
      space: space,
    );
  }

  /// Parse a signal from yabai command
  YabaiSignal? _parseSignal(String line, String id) {
    String? event;
    String? action;
    String? label;

    // Parse event
    final eventMatch = RegExp(r'event=(\S+)').firstMatch(line);
    if (eventMatch != null) {
      event = eventMatch.group(1);
    }

    // Parse action
    final actionMatch = RegExp(r'action="([^"]+)"').firstMatch(line);
    if (actionMatch != null) {
      action = actionMatch.group(1);
    }

    // Parse label
    final labelMatch = RegExp(r'label="([^"]+)"').firstMatch(line);
    if (labelMatch != null) {
      label = labelMatch.group(1);
    }

    if (event == null || action == null) {
      return null;
    }

    return YabaiSignal(
      id: label ?? id,
      event: event,
      action: action,
      label: label,
    );
  }

  /// Write the yabai config to file
  Future<void> writeConfig(YabaiConfig config, String? customPath, {bool createBackup = true}) async {
    final path = customPath?.isNotEmpty == true
        ? customPath!
        : '$_homeDirectory/.yabairc';
    final file = File(path);

    // Create backup before writing
    if (createBackup && await file.exists()) {
      await _backupService.createBackup(path, description: 'Auto-backup before save');
    }

    final content = config.toYabairc();
    await file.writeAsString(content);
  }
}

/// Provider for the config file service
final yabaiConfigFileServiceProvider = Provider<YabaiConfigFileService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return YabaiConfigFileService(backupService);
});

// ============================================================================
// Config State Notifier
// ============================================================================

/// State notifier for managing Yabai configuration
class YabaiConfigNotifier extends StateNotifier<AsyncValue<YabaiConfig>> {
  final Ref _ref;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  YabaiConfigNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadConfig();
  }

  /// Get the config file service
  YabaiConfigFileService get _configService => _ref.read(yabaiConfigFileServiceProvider);

  /// Get the current settings
  AppSettings get _settings => _ref.read(settingsProvider);

  /// Whether there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Load configuration from file
  Future<void> loadConfig() async {
    state = const AsyncValue.loading();
    try {
      final config = await _configService.readConfig(_settings.yabaiConfigPath);
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
        _settings.yabaiConfigPath,
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

  /// Update a configuration value
  void _updateConfig(YabaiConfig Function(YabaiConfig) updater) {
    final currentConfig = state.valueOrNull;
    if (currentConfig == null) return;

    state = AsyncValue.data(updater(currentConfig));
    _hasUnsavedChanges = true;
    _scheduleAutoSave();
  }

  /// Update the layout type
  void updateLayout(String layout) {
    _updateConfig((config) => config.copyWith(layout: layout));
  }

  /// Update window gap
  void updateWindowGap(int gap) {
    _updateConfig((config) => config.copyWith(windowGap: gap));
  }

  /// Update padding values
  void updatePadding({int? top, int? bottom, int? left, int? right}) {
    _updateConfig((config) => config.copyWith(
      topPadding: top,
      bottomPadding: bottom,
      leftPadding: left,
      rightPadding: right,
    ));
  }

  /// Update mouse settings
  void updateMouseSettings({
    String? focusFollowsMouse,
    bool? mouseFollowsFocus,
    String? mouseModifier,
    String? mouseAction1,
    String? mouseAction2,
    String? mouseDropAction,
  }) {
    _updateConfig((config) => config.copyWith(
      focusFollowsMouse: focusFollowsMouse,
      mouseFollowsFocus: mouseFollowsFocus,
      mouseModifier: mouseModifier,
      mouseAction1: mouseAction1,
      mouseAction2: mouseAction2,
      mouseDropAction: mouseDropAction,
    ));
  }

  /// Add a new window rule
  void addRule(WindowRule rule) {
    _updateConfig((config) => config.addRule(rule));
  }

  /// Update an existing window rule
  void updateRule(WindowRule updatedRule) {
    _updateConfig((config) => config.updateRule(updatedRule));
  }

  /// Remove a window rule by id
  void removeRule(String id) {
    _updateConfig((config) => config.removeRule(id));
  }

  /// Add a new signal
  void addSignal(YabaiSignal signal) {
    _updateConfig((config) => config.addSignal(signal));
  }

  /// Update an existing signal
  void updateSignal(YabaiSignal updatedSignal) {
    _updateConfig((config) => config.updateSignal(updatedSignal));
  }

  /// Remove a signal by ID
  void removeSignal(String id) {
    _updateConfig((config) => config.removeSignal(id));
  }

  /// Toggle a signal's enabled state
  void toggleSignal(String id) {
    _updateConfig((config) {
      final signal = config.findSignalById(id);
      if (signal != null) {
        return config.updateSignal(signal.copyWith(enabled: !signal.enabled));
      }
      return config;
    });
  }

  /// Apply configuration to running yabai instance
  Future<void> applyConfig() async {
    final yabaiService = _ref.read(yabaiServiceProvider);
    final config = state.valueOrNull;
    if (config == null) return;

    // Apply layout
    try {
      await yabaiService.executeCommand('config layout ${config.layout}');
      await yabaiService.executeCommand('config window_gap ${config.windowGap}');
      await yabaiService.executeCommand('config top_padding ${config.topPadding}');
      await yabaiService.executeCommand('config bottom_padding ${config.bottomPadding}');
      await yabaiService.executeCommand('config left_padding ${config.leftPadding}');
      await yabaiService.executeCommand('config right_padding ${config.rightPadding}');
    } catch (_) {
      // Continue applying other settings even if one fails
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// Provider for the Yabai config state
final yabaiConfigProvider = StateNotifierProvider<YabaiConfigNotifier, AsyncValue<YabaiConfig>>((ref) {
  return YabaiConfigNotifier(ref);
});

// ============================================================================
// Derived Providers
// ============================================================================

/// Provider for current layout
final yabaiLayoutProvider = Provider<String?>((ref) {
  return ref.watch(yabaiConfigProvider).whenData((config) => config.layout).valueOrNull;
});

/// Provider for window gap
final yabaiWindowGapProvider = Provider<int?>((ref) {
  return ref.watch(yabaiConfigProvider).whenData((config) => config.windowGap).valueOrNull;
});

/// Provider for all rules
final yabaiRulesProvider = Provider<List<WindowRule>>((ref) {
  return ref.watch(yabaiConfigProvider).whenData((config) => config.rules).valueOrNull ?? [];
});

/// Provider for all signals
final yabaiSignalsProvider = Provider<List<YabaiSignal>>((ref) {
  return ref.watch(yabaiConfigProvider).whenData((config) => config.signals).valueOrNull ?? [];
});

/// Provider for unsaved changes status
final yabaiHasUnsavedChangesProvider = Provider<bool>((ref) {
  return ref.watch(yabaiConfigProvider.notifier).hasUnsavedChanges;
});
