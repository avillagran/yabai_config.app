import 'package:flutter/foundation.dart';

/// Shortcut categories for organizing keybindings
enum ShortcutCategory {
  focus('focus', 'Focus', 'Window focus commands'),
  move('move', 'Move', 'Window movement commands'),
  resize('resize', 'Resize', 'Window resize commands'),
  layout('layout', 'Layout', 'Layout switching commands'),
  space('space', 'Space', 'Space/desktop commands'),
  display('display', 'Display', 'Display/monitor commands'),
  custom('custom', 'Custom', 'User-defined commands');

  final String value;
  final String displayName;
  final String description;

  const ShortcutCategory(this.value, this.displayName, this.description);

  static ShortcutCategory? fromString(String? value) {
    if (value == null) return null;
    return ShortcutCategory.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => ShortcutCategory.custom,
    );
  }
}

/// A keyboard shortcut configuration for skhd
class Shortcut {
  /// Unique identifier for this shortcut
  final String id;

  /// List of modifier keys (alt, shift, ctrl, cmd)
  final List<String> modifiers;

  /// The main key for this shortcut
  final String key;

  /// The yabai command or action to execute
  final String action;

  /// Optional category for organizing shortcuts
  final String? category;

  /// Whether this shortcut is currently enabled
  final bool enabled;

  /// Optional description for this shortcut
  final String? description;

  /// Valid modifier keys
  static const List<String> validModifiers = ['alt', 'shift', 'ctrl', 'cmd', 'fn', 'hyper', 'meh'];

  /// Common special keys
  static const List<String> specialKeys = [
    'return', 'tab', 'space', 'backspace', 'escape',
    'delete', 'home', 'end', 'pageup', 'pagedown',
    'left', 'right', 'up', 'down',
    'f1', 'f2', 'f3', 'f4', 'f5', 'f6',
    'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
  ];

  const Shortcut({
    required this.id,
    required this.modifiers,
    required this.key,
    required this.action,
    this.category,
    this.enabled = true,
    this.description,
  });

  /// Creates a copy of this Shortcut with the given fields replaced
  Shortcut copyWith({
    String? id,
    List<String>? modifiers,
    String? key,
    String? action,
    String? category,
    bool? enabled,
    String? description,
    bool clearCategory = false,
    bool clearDescription = false,
  }) {
    return Shortcut(
      id: id ?? this.id,
      modifiers: modifiers ?? List.from(this.modifiers),
      key: key ?? this.key,
      action: action ?? this.action,
      category: clearCategory ? null : (category ?? this.category),
      enabled: enabled ?? this.enabled,
      description: clearDescription ? null : (description ?? this.description),
    );
  }

  /// Creates a Shortcut from JSON
  factory Shortcut.fromJson(Map<String, dynamic> json) {
    return Shortcut(
      id: json['id'] as String,
      modifiers: (json['modifiers'] as List<dynamic>).cast<String>(),
      key: json['key'] as String,
      action: json['action'] as String,
      category: json['category'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  /// Converts this Shortcut to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modifiers': modifiers,
      'key': key,
      'action': action,
      if (category != null) 'category': category,
      'enabled': enabled,
      if (description != null) 'description': description,
    };
  }

  /// Generates the skhd hotkey string (e.g., "alt + shift - j")
  String toSkhdHotkey() {
    if (modifiers.isEmpty) {
      return key;
    }
    return '${modifiers.join(' + ')} - $key';
  }

  /// Generates the complete skhd config line
  String toSkhdLine() {
    final comment = description != null ? '# $description\n' : '';
    if (!enabled) {
      return '$comment# [DISABLED] ${toSkhdHotkey()} : $action';
    }
    return '$comment${toSkhdHotkey()} : $action';
  }

  /// Parses an skhd config line into a Shortcut
  static Shortcut? fromSkhdLine(String line, {String? id, String? precedingComment}) {
    // Skip comments and empty lines
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      return null;
    }

    // Split on ' : ' to separate hotkey from action
    final colonIndex = trimmed.indexOf(' : ');
    if (colonIndex == -1) return null;

    final hotkeyPart = trimmed.substring(0, colonIndex).trim();
    final actionPart = trimmed.substring(colonIndex + 3).trim();

    // Parse the hotkey
    final hotkeyMatch = RegExp(r'^(.+?)\s*-\s*(\S+)$').firstMatch(hotkeyPart);

    List<String> modifiers;
    String key;

    if (hotkeyMatch != null) {
      final modifiersPart = hotkeyMatch.group(1)!;
      modifiers = modifiersPart
          .split('+')
          .map((m) => m.trim().toLowerCase())
          .where((m) => m.isNotEmpty)
          .toList();
      key = hotkeyMatch.group(2)!;
    } else {
      // No modifiers, just the key
      modifiers = [];
      key = hotkeyPart;
    }

    return Shortcut(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      modifiers: modifiers,
      key: key,
      action: actionPart,
      enabled: true,
      description: precedingComment,
    );
  }

