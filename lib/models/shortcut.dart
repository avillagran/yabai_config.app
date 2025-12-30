import 'package:flutter/foundation.dart';

/// Represents a keyboard shortcut for SKHD.
///
/// A shortcut consists of:
/// - One or more modifier keys (alt, shift, ctrl, cmd)
/// - A trigger key
/// - An action command (typically a yabai command)
/// - Optional metadata like category and description
@immutable
class Shortcut {
  /// The modifier keys for this shortcut
  final List<String> modifiers;

  /// The trigger key for this shortcut
  final String key;

  /// The action/command to execute
  final String action;

  /// Optional category for grouping shortcuts
  final String? category;

  /// Optional human-readable description
  final String? description;

  /// Whether this shortcut is enabled
  final bool enabled;

  /// Optional label/identifier
  final String? label;

  const Shortcut({
    required this.modifiers,
    required this.key,
    required this.action,
    this.category,
    this.description,
    this.enabled = true,
    this.label,
  });

  /// Create a shortcut from SKHD line format
  /// Format: "modifier + modifier - key : action"
  factory Shortcut.fromSkhdLine(String line) {
    final trimmed = line.trim();

    // Skip comments and empty lines
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      throw FormatException('Invalid shortcut line: $line');
    }

    // Split by colon to separate hotkey from action
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex == -1) {
      throw FormatException('Missing colon separator: $line');
    }

    final hotkeyPart = trimmed.substring(0, colonIndex).trim();
    final actionPart = trimmed.substring(colonIndex + 1).trim();

    // Parse hotkey: "modifier + modifier - key"
    // Find the last " - " which separates modifiers from key
    final lastDash = hotkeyPart.lastIndexOf(' - ');
    if (lastDash == -1) {
      // Try without spaces around dash
      final dashIndex = hotkeyPart.lastIndexOf('-');
      if (dashIndex == -1) {
        throw FormatException('Missing key separator: $line');
      }
      final modPart = hotkeyPart.substring(0, dashIndex).trim();
      final key = hotkeyPart.substring(dashIndex + 1).trim();

      final modifiers = modPart
          .split('+')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      return Shortcut(modifiers: modifiers, key: key, action: actionPart);
    }

    final modPart = hotkeyPart.substring(0, lastDash).trim();
    final key = hotkeyPart.substring(lastDash + 3).trim();

    final modifiers = modPart
        .split('+')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    return Shortcut(modifiers: modifiers, key: key, action: actionPart);
  }

  /// Convert to SKHD format string
  String toSkhdLine() {
    final modStr = modifiers.join(' + ');
    final hotkeyStr = modStr.isEmpty ? key : '$modStr - $key';
    return '$hotkeyStr : $action';
  }

  /// Get a display-friendly representation of the hotkey
  String get hotkeyDisplay {
    final modSymbols = modifiers.map(_modifierSymbol).join('');
    final keySymbol = _keySymbol(key);
    return '$modSymbols$keySymbol';
  }

  /// Get the modifier symbols for display
  static String _modifierSymbol(String modifier) {
    switch (modifier.toLowerCase()) {
      case 'cmd':
      case 'lcmd':
      case 'rcmd':
        return '\u2318'; // Command
      case 'alt':
      case 'lalt':
      case 'ralt':
        return '\u2325'; // Option
      case 'shift':
      case 'lshift':
      case 'rshift':
        return '\u21E7'; // Shift
      case 'ctrl':
      case 'lctrl':
      case 'rctrl':
        return '\u2303'; // Control
      case 'fn':
        return 'fn';
      case 'hyper':
        return '\u2303\u2325\u21E7\u2318';
      default:
        return modifier;
    }
  }

  /// Get the key symbol for display
  static String _keySymbol(String key) {
    switch (key.toLowerCase()) {
      case 'left':
        return '\u2190';
      case 'right':
        return '\u2192';
      case 'up':
        return '\u2191';
      case 'down':
        return '\u2193';
      case 'space':
        return 'Space';
      case 'tab':
        return '\u21E5';
      case 'return':
        return '\u23CE';
      case 'escape':
        return '\u238B';
      case 'delete':
        return '\u232B';
      default:
        return key.toUpperCase();
    }
  }

  /// Create a copy with modified fields
  Shortcut copyWith({
    List<String>? modifiers,
    String? key,
    String? action,
    String? category,
    String? description,
    bool? enabled,
    String? label,
  }) {
    return Shortcut(
      modifiers: modifiers ?? this.modifiers,
      key: key ?? this.key,
      action: action ?? this.action,
      category: category ?? this.category,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'modifiers': modifiers,
      'key': key,
      'action': action,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      'enabled': enabled,
      if (label != null) 'label': label,
    };
  }

  /// Create from JSON map
  factory Shortcut.fromJson(Map<String, dynamic> json) {
    return Shortcut(
      modifiers: List<String>.from(json['modifiers'] as List),
      key: json['key'] as String,
      action: json['action'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Shortcut) return false;

    return listEquals(modifiers, other.modifiers) &&
        key == other.key &&
        action == other.action &&
        category == other.category &&
        description == other.description &&
        enabled == other.enabled &&
        label == other.label;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(modifiers),
      key,
      action,
      category,
      description,
      enabled,
      label,
    );
  }

  @override
  String toString() {
    return 'Shortcut(${toSkhdLine()})';
  }
}

/// Categories for organizing shortcuts
class ShortcutCategory {
  ShortcutCategory._();

  static const String focus = 'focus';
  static const String swap = 'swap';
  static const String warp = 'warp';
  static const String resize = 'resize';
  static const String move = 'move';
  static const String space = 'space';
  static const String display = 'display';
  static const String layout = 'layout';
  static const String toggle = 'toggle';
  static const String stack = 'stack';
  static const String custom = 'custom';

  static const List<String> all = [
    focus,
    swap,
    warp,
    resize,
    move,
    space,
    display,
    layout,
    toggle,
    stack,
    custom,
  ];

  static const Map<String, String> displayNames = {
    focus: 'Focus Window',
    swap: 'Swap Window',
    warp: 'Warp Window',
    resize: 'Resize Window',
    move: 'Move Window',
    space: 'Space Navigation',
    display: 'Display Navigation',
    layout: 'Layout Control',
    toggle: 'Toggle Features',
    stack: 'Stack Management',
    custom: 'Custom',
  };

  static const Map<String, String> descriptions = {
    focus: 'Move keyboard focus between windows',
    swap: 'Swap window positions',
    warp: 'Re-insert window at a new position',
    resize: 'Change window dimensions',
    move: 'Move windows to different locations',
    space: 'Navigate between spaces',
    display: 'Navigate between displays',
    layout: 'Change tiling layout modes',
    toggle: 'Toggle window properties',
    stack: 'Manage stacked windows',
    custom: 'User-defined shortcuts',
  };
}
