import 'package:flutter/foundation.dart';

import 'window_rule.dart';
import 'signal.dart';
import 'space_config.dart';
import 'exclusion_rule.dart';

/// Main Yabai window manager configuration
///
/// Contains all settings for Yabai including layout, gaps, mouse settings,
/// window rules, signals, and per-space configurations.
class YabaiConfig {
  /// Window layout mode: bsp, float, or stack
  final String layout;

  /// Gap between windows in pixels
  final int windowGap;

  /// Padding on top of windows (useful for status bars)
  final int topPadding;

  /// Padding on bottom of windows
  final int bottomPadding;

  /// Padding on left of windows
  final int leftPadding;

  /// Padding on right of windows
  final int rightPadding;

  /// Where new windows appear: first_child or second_child
  final String windowPlacement;

  /// External bar configuration for sketchybar integration
  /// Format: "main:<top_padding>:<bottom_padding>" or "all:<top>:<bottom>"
  final String? externalBar;

  /// Whether focus follows the mouse cursor
  final bool mouseFollowsFocus;

  /// Whether to focus window under mouse on mouse move
  /// Values: 'off', 'autoraise', 'autofocus'
  final String focusFollowsMouse;

  /// Mouse modifier key for window operations (alt, cmd, ctrl, shift)
  final String mouseModifier;

  /// Action for mouse button 1 with modifier: move or resize
  final String mouseAction1;

  /// Action for mouse button 2 with modifier: move or resize
  final String mouseAction2;

  /// Action when dropping a window: swap or stack
  final String mouseDropAction;

  /// Auto-balance windows when a new window is added
  final bool autoBalance;

  /// Split ratio for BSP layout (0.0 to 1.0)
  final double splitRatio;

  /// Split type: auto, vertical, or horizontal
  final String splitType;

  /// Window opacity settings
  final bool windowOpacity;
  final double activeWindowOpacity;
  final double normalWindowOpacity;

  /// Window shadow settings: on, off, or float
  final String windowShadow;

  /// Window border settings
  final bool windowBorder;
  final int windowBorderWidth;
  final String activeWindowBorderColor;
  final String normalWindowBorderColor;
  final String insertFeedbackColor;

  /// Animation duration in seconds (0 to disable)
  final double windowAnimationDuration;

  /// Window rules for specific applications
  final List<WindowRule> rules;

  /// Signals for event-based actions
  final List<YabaiSignal> signals;

  /// Per-space configurations
  final List<SpaceConfig> spaces;

  /// Valid layout values
  static const List<String> validLayouts = ['bsp', 'float', 'stack'];

  /// Valid window placement values
  static const List<String> validPlacements = ['first_child', 'second_child'];

  /// Valid mouse modifier values
  static const List<String> validMouseModifiers = ['alt', 'cmd', 'ctrl', 'shift', 'fn'];

  /// Valid mouse action values
  static const List<String> validMouseActions = ['move', 'resize'];

  /// Valid mouse drop action values
  static const List<String> validDropActions = ['swap', 'stack'];

  /// Valid split type values
  static const List<String> validSplitTypes = ['auto', 'vertical', 'horizontal'];

  /// Valid window shadow values
  static const List<String> validShadowOptions = ['on', 'off', 'float'];

  /// Valid focus follows mouse values
  static const List<String> validFocusFollowsMouse = ['off', 'autoraise', 'autofocus'];

  /// Default configuration values
  static const YabaiConfig defaults = YabaiConfig();

  const YabaiConfig({
    this.layout = 'bsp',
    this.windowGap = 6,
    this.topPadding = 6,
    this.bottomPadding = 6,
    this.leftPadding = 6,
    this.rightPadding = 6,
    this.windowPlacement = 'second_child',
    this.externalBar,
    this.mouseFollowsFocus = false,
    this.focusFollowsMouse = 'off',
    this.mouseModifier = 'alt',
    this.mouseAction1 = 'move',
    this.mouseAction2 = 'resize',
    this.mouseDropAction = 'swap',
    this.autoBalance = false,
    this.splitRatio = 0.5,
    this.splitType = 'auto',
    this.windowOpacity = false,
    this.activeWindowOpacity = 1.0,
    this.normalWindowOpacity = 0.9,
    this.windowShadow = 'on',
    this.windowBorder = false,
    this.windowBorderWidth = 4,
    this.activeWindowBorderColor = '0xff775759',
    this.normalWindowBorderColor = '0xff555555',
    this.insertFeedbackColor = '0xffd75f5f',
    this.windowAnimationDuration = 0.0,
    this.rules = const [],
    this.signals = const [],
    this.spaces = const [],
  });