  /// Returns a human-readable display string for this shortcut
  String get displayString {
    final modifierSymbols = modifiers.map((m) {
      switch (m.toLowerCase()) {
        case 'cmd':
          return '\u2318'; // Command symbol
        case 'alt':
          return '\u2325'; // Option symbol
        case 'ctrl':
          return '\u2303'; // Control symbol
        case 'shift':
          return '\u21E7'; // Shift symbol
        case 'fn':
          return 'fn';
        case 'hyper':
          return 'Hyper';
        case 'meh':
          return 'Meh';
        default:
          return m;
      }
    }).join('');

    return '$modifierSymbols${key.toUpperCase()}';
  }

  /// Returns the category enum value if valid
  ShortcutCategory? get categoryEnum => ShortcutCategory.fromString(category);

  /// Checks if this shortcut targets yabai
  bool get isYabaiShortcut => action.contains('yabai');

  /// Checks if modifiers are valid
  bool get hasValidModifiers => modifiers.every(
    (m) => validModifiers.contains(m.toLowerCase())
  );

  /// Auto-detect category from the action command
  static String? detectCategoryFromAction(String action) {
    final lowerAction = action.toLowerCase();

    // Check for yabai commands with -m flag
    if (lowerAction.contains('yabai')) {
      // Window focus commands
      if (lowerAction.contains('-m window') && lowerAction.contains('--focus')) {
        return 'focus';
      }
      // Window swap/warp/move commands
      if (lowerAction.contains('-m window') &&
          (lowerAction.contains('--swap') ||
           lowerAction.contains('--warp') ||
           lowerAction.contains('--move'))) {
        return 'move';
      }
      // Window resize commands
      if (lowerAction.contains('-m window') &&
          (lowerAction.contains('--resize') ||
           lowerAction.contains('--ratio') ||
           lowerAction.contains('--toggle zoom'))) {
        return 'resize';
      }
      // Window toggle commands (float, sticky, etc.)
      if (lowerAction.contains('-m window') && lowerAction.contains('--toggle')) {
        return 'layout';
      }
      // Space commands
      if (lowerAction.contains('-m space') ||
          lowerAction.contains('-m window --space')) {
        return 'space';
      }
      // Display commands
      if (lowerAction.contains('-m display') ||
          lowerAction.contains('-m window --display')) {
        return 'display';
      }
      // Layout commands
      if (lowerAction.contains('-m config layout') ||
          lowerAction.contains('-m space --layout')) {
        return 'layout';
      }
      // Balance/equalize commands
      if (lowerAction.contains('--balance') ||
          lowerAction.contains('--equalize')) {
        return 'layout';
      }
    }

    return 'custom';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shortcut &&
        other.id == id &&
        listEquals(other.modifiers, modifiers) &&
        other.key == key &&
        other.action == action &&
        other.category == category &&
        other.enabled == enabled &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(modifiers),
      key,
      action,
      category,
      enabled,
      description,
    );
  }

  @override
  String toString() {
    return 'Shortcut(id: $id, modifiers: $modifiers, key: $key, '
        'action: $action, category: $category, enabled: $enabled)';
  }
}

/// Complete skhd configuration containing all shortcuts
class SkhdConfig {
  /// List of all configured shortcuts
  final List<Shortcut> shortcuts;

  const SkhdConfig({
    this.shortcuts = const [],
  });

  /// Creates a copy of this SkhdConfig with the given fields replaced
  SkhdConfig copyWith({
    List<Shortcut>? shortcuts,
  }) {
    return SkhdConfig(
      shortcuts: shortcuts ?? List.from(this.shortcuts),
    );
  }

