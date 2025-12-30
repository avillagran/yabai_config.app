import 'package:flutter/foundation.dart';

/// Categories for organizing keyboard shortcuts
enum ShortcutCategory {
  focus('Focus'),
  move('Move'),
  resize('Resize'),
  layout('Layout'),
  spaces('Spaces'),
  custom('Custom');

  final String displayName;
  const ShortcutCategory(this.displayName);
}

/// Model representing a keyboard shortcut for skhd
@immutable
class KeyboardShortcut {
  final String id;
  final String keyCombo;
  final String action;
  final String description;
  final ShortcutCategory category;
  final bool isEnabled;

  const KeyboardShortcut({
    required this.id,
    required this.keyCombo,
    required this.action,
    required this.description,
    required this.category,
    this.isEnabled = true,
  });

  KeyboardShortcut copyWith({
    String? id,
    String? keyCombo,
    String? action,
    String? description,
    ShortcutCategory? category,
    bool? isEnabled,
  }) {
    return KeyboardShortcut(
      id: id ?? this.id,
      keyCombo: keyCombo ?? this.keyCombo,
      action: action ?? this.action,
      description: description ?? this.description,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert to skhd config line
  String toSkhdConfig() {
    if (!isEnabled) {
      return '# $keyCombo : $action';
    }
    return '$keyCombo : $action';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyCombo': keyCombo,
      'action': action,
      'description': description,
      'category': category.name,
      'isEnabled': isEnabled,
    };
  }

  factory KeyboardShortcut.fromJson(Map<String, dynamic> json) {
    return KeyboardShortcut(
      id: json['id'] as String,
      keyCombo: json['keyCombo'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      category: ShortcutCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ShortcutCategory.custom,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Auto-detect category from the action command
  static ShortcutCategory detectCategoryFromAction(String action) {
    final lowerAction = action.toLowerCase();

    if (lowerAction.contains('yabai')) {
      // Window focus commands
      if (lowerAction.contains('-m window') && lowerAction.contains('--focus')) {
        return ShortcutCategory.focus;
      }
      // Window swap/warp/move commands
      if (lowerAction.contains('-m window') &&
          (lowerAction.contains('--swap') ||
           lowerAction.contains('--warp') ||
           lowerAction.contains('--move'))) {
        return ShortcutCategory.move;
      }
      // Window resize commands
      if (lowerAction.contains('-m window') &&
          (lowerAction.contains('--resize') ||
           lowerAction.contains('--ratio') ||
           lowerAction.contains('--toggle zoom'))) {
        return ShortcutCategory.resize;
      }
      // Layout commands (toggle float, sticky, layout changes)
      if ((lowerAction.contains('-m window') && lowerAction.contains('--toggle')) ||
          lowerAction.contains('-m config layout') ||
          lowerAction.contains('-m space --layout') ||
          lowerAction.contains('--balance') ||
          lowerAction.contains('--rotate') ||
          lowerAction.contains('--mirror')) {
        return ShortcutCategory.layout;
      }
      // Space/display commands
      if (lowerAction.contains('-m space') ||
          lowerAction.contains('-m window --space') ||
          lowerAction.contains('-m display') ||
          lowerAction.contains('-m window --display')) {
        return ShortcutCategory.spaces;
      }
    }

    return ShortcutCategory.custom;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeyboardShortcut &&
        other.id == id &&
        other.keyCombo == keyCombo &&
        other.action == action &&
        other.description == description &&
        other.category == category &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      keyCombo,
      action,
      description,
      category,
      isEnabled,
    );
  }
}

/// Common Yabai commands for shortcuts
class YabaiCommands {
  static const Map<String, String> focusCommands = {
    'yabai -m window --focus west': 'Focus window to the west',
    'yabai -m window --focus east': 'Focus window to the east',
    'yabai -m window --focus north': 'Focus window to the north',
    'yabai -m window --focus south': 'Focus window to the south',
    'yabai -m window --focus recent': 'Focus recent window',
    'yabai -m window --focus next': 'Focus next window',
    'yabai -m window --focus prev': 'Focus previous window',
  };

  static const Map<String, String> moveCommands = {
    'yabai -m window --swap west': 'Swap with window to the west',
    'yabai -m window --swap east': 'Swap with window to the east',
    'yabai -m window --swap north': 'Swap with window to the north',
    'yabai -m window --swap south': 'Swap with window to the south',
    'yabai -m window --warp west': 'Warp to the west',
    'yabai -m window --warp east': 'Warp to the east',
    'yabai -m window --warp north': 'Warp to the north',
    'yabai -m window --warp south': 'Warp to the south',
  };

  static const Map<String, String> resizeCommands = {
    'yabai -m window --resize left:-20:0': 'Resize left edge inward',
    'yabai -m window --resize right:20:0': 'Resize right edge outward',
    'yabai -m window --resize top:0:-20': 'Resize top edge inward',
    'yabai -m window --resize bottom:0:20': 'Resize bottom edge outward',
    'yabai -m window --resize left:20:0': 'Resize left edge outward',
    'yabai -m window --resize right:-20:0': 'Resize right edge inward',
    'yabai -m window --ratio abs:0.5': 'Balance split ratio',
  };

  static const Map<String, String> layoutCommands = {
    'yabai -m space --layout bsp': 'Set BSP layout',
    'yabai -m space --layout stack': 'Set Stack layout',
    'yabai -m space --layout float': 'Set Float layout',
    'yabai -m window --toggle float': 'Toggle window float',
    'yabai -m window --toggle sticky': 'Toggle window sticky',
    'yabai -m window --toggle zoom-fullscreen': 'Toggle fullscreen zoom',
    'yabai -m window --toggle zoom-parent': 'Toggle parent zoom',
    'yabai -m space --rotate 90': 'Rotate layout 90 degrees',
    'yabai -m space --rotate 270': 'Rotate layout 270 degrees',
    'yabai -m space --mirror x-axis': 'Mirror on X axis',
    'yabai -m space --mirror y-axis': 'Mirror on Y axis',
    'yabai -m space --balance': 'Balance all windows',
  };

  static const Map<String, String> spacesCommands = {
    'yabai -m space --focus 1': 'Focus space 1',
    'yabai -m space --focus 2': 'Focus space 2',
    'yabai -m space --focus 3': 'Focus space 3',
    'yabai -m space --focus 4': 'Focus space 4',
    'yabai -m space --focus 5': 'Focus space 5',
    'yabai -m space --focus 6': 'Focus space 6',
    'yabai -m space --focus 7': 'Focus space 7',
    'yabai -m space --focus 8': 'Focus space 8',
    'yabai -m space --focus 9': 'Focus space 9',
    'yabai -m space --focus next': 'Focus next space',
    'yabai -m space --focus prev': 'Focus previous space',
    'yabai -m space --focus recent': 'Focus recent space',
    'yabai -m window --space 1': 'Move window to space 1',
    'yabai -m window --space 2': 'Move window to space 2',
    'yabai -m window --space 3': 'Move window to space 3',
    'yabai -m window --space 4': 'Move window to space 4',
    'yabai -m window --space 5': 'Move window to space 5',
    'yabai -m window --space 6': 'Move window to space 6',
    'yabai -m window --space 7': 'Move window to space 7',
    'yabai -m window --space 8': 'Move window to space 8',
    'yabai -m window --space 9': 'Move window to space 9',
    'yabai -m window --space next': 'Move window to next space',
    'yabai -m window --space prev': 'Move window to previous space',
  };

  static Map<String, String> get allCommands => {
        ...focusCommands,
        ...moveCommands,
        ...resizeCommands,
        ...layoutCommands,
        ...spacesCommands,
      };

  static Map<String, String> commandsForCategory(ShortcutCategory category) {
    switch (category) {
      case ShortcutCategory.focus:
        return focusCommands;
      case ShortcutCategory.move:
        return moveCommands;
      case ShortcutCategory.resize:
        return resizeCommands;
      case ShortcutCategory.layout:
        return layoutCommands;
      case ShortcutCategory.spaces:
        return spacesCommands;
      case ShortcutCategory.custom:
        return {};
    }
  }
}

/// Default vim-style preset shortcuts
class PresetShortcuts {
  static List<KeyboardShortcut> get vimStylePreset {
    int id = 0;
    String nextId() => 'preset_${++id}';

    return [
      // Focus with alt + hjkl
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - h',
        action: 'yabai -m window --focus west',
        description: 'Focus window to the west',
        category: ShortcutCategory.focus,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - j',
        action: 'yabai -m window --focus south',
        description: 'Focus window to the south',
        category: ShortcutCategory.focus,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - k',
        action: 'yabai -m window --focus north',
        description: 'Focus window to the north',
        category: ShortcutCategory.focus,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - l',
        action: 'yabai -m window --focus east',
        description: 'Focus window to the east',
        category: ShortcutCategory.focus,
      ),
      // Swap with shift + alt + hjkl
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'shift + alt - h',
        action: 'yabai -m window --swap west',
        description: 'Swap with window to the west',
        category: ShortcutCategory.move,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'shift + alt - j',
        action: 'yabai -m window --swap south',
        description: 'Swap with window to the south',
        category: ShortcutCategory.move,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'shift + alt - k',
        action: 'yabai -m window --swap north',
        description: 'Swap with window to the north',
        category: ShortcutCategory.move,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'shift + alt - l',
        action: 'yabai -m window --swap east',
        description: 'Swap with window to the east',
        category: ShortcutCategory.move,
      ),
      // Resize with ctrl + alt + hjkl
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'ctrl + alt - h',
        action: 'yabai -m window --resize left:-20:0',
        description: 'Resize left edge inward',
        category: ShortcutCategory.resize,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'ctrl + alt - j',
        action: 'yabai -m window --resize bottom:0:20',
        description: 'Resize bottom edge outward',
        category: ShortcutCategory.resize,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'ctrl + alt - k',
        action: 'yabai -m window --resize top:0:-20',
        description: 'Resize top edge inward',
        category: ShortcutCategory.resize,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'ctrl + alt - l',
        action: 'yabai -m window --resize right:20:0',
        description: 'Resize right edge outward',
        category: ShortcutCategory.resize,
      ),
      // Space focus with alt + 1-9
      for (int i = 1; i <= 9; i++)
        KeyboardShortcut(
          id: nextId(),
          keyCombo: 'alt - $i',
          action: 'yabai -m space --focus $i',
          description: 'Focus space $i',
          category: ShortcutCategory.spaces,
        ),
      // Move to space with shift + alt + 1-9
      for (int i = 1; i <= 9; i++)
        KeyboardShortcut(
          id: nextId(),
          keyCombo: 'shift + alt - $i',
          action: 'yabai -m window --space $i',
          description: 'Move window to space $i',
          category: ShortcutCategory.spaces,
        ),
      // Layout toggles
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - e',
        action: 'yabai -m space --layout bsp',
        description: 'Set BSP layout',
        category: ShortcutCategory.layout,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - s',
        action: 'yabai -m space --layout stack',
        description: 'Set Stack layout',
        category: ShortcutCategory.layout,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - f',
        action: 'yabai -m window --toggle zoom-fullscreen',
        description: 'Toggle fullscreen zoom',
        category: ShortcutCategory.layout,
      ),
      KeyboardShortcut(
        id: nextId(),
        keyCombo: 'alt - t',
        action: 'yabai -m window --toggle float',
        description: 'Toggle window float',
        category: ShortcutCategory.layout,
      ),
    ];
  }
}