  /// Creates a copy of this YabaiConfig with the given fields replaced
  YabaiConfig copyWith({
    String? layout,
    int? windowGap,
    int? topPadding,
    int? bottomPadding,
    int? leftPadding,
    int? rightPadding,
    String? windowPlacement,
    String? externalBar,
    bool? mouseFollowsFocus,
    String? focusFollowsMouse,
    String? mouseModifier,
    String? mouseAction1,
    String? mouseAction2,
    String? mouseDropAction,
    bool? autoBalance,
    double? splitRatio,
    String? splitType,
    bool? windowOpacity,
    double? activeWindowOpacity,
    double? normalWindowOpacity,
    String? windowShadow,
    bool? windowBorder,
    int? windowBorderWidth,
    String? activeWindowBorderColor,
    String? normalWindowBorderColor,
    String? insertFeedbackColor,
    double? windowAnimationDuration,
    List<WindowRule>? rules,
    List<YabaiSignal>? signals,
    List<SpaceConfig>? spaces,
    bool clearExternalBar = false,
  }) {
    return YabaiConfig(
      layout: layout ?? this.layout,
      windowGap: windowGap ?? this.windowGap,
      topPadding: topPadding ?? this.topPadding,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      leftPadding: leftPadding ?? this.leftPadding,
      rightPadding: rightPadding ?? this.rightPadding,
      windowPlacement: windowPlacement ?? this.windowPlacement,
      externalBar: clearExternalBar ? null : (externalBar ?? this.externalBar),
      mouseFollowsFocus: mouseFollowsFocus ?? this.mouseFollowsFocus,
      focusFollowsMouse: focusFollowsMouse ?? this.focusFollowsMouse,
      mouseModifier: mouseModifier ?? this.mouseModifier,
      mouseAction1: mouseAction1 ?? this.mouseAction1,
      mouseAction2: mouseAction2 ?? this.mouseAction2,
      mouseDropAction: mouseDropAction ?? this.mouseDropAction,
      autoBalance: autoBalance ?? this.autoBalance,
      splitRatio: splitRatio ?? this.splitRatio,
      splitType: splitType ?? this.splitType,
      windowOpacity: windowOpacity ?? this.windowOpacity,
      activeWindowOpacity: activeWindowOpacity ?? this.activeWindowOpacity,
      normalWindowOpacity: normalWindowOpacity ?? this.normalWindowOpacity,
      windowShadow: windowShadow ?? this.windowShadow,
      windowBorder: windowBorder ?? this.windowBorder,
      windowBorderWidth: windowBorderWidth ?? this.windowBorderWidth,
      activeWindowBorderColor: activeWindowBorderColor ?? this.activeWindowBorderColor,
      normalWindowBorderColor: normalWindowBorderColor ?? this.normalWindowBorderColor,
      insertFeedbackColor: insertFeedbackColor ?? this.insertFeedbackColor,
      windowAnimationDuration: windowAnimationDuration ?? this.windowAnimationDuration,
      rules: rules ?? List.from(this.rules),
      signals: signals ?? List.from(this.signals),
      spaces: spaces ?? List.from(this.spaces),
    );
  }