  /// Creates an SkhdConfig from JSON
  factory SkhdConfig.fromJson(Map<String, dynamic> json) {
    return SkhdConfig(
      shortcuts: (json['shortcuts'] as List<dynamic>?)
              ?.map((e) => Shortcut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this SkhdConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'shortcuts': shortcuts.map((s) => s.toJson()).toList(),
    };
  }

  /// Generates the complete skhdrc file content
  String toSkhdrc() {
    final buffer = StringBuffer();
    buffer.writeln('# skhd configuration');
    buffer.writeln('# Generated by Yabai Config');
    buffer.writeln();

    // Group shortcuts by category
    final grouped = <String?, List<Shortcut>>{};
    for (final shortcut in shortcuts) {
      grouped.putIfAbsent(shortcut.category, () => []).add(shortcut);
    }

    // Sort categories with known ones first, then custom/null
    final categoryOrder = ['focus', 'move', 'resize', 'layout', 'space', 'display', 'custom', null];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder.indexOf(a);
        final bIndex = categoryOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return 0;
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    // Write each category
    for (final category in sortedKeys) {
      final categoryName = category != null
          ? ShortcutCategory.fromString(category)?.displayName ?? category
          : 'Uncategorized';
      buffer.writeln('# === $categoryName ===');
      for (final shortcut in grouped[category]!) {
        buffer.writeln(shortcut.toSkhdLine());
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Parses an skhdrc file content into SkhdConfig
  factory SkhdConfig.fromSkhdrc(String content) {
    final shortcuts = <Shortcut>[];
    final lines = content.split('\n');
    int idCounter = 0;
    String? currentCategory;
    String? pendingComment;

    for (final line in lines) {
      final trimmed = line.trim();

      // Check for category comments
      final categoryMatch = RegExp(r'^#\s*===\s*(.+?)\s*===').firstMatch(trimmed);
      if (categoryMatch != null) {
        currentCategory = categoryMatch.group(1)?.toLowerCase();
        continue;
      }

      // Check for regular comments (potential descriptions)
      if (trimmed.startsWith('#') && !trimmed.startsWith('# [DISABLED]')) {
        pendingComment = trimmed.substring(1).trim();
        continue;
      }

      // Try to parse as shortcut
      final shortcut = Shortcut.fromSkhdLine(
        line,
        id: 'shortcut_${idCounter++}',
        precedingComment: pendingComment,
      );

      if (shortcut != null) {
        // Use category from comment if available, otherwise auto-detect from action
        final category = currentCategory ?? Shortcut.detectCategoryFromAction(shortcut.action);
        shortcuts.add(shortcut.copyWith(category: category));
      }

      pendingComment = null;
    }

    return SkhdConfig(shortcuts: shortcuts);
  }

  /// Returns shortcuts filtered by category
  List<Shortcut> getByCategory(String? category) {
    return shortcuts.where((s) => s.category == category).toList();
  }

  /// Returns all unique categories
  List<String?> get categories {
    return shortcuts.map((s) => s.category).toSet().toList();
  }

  /// Returns the number of enabled shortcuts
  int get enabledCount => shortcuts.where((s) => s.enabled).length;

  /// Returns the number of disabled shortcuts
  int get disabledCount => shortcuts.where((s) => !s.enabled).length;

  /// Adds a shortcut and returns a new config
  SkhdConfig addShortcut(Shortcut shortcut) {
    return copyWith(shortcuts: [...shortcuts, shortcut]);
  }

  /// Removes a shortcut by id and returns a new config
  SkhdConfig removeShortcut(String id) {
    return copyWith(
      shortcuts: shortcuts.where((s) => s.id != id).toList(),
    );
  }

  /// Updates a shortcut and returns a new config
  SkhdConfig updateShortcut(Shortcut shortcut) {
    return copyWith(
      shortcuts: shortcuts.map((s) => s.id == shortcut.id ? shortcut : s).toList(),
    );
  }

  /// Finds a shortcut by id
  Shortcut? findById(String id) {
    try {
      return shortcuts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a hotkey combination is already in use
  bool isHotkeyInUse(List<String> modifiers, String key, {String? excludeId}) {
    final sortedMods = List<String>.from(modifiers)..sort();
    return shortcuts.any((s) {
      if (s.id == excludeId) return false;
      if (!s.enabled) return false;
      final sMods = List<String>.from(s.modifiers)..sort();
      return listEquals(sMods, sortedMods) &&
             s.key.toLowerCase() == key.toLowerCase();
    });
  }

  /// Returns shortcuts that conflict with the given hotkey
  List<Shortcut> getConflictingShortcuts(List<String> modifiers, String key, {String? excludeId}) {
    final sortedMods = List<String>.from(modifiers)..sort();
    return shortcuts.where((s) {
      if (s.id == excludeId) return false;
      if (!s.enabled) return false;
      final sMods = List<String>.from(s.modifiers)..sort();
      return listEquals(sMods, sortedMods) &&
             s.key.toLowerCase() == key.toLowerCase();
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkhdConfig && listEquals(other.shortcuts, shortcuts);
  }

  @override
  int get hashCode => Object.hashAll(shortcuts);

  @override
  String toString() {
    return 'SkhdConfig(shortcuts: ${shortcuts.length}, enabled: $enabledCount)';
  }
}
