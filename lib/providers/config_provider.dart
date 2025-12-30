import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/yabai_config.dart';
import '../models/config_enums.dart';
import '../models/exclusion_rule.dart';
import 'exclusions_provider.dart';

/// Provider for Yabai configuration with auto-save
final yabaiConfigProvider =
    StateNotifierProvider<YabaiConfigNotifier, YabaiConfig>((ref) {
  final notifier = YabaiConfigNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Provider for auto-save status
final autoSaveEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for auto-apply status (restart yabai after save)
final autoApplyEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for unsaved changes indicator
final hasUnsavedChangesProvider = StateProvider<bool>((ref) => false);

/// Provider for saving status
final isSavingProvider = StateProvider<bool>((ref) => false);

/// Provider for last save time
final lastSaveTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Helper provider to get layout enum from config
final layoutProvider = Provider<YabaiLayout>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return YabaiLayout.fromString(config.layout);
});

/// Helper provider to get window placement enum from config
final windowPlacementProvider = Provider<WindowPlacement>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return WindowPlacement.fromString(config.windowPlacement);
});

/// Helper provider for mouse follows focus
final mouseFollowsFocusProvider = Provider<bool>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return config.mouseFollowsFocus;
});

/// Helper provider for mouse modifier
final mouseModifierProvider = Provider<MouseModifier>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return MouseModifier.fromString(config.mouseModifier);
});

/// Helper provider for mouse action 1
final mouseAction1Provider = Provider<MouseAction>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return MouseAction.fromString(config.mouseAction1);
});

/// Helper provider for mouse action 2
final mouseAction2Provider = Provider<MouseAction>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return MouseAction.fromString(config.mouseAction2);
});

/// Helper provider for mouse drop action
final mouseDropActionProvider = Provider<MouseDropAction>((ref) {
  final config = ref.watch(yabaiConfigProvider);
  return MouseDropAction.fromString(config.mouseDropAction);
});

/// Notifier for managing Yabai configuration
class YabaiConfigNotifier extends StateNotifier<YabaiConfig> {
  final Ref _ref;
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 1500);

  YabaiConfigNotifier(this._ref) : super(const YabaiConfig()) {
    loadConfig();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Trigger auto-save with debounce
  void _triggerAutoSave() {
    final autoSaveEnabled = _ref.read(autoSaveEnabledProvider);
    if (!autoSaveEnabled) return;

    // Mark as having unsaved changes
    _ref.read(hasUnsavedChangesProvider.notifier).state = true;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(_debounceDelay, () async {
      await saveAndApply();
    });
  }

  /// Save config and optionally apply (restart yabai)
  Future<bool> saveAndApply() async {
    final success = await saveConfig();
    if (success) {
      _ref.read(hasUnsavedChangesProvider.notifier).state = false;
      _ref.read(lastSaveTimeProvider.notifier).state = DateTime.now();

      // Auto-apply if enabled
      final autoApplyEnabled = _ref.read(autoApplyEnabledProvider);
      if (autoApplyEnabled) {
        await _restartYabai();
      }
    }
    return success;
  }

  /// Restart yabai to apply changes
  Future<void> _restartYabai() async {
    try {
      // Try common paths for yabai
      final paths = ['/opt/homebrew/bin/yabai', '/usr/local/bin/yabai'];
      for (final path in paths) {
        if (await File(path).exists()) {
          await Process.run(path, ['--restart-service']);
          return;
        }
      }
      // Fallback to PATH
      await Process.run('/bin/bash', ['-c', 'yabai --restart-service']);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Load configuration from yabairc file
  Future<void> loadConfig() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');

      if (!await yabairc.exists()) {
        return;
      }

      final content = await yabairc.readAsString();
      final parsedConfig = _parseYabairc(content);
      state = parsedConfig;
    } catch (e) {
      // Use default config on error
    }
  }

  /// Parse yabairc file content into YabaiConfig
  YabaiConfig _parseYabairc(String content) {
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
    );
  }

  /// Update layout
  void updateLayout(YabaiLayout layout) {
    state = state.copyWith(layout: layout.value);
    _triggerAutoSave();
  }

  /// Update window gap
  void updateWindowGap(int gap) {
    state = state.copyWith(windowGap: gap);
    _triggerAutoSave();
  }

  /// Update window placement
  void updateWindowPlacement(WindowPlacement placement) {
    state = state.copyWith(windowPlacement: placement.value);
    _triggerAutoSave();
  }

  /// Update external bar
  void updateExternalBar(String externalBar) {
    if (externalBar.isEmpty) {
      state = state.copyWith(clearExternalBar: true);
    } else {
      state = state.copyWith(externalBar: externalBar);
    }
    _triggerAutoSave();
  }

  /// Update mouse follows focus
  void updateMouseFollowsFocus(bool value) {
    state = state.copyWith(mouseFollowsFocus: value);
    _triggerAutoSave();
  }

  /// Update mouse modifier
  void updateMouseModifier(MouseModifier modifier) {
    state = state.copyWith(mouseModifier: modifier.value);
    _triggerAutoSave();
  }

  /// Update mouse action 1
  void updateMouseAction1(MouseAction action) {
    state = state.copyWith(mouseAction1: action.value);
    _triggerAutoSave();
  }

  /// Update mouse action 2
  void updateMouseAction2(MouseAction action) {
    state = state.copyWith(mouseAction2: action.value);
    _triggerAutoSave();
  }

  /// Update mouse drop action
  void updateMouseDropAction(MouseDropAction action) {
    state = state.copyWith(mouseDropAction: action.value);
    _triggerAutoSave();
  }

  /// Update padding
  void updatePadding({int? top, int? bottom, int? left, int? right}) {
    state = state.copyWith(
      topPadding: top,
      bottomPadding: bottom,
      leftPadding: left,
      rightPadding: right,
    );
    _triggerAutoSave();
  }

  /// Save configuration to yabairc file
  Future<bool> saveConfig() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');

      // Get exclusion rules from the provider
      final exclusionRules = _ref.read(exclusionsProvider);

      final content = state.toYabairc(exclusionRules: exclusionRules);
      await yabairc.writeAsString(content);

      // Make the file executable
      await Process.run('chmod', ['+x', yabairc.path]);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save configuration with specific exclusion rules (avoids timing issues)
  Future<bool> saveConfigWithExclusions(List<ExclusionRule> exclusionRules) async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');

      final content = state.toYabairc(exclusionRules: exclusionRules);
      await yabairc.writeAsString(content);

      // Make the file executable
      await Process.run('chmod', ['+x', yabairc.path]);

      return true;
    } catch (e) {
      return false;
    }
  }
}