  /// Creates a YabaiConfig from JSON
  factory YabaiConfig.fromJson(Map<String, dynamic> json) {
    return YabaiConfig(
      layout: json['layout'] as String? ?? 'bsp',
      windowGap: json['window_gap'] as int? ?? 6,
      topPadding: json['top_padding'] as int? ?? 6,
      bottomPadding: json['bottom_padding'] as int? ?? 6,
      leftPadding: json['left_padding'] as int? ?? 6,
      rightPadding: json['right_padding'] as int? ?? 6,
      windowPlacement: json['window_placement'] as String? ?? 'second_child',
      externalBar: json['external_bar'] as String?,
      mouseFollowsFocus: json['mouse_follows_focus'] as bool? ?? false,
      focusFollowsMouse: json['focus_follows_mouse'] as String? ?? 'off',
      mouseModifier: json['mouse_modifier'] as String? ?? 'alt',
      mouseAction1: json['mouse_action1'] as String? ?? 'move',
      mouseAction2: json['mouse_action2'] as String? ?? 'resize',
      mouseDropAction: json['mouse_drop_action'] as String? ?? 'swap',
      autoBalance: json['auto_balance'] as bool? ?? false,
      splitRatio: (json['split_ratio'] as num?)?.toDouble() ?? 0.5,
      splitType: json['split_type'] as String? ?? 'auto',
      windowOpacity: json['window_opacity'] as bool? ?? false,
      activeWindowOpacity: (json['active_window_opacity'] as num?)?.toDouble() ?? 1.0,
      normalWindowOpacity: (json['normal_window_opacity'] as num?)?.toDouble() ?? 0.9,
      windowShadow: json['window_shadow'] as String? ?? 'on',
      windowBorder: json['window_border'] as bool? ?? false,
      windowBorderWidth: json['window_border_width'] as int? ?? 4,
      activeWindowBorderColor: json['active_window_border_color'] as String? ?? '0xff775759',
      normalWindowBorderColor: json['normal_window_border_color'] as String? ?? '0xff555555',
      insertFeedbackColor: json['insert_feedback_color'] as String? ?? '0xffd75f5f',
      windowAnimationDuration: (json['window_animation_duration'] as num?)?.toDouble() ?? 0.0,
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => WindowRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      signals: (json['signals'] as List<dynamic>?)
              ?.map((e) => YabaiSignal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      spaces: (json['spaces'] as List<dynamic>?)
              ?.map((e) => SpaceConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this YabaiConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'layout': layout,
      'window_gap': windowGap,
      'top_padding': topPadding,
      'bottom_padding': bottomPadding,
      'left_padding': leftPadding,
      'right_padding': rightPadding,
      'window_placement': windowPlacement,
      if (externalBar != null) 'external_bar': externalBar,
      'mouse_follows_focus': mouseFollowsFocus,
      'focus_follows_mouse': focusFollowsMouse,
      'mouse_modifier': mouseModifier,
      'mouse_action1': mouseAction1,
      'mouse_action2': mouseAction2,
      'mouse_drop_action': mouseDropAction,
      'auto_balance': autoBalance,
      'split_ratio': splitRatio,
      'split_type': splitType,
      'window_opacity': windowOpacity,
      'active_window_opacity': activeWindowOpacity,
      'normal_window_opacity': normalWindowOpacity,
      'window_shadow': windowShadow,
      'window_border': windowBorder,
      'window_border_width': windowBorderWidth,
      'active_window_border_color': activeWindowBorderColor,
      'normal_window_border_color': normalWindowBorderColor,
      'insert_feedback_color': insertFeedbackColor,
      'window_animation_duration': windowAnimationDuration,
      'rules': rules.map((r) => r.toJson()).toList(),
      'signals': signals.map((s) => s.toJson()).toList(),
      'spaces': spaces.map((s) => s.toJson()).toList(),
    };
  }

  /// Generates the complete yabairc file content
  /// [exclusionRules] - Optional list of exclusion rules to include
  String toYabairc({List<ExclusionRule>? exclusionRules}) {
    final buffer = StringBuffer();
    buffer.writeln('#!/usr/bin/env sh');
    buffer.writeln();
    buffer.writeln('# yabai configuration');
    buffer.writeln('# Generated by Yabai Config');
    buffer.writeln();

    // Window rules (exclusions) - FIRST so they apply before any other config
    buffer.writeln('# === Window Rules (Exclusions) ===');
    if (exclusionRules != null && exclusionRules.isNotEmpty) {
      for (final rule in exclusionRules) {
        if (rule.isEnabled) {
          final cmd = rule.toYabaiCommand();
          if (cmd.isNotEmpty) {
            buffer.writeln(cmd);
          }
        }
      }
    } else {
      // Fallback: always exclude yabai_config app from management
      buffer.writeln('yabai -m rule --add app="^yabai_config\$" manage=off');
    }
    // Also include any rules from the config model
    for (final rule in rules) {
      for (final cmd in rule.toYabaiCommands()) {
        buffer.writeln(cmd);
      }
    }
    buffer.writeln();

    // Layout settings
    buffer.writeln('# === Layout ===');
    buffer.writeln('yabai -m config layout $layout');
    buffer.writeln('yabai -m config window_placement $windowPlacement');
    buffer.writeln('yabai -m config auto_balance ${autoBalance ? 'on' : 'off'}');
    buffer.writeln('yabai -m config split_ratio $splitRatio');
    buffer.writeln('yabai -m config split_type $splitType');
    buffer.writeln();

    // Gaps and padding
    buffer.writeln('# === Gaps and Padding ===');
    buffer.writeln('yabai -m config window_gap $windowGap');
    buffer.writeln('yabai -m config top_padding $topPadding');
    buffer.writeln('yabai -m config bottom_padding $bottomPadding');
    buffer.writeln('yabai -m config left_padding $leftPadding');
    buffer.writeln('yabai -m config right_padding $rightPadding');
    buffer.writeln();

    // External bar
    if (externalBar != null) {
      buffer.writeln('# === External Bar ===');
      buffer.writeln('yabai -m config external_bar $externalBar');
      buffer.writeln();
    }

    // Mouse settings
    buffer.writeln('# === Mouse ===');
    buffer.writeln('yabai -m config mouse_follows_focus ${mouseFollowsFocus ? 'on' : 'off'}');
    buffer.writeln('yabai -m config focus_follows_mouse $focusFollowsMouse');
    buffer.writeln('yabai -m config mouse_modifier $mouseModifier');
    buffer.writeln('yabai -m config mouse_action1 $mouseAction1');
    buffer.writeln('yabai -m config mouse_action2 $mouseAction2');
    buffer.writeln('yabai -m config mouse_drop_action $mouseDropAction');
    buffer.writeln();

    // Window appearance
    buffer.writeln('# === Window Appearance ===');
    buffer.writeln('yabai -m config window_opacity ${windowOpacity ? 'on' : 'off'}');
    if (windowOpacity) {
      buffer.writeln('yabai -m config active_window_opacity $activeWindowOpacity');
      buffer.writeln('yabai -m config normal_window_opacity $normalWindowOpacity');
    }
    buffer.writeln('yabai -m config window_shadow $windowShadow');
    buffer.writeln('yabai -m config window_animation_duration $windowAnimationDuration');
    buffer.writeln();

    // Window borders
    buffer.writeln('# === Window Borders ===');
    buffer.writeln('yabai -m config window_border ${windowBorder ? 'on' : 'off'}');
    if (windowBorder) {
      buffer.writeln('yabai -m config window_border_width $windowBorderWidth');
      buffer.writeln('yabai -m config active_window_border_color $activeWindowBorderColor');
      buffer.writeln('yabai -m config normal_window_border_color $normalWindowBorderColor');
      buffer.writeln('yabai -m config insert_feedback_color $insertFeedbackColor');
    }
    buffer.writeln();

    // Space configurations
    if (spaces.isNotEmpty) {
      buffer.writeln('# === Space Configurations ===');
      for (final space in spaces) {
        for (final cmd in space.toYabaiCommands()) {
          buffer.writeln(cmd);
        }
      }
      buffer.writeln();
    }

    // Signals
    if (signals.isNotEmpty) {
      buffer.writeln('# === Signals ===');
      for (final signal in signals) {
        final cmd = signal.toYabaiCommand();
        if (cmd.isNotEmpty) {
          buffer.writeln(cmd);
        }
      }
      buffer.writeln();
    }

    buffer.writeln('echo "yabai configuration loaded..."');

    return buffer.toString();
  }

  /// Returns a human-readable description of the layout
  String get layoutDescription {
    switch (layout) {
      case 'bsp':
        return 'Binary Space Partitioning';
      case 'float':
        return 'Floating';
      case 'stack':
        return 'Stacked';
      default:
        return layout;
    }
  }

  /// Returns uniform padding if all sides are equal, null otherwise
  int? get uniformPadding {
    if (topPadding == bottomPadding &&
        bottomPadding == leftPadding &&
        leftPadding == rightPadding) {
      return topPadding;
    }
    return null;
  }

  /// Sets all padding to the same value
  YabaiConfig withUniformPadding(int padding) {
    return copyWith(
      topPadding: padding,
      bottomPadding: padding,
      leftPadding: padding,
      rightPadding: padding,
    );
  }

  /// Rule management helpers
  YabaiConfig addRule(WindowRule rule) {
    return copyWith(rules: [...rules, rule]);
  }

  YabaiConfig removeRule(String id) {
    return copyWith(rules: rules.where((r) => r.id != id).toList());
  }

  YabaiConfig updateRule(WindowRule rule) {
    return copyWith(rules: rules.map((r) => r.id == rule.id ? rule : r).toList());
  }

  WindowRule? findRuleById(String id) {
    try {
      return rules.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Signal management helpers
  YabaiConfig addSignal(YabaiSignal signal) {
    return copyWith(signals: [...signals, signal]);
  }

  YabaiConfig removeSignal(String id) {
    return copyWith(signals: signals.where((s) => s.id != id).toList());
  }

  YabaiConfig updateSignal(YabaiSignal signal) {
    return copyWith(signals: signals.map((s) => s.id == signal.id ? signal : s).toList());
  }

  YabaiSignal? findSignalById(String id) {
    try {
      return signals.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Space management helpers
  YabaiConfig addSpace(SpaceConfig space) {
    return copyWith(spaces: [...spaces, space]);
  }

  YabaiConfig removeSpace(int index) {
    return copyWith(spaces: spaces.where((s) => s.index != index).toList());
  }

  YabaiConfig updateSpace(SpaceConfig space) {
    return copyWith(spaces: spaces.map((s) => s.index == space.index ? space : s).toList());
  }

  /// Get space config by index
  SpaceConfig? getSpaceConfig(int index) {
    try {
      return spaces.firstWhere((s) => s.index == index);
    } catch (_) {
      return null;
    }
  }

  /// Statistics helpers
  int get enabledRulesCount => rules.where((r) => r.enabled).length;
  int get enabledSignalsCount => signals.where((s) => s.enabled).length;
  int get customizedSpacesCount => spaces.where((s) => s.hasCustomization).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YabaiConfig &&
        other.layout == layout &&
        other.windowGap == windowGap &&
        other.topPadding == topPadding &&
        other.bottomPadding == bottomPadding &&
        other.leftPadding == leftPadding &&
        other.rightPadding == rightPadding &&
        other.windowPlacement == windowPlacement &&
        other.externalBar == externalBar &&
        other.mouseFollowsFocus == mouseFollowsFocus &&
        other.focusFollowsMouse == focusFollowsMouse &&
        other.mouseModifier == mouseModifier &&
        other.mouseAction1 == mouseAction1 &&
        other.mouseAction2 == mouseAction2 &&
        other.mouseDropAction == mouseDropAction &&
        other.autoBalance == autoBalance &&
        other.splitRatio == splitRatio &&
        other.splitType == splitType &&
        other.windowOpacity == windowOpacity &&
        other.activeWindowOpacity == activeWindowOpacity &&
        other.normalWindowOpacity == normalWindowOpacity &&
        other.windowShadow == windowShadow &&
        other.windowBorder == windowBorder &&
        other.windowBorderWidth == windowBorderWidth &&
        other.activeWindowBorderColor == activeWindowBorderColor &&
        other.normalWindowBorderColor == normalWindowBorderColor &&
        other.insertFeedbackColor == insertFeedbackColor &&
        other.windowAnimationDuration == windowAnimationDuration &&
        listEquals(other.rules, rules) &&
        listEquals(other.signals, signals) &&
        listEquals(other.spaces, spaces);
  }

  @override
  int get hashCode {
    return Object.hash(
      layout,
      windowGap,
      topPadding,
      bottomPadding,
      leftPadding,
      rightPadding,
      windowPlacement,
      externalBar,
      mouseFollowsFocus,
      focusFollowsMouse,
      mouseModifier,
      mouseAction1,
      mouseAction2,
      mouseDropAction,
      autoBalance,
      splitRatio,
      Object.hash(
        splitType,
        windowOpacity,
        activeWindowOpacity,
        normalWindowOpacity,
        windowShadow,
        windowBorder,
        windowBorderWidth,
        activeWindowBorderColor,
        normalWindowBorderColor,
        insertFeedbackColor,
        windowAnimationDuration,
        Object.hashAll(rules),
        Object.hashAll(signals),
        Object.hashAll(spaces),
      ),
    );
  }

  @override
  String toString() {
    return 'YabaiConfig(layout: $layout, windowGap: $windowGap, '
        'rules: ${rules.length}, signals: ${signals.length}, '
        'spaces: ${spaces.length})';
  }
}
