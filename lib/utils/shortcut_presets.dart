import '../models/shortcut.dart';
import 'yabai_commands.dart';

/// Preset shortcut configurations for common workflows.
///
/// Provides ready-to-use shortcut sets that users can import.
class ShortcutPresets {
  ShortcutPresets._();

  /// Vim-style navigation shortcuts using hjkl
  ///
  /// Focus: alt + hjkl
  /// Swap: alt + shift + hjkl
  /// Warp: alt + ctrl + hjkl
  /// Resize: alt + cmd + hjkl
  static List<Shortcut> get vimStyle => [
    // Focus windows with alt + hjkl
    Shortcut(
      modifiers: const ['alt'],
      key: 'h',
      action: YabaiCommands.focus('west'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the west',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'j',
      action: YabaiCommands.focus('south'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the south',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'k',
      action: YabaiCommands.focus('north'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the north',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'l',
      action: YabaiCommands.focus('east'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the east',
    ),

    // Swap windows with alt + shift + hjkl
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'h',
      action: YabaiCommands.swap('west'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the west',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'j',
      action: YabaiCommands.swap('south'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the south',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'k',
      action: YabaiCommands.swap('north'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the north',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'l',
      action: YabaiCommands.swap('east'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the east',
    ),

    // Warp windows with alt + ctrl + hjkl
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'h',
      action: YabaiCommands.warp('west'),
      category: ShortcutCategory.warp,
      description: 'Warp to the west',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'j',
      action: YabaiCommands.warp('south'),
      category: ShortcutCategory.warp,
      description: 'Warp to the south',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'k',
      action: YabaiCommands.warp('north'),
      category: ShortcutCategory.warp,
      description: 'Warp to the north',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'l',
      action: YabaiCommands.warp('east'),
      category: ShortcutCategory.warp,
      description: 'Warp to the east',
    ),

    // Resize windows with alt + cmd + hjkl
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'h',
      action: YabaiCommands.resize('left', -50, 0),
      category: ShortcutCategory.resize,
      description: 'Shrink from left edge',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'j',
      action: YabaiCommands.resize('bottom', 0, 50),
      category: ShortcutCategory.resize,
      description: 'Grow from bottom edge',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'k',
      action: YabaiCommands.resize('top', 0, -50),
      category: ShortcutCategory.resize,
      description: 'Shrink from top edge',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'l',
      action: YabaiCommands.resize('right', 50, 0),
      category: ShortcutCategory.resize,
      description: 'Grow from right edge',
    ),

    // Space navigation with alt + number
    ...List.generate(
      9,
      (i) => Shortcut(
        modifiers: const ['alt'],
        key: '${i + 1}',
        action: YabaiCommands.focusSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Focus space ${i + 1}',
      ),
    ),

    // Move window to space with alt + shift + number
    ...List.generate(
      9,
      (i) => Shortcut(
        modifiers: const ['alt', 'shift'],
        key: '${i + 1}',
        action: YabaiCommands.moveToSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Move window to space ${i + 1}',
      ),
    ),

    // Toggle shortcuts
    Shortcut(
      modifiers: const ['alt'],
      key: 'f',
      action: YabaiCommands.toggleFullscreen(),
      category: ShortcutCategory.toggle,
      description: 'Toggle fullscreen zoom',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'f',
      action: YabaiCommands.toggleFloat(),
      category: ShortcutCategory.toggle,
      description: 'Toggle float',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 's',
      action: YabaiCommands.toggleSplit(),
      category: ShortcutCategory.toggle,
      description: 'Toggle split orientation',
    ),

    // Layout shortcuts
    Shortcut(
      modifiers: const ['alt'],
      key: 'e',
      action: YabaiCommands.balanceSpace(),
      category: ShortcutCategory.layout,
      description: 'Balance windows',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'r',
      action: YabaiCommands.rotateSpace(90),
      category: ShortcutCategory.layout,
      description: 'Rotate layout 90 degrees',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'r',
      action: YabaiCommands.rotateSpace(270),
      category: ShortcutCategory.layout,
      description: 'Rotate layout -90 degrees',
    ),

    // Display navigation
    Shortcut(
      modifiers: const ['alt'],
      key: 'p',
      action: YabaiCommands.focusPrevDisplay(),
      category: ShortcutCategory.display,
      description: 'Focus previous display',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'n',
      action: YabaiCommands.focusNextDisplay(),
      category: ShortcutCategory.display,
      description: 'Focus next display',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'p',
      action: YabaiCommands.moveToPrevDisplay(),
      category: ShortcutCategory.display,
      description: 'Move window to previous display',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'n',
      action: YabaiCommands.moveToNextDisplay(),
      category: ShortcutCategory.display,
      description: 'Move window to next display',
    ),
  ];

  /// Arrow key navigation (more intuitive for non-vim users)
  ///
  /// Focus: alt + arrows
  /// Swap: alt + shift + arrows
  /// Resize: alt + cmd + arrows
  static List<Shortcut> get arrowStyle => [
    // Focus with alt + arrows
    Shortcut(
      modifiers: const ['alt'],
      key: 'left',
      action: YabaiCommands.focus('west'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the left',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'down',
      action: YabaiCommands.focus('south'),
      category: ShortcutCategory.focus,
      description: 'Focus window below',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'up',
      action: YabaiCommands.focus('north'),
      category: ShortcutCategory.focus,
      description: 'Focus window above',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'right',
      action: YabaiCommands.focus('east'),
      category: ShortcutCategory.focus,
      description: 'Focus window to the right',
    ),

    // Swap with alt + shift + arrows
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'left',
      action: YabaiCommands.swap('west'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the left',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'down',
      action: YabaiCommands.swap('south'),
      category: ShortcutCategory.swap,
      description: 'Swap with window below',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'up',
      action: YabaiCommands.swap('north'),
      category: ShortcutCategory.swap,
      description: 'Swap with window above',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'right',
      action: YabaiCommands.swap('east'),
      category: ShortcutCategory.swap,
      description: 'Swap with window to the right',
    ),

    // Resize with alt + cmd + arrows
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'left',
      action: YabaiCommands.resize('right', -50, 0),
      category: ShortcutCategory.resize,
      description: 'Shrink window width',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'down',
      action: YabaiCommands.resize('bottom', 0, 50),
      category: ShortcutCategory.resize,
      description: 'Grow window height',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'up',
      action: YabaiCommands.resize('bottom', 0, -50),
      category: ShortcutCategory.resize,
      description: 'Shrink window height',
    ),
    Shortcut(
      modifiers: const ['alt', 'cmd'],
      key: 'right',
      action: YabaiCommands.resize('right', 50, 0),
      category: ShortcutCategory.resize,
      description: 'Grow window width',
    ),

    // Space navigation with ctrl + number
    ...List.generate(
      9,
      (i) => Shortcut(
        modifiers: const ['ctrl'],
        key: '${i + 1}',
        action: YabaiCommands.focusSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Focus space ${i + 1}',
      ),
    ),

    // Move to space with ctrl + shift + number
    ...List.generate(
      9,
      (i) => Shortcut(
        modifiers: const ['ctrl', 'shift'],
        key: '${i + 1}',
        action: YabaiCommands.moveToSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Move window to space ${i + 1}',
      ),
    ),

    // Toggles
    Shortcut(
      modifiers: const ['alt'],
      key: 'return',
      action: YabaiCommands.toggleFullscreen(),
      category: ShortcutCategory.toggle,
      description: 'Toggle fullscreen',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'space',
      action: YabaiCommands.toggleFloat(),
      category: ShortcutCategory.toggle,
      description: 'Toggle float',
    ),
  ];

  /// Minimal set of essential shortcuts
  static List<Shortcut> get minimal => [
    // Basic focus
    Shortcut(
      modifiers: const ['alt'],
      key: 'h',
      action: YabaiCommands.focus('west'),
      category: ShortcutCategory.focus,
      description: 'Focus left',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'l',
      action: YabaiCommands.focus('east'),
      category: ShortcutCategory.focus,
      description: 'Focus right',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'j',
      action: YabaiCommands.focus('south'),
      category: ShortcutCategory.focus,
      description: 'Focus down',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'k',
      action: YabaiCommands.focus('north'),
      category: ShortcutCategory.focus,
      description: 'Focus up',
    ),

    // Basic toggles
    Shortcut(
      modifiers: const ['alt'],
      key: 'f',
      action: YabaiCommands.toggleFullscreen(),
      category: ShortcutCategory.toggle,
      description: 'Toggle fullscreen',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'f',
      action: YabaiCommands.toggleFloat(),
      category: ShortcutCategory.toggle,
      description: 'Toggle float',
    ),

    // Space navigation (1-5)
    ...List.generate(
      5,
      (i) => Shortcut(
        modifiers: const ['alt'],
        key: '${i + 1}',
        action: YabaiCommands.focusSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Focus space ${i + 1}',
      ),
    ),
  ];

  /// i3-like keyboard shortcuts
  static List<Shortcut> get i3Style => [
    // Focus with $mod (alt) + jkl;
    Shortcut(
      modifiers: const ['alt'],
      key: 'j',
      action: YabaiCommands.focus('west'),
      category: ShortcutCategory.focus,
      description: 'Focus left',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'k',
      action: YabaiCommands.focus('south'),
      category: ShortcutCategory.focus,
      description: 'Focus down',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'l',
      action: YabaiCommands.focus('north'),
      category: ShortcutCategory.focus,
      description: 'Focus up',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: ';',
      action: YabaiCommands.focus('east'),
      category: ShortcutCategory.focus,
      description: 'Focus right',
    ),

    // Move with $mod + shift + jkl;
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'j',
      action: YabaiCommands.swap('west'),
      category: ShortcutCategory.swap,
      description: 'Move left',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'k',
      action: YabaiCommands.swap('south'),
      category: ShortcutCategory.swap,
      description: 'Move down',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'l',
      action: YabaiCommands.swap('north'),
      category: ShortcutCategory.swap,
      description: 'Move up',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: ';',
      action: YabaiCommands.swap('east'),
      category: ShortcutCategory.swap,
      description: 'Move right',
    ),

    // Workspaces 1-10
    ...List.generate(
      10,
      (i) => Shortcut(
        modifiers: const ['alt'],
        key: i == 9 ? '0' : '${i + 1}',
        action: YabaiCommands.focusSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Focus workspace ${i + 1}',
      ),
    ),

    // Move to workspaces
    ...List.generate(
      10,
      (i) => Shortcut(
        modifiers: const ['alt', 'shift'],
        key: i == 9 ? '0' : '${i + 1}',
        action: YabaiCommands.moveToSpace(i + 1),
        category: ShortcutCategory.space,
        description: 'Move to workspace ${i + 1}',
      ),
    ),

    // Layout modes
    Shortcut(
      modifiers: const ['alt'],
      key: 'e',
      action: YabaiCommands.setLayout('bsp'),
      category: ShortcutCategory.layout,
      description: 'BSP layout (tiling)',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 's',
      action: YabaiCommands.setLayout('stack'),
      category: ShortcutCategory.layout,
      description: 'Stack layout (tabbed)',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'w',
      action: YabaiCommands.setLayout('float'),
      category: ShortcutCategory.layout,
      description: 'Floating layout',
    ),

    // Fullscreen
    Shortcut(
      modifiers: const ['alt'],
      key: 'f',
      action: YabaiCommands.toggleFullscreen(),
      category: ShortcutCategory.toggle,
      description: 'Toggle fullscreen',
    ),

    // Toggle floating
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'space',
      action: YabaiCommands.toggleFloat(),
      category: ShortcutCategory.toggle,
      description: 'Toggle floating',
    ),

    // Split orientation
    Shortcut(
      modifiers: const ['alt'],
      key: 'v',
      action: YabaiCommands.toggleSplit(),
      category: ShortcutCategory.toggle,
      description: 'Toggle split orientation',
    ),

    // Resize mode alternatives
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'j',
      action: YabaiCommands.resize('left', -50, 0),
      category: ShortcutCategory.resize,
      description: 'Shrink width',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'k',
      action: YabaiCommands.resize('bottom', 0, 50),
      category: ShortcutCategory.resize,
      description: 'Grow height',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'l',
      action: YabaiCommands.resize('bottom', 0, -50),
      category: ShortcutCategory.resize,
      description: 'Shrink height',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: ';',
      action: YabaiCommands.resize('right', 50, 0),
      category: ShortcutCategory.resize,
      description: 'Grow width',
    ),
  ];

  /// Stack-focused shortcuts for managing stacked windows
  static List<Shortcut> get stackFocused => [
    // Stack navigation
    Shortcut(
      modifiers: const ['alt'],
      key: 'n',
      action: YabaiCommands.focusStackNext(),
      category: ShortcutCategory.stack,
      description: 'Focus next in stack',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: 'p',
      action: YabaiCommands.focusStackPrev(),
      category: ShortcutCategory.stack,
      description: 'Focus previous in stack',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: '[',
      action: YabaiCommands.focusStackFirst(),
      category: ShortcutCategory.stack,
      description: 'Focus first in stack',
    ),
    Shortcut(
      modifiers: const ['alt'],
      key: ']',
      action: YabaiCommands.focusStackLast(),
      category: ShortcutCategory.stack,
      description: 'Focus last in stack',
    ),

    // Stack windows
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'h',
      action: YabaiCommands.stack('west'),
      category: ShortcutCategory.stack,
      description: 'Stack with west window',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'j',
      action: YabaiCommands.stack('south'),
      category: ShortcutCategory.stack,
      description: 'Stack with south window',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'k',
      action: YabaiCommands.stack('north'),
      category: ShortcutCategory.stack,
      description: 'Stack with north window',
    ),
    Shortcut(
      modifiers: const ['alt', 'shift'],
      key: 'l',
      action: YabaiCommands.stack('east'),
      category: ShortcutCategory.stack,
      description: 'Stack with east window',
    ),

    // Unstack (warp out)
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'h',
      action: YabaiCommands.warp('west'),
      category: ShortcutCategory.warp,
      description: 'Warp west (unstack)',
    ),
    Shortcut(
      modifiers: const ['alt', 'ctrl'],
      key: 'l',
      action: YabaiCommands.warp('east'),
      category: ShortcutCategory.warp,
      description: 'Warp east (unstack)',
    ),
  ];

  /// Get all available presets with metadata
  static Map<String, PresetInfo> get all => {
        'vimStyle': PresetInfo(
          name: 'Vim Style',
          description:
              'Vim-inspired navigation using hjkl keys with various modifiers',
          shortcuts: vimStyle,
          icon: 'keyboard',
        ),
        'arrowStyle': PresetInfo(
          name: 'Arrow Keys',
          description:
              'Intuitive navigation using arrow keys, great for beginners',
          shortcuts: arrowStyle,
          icon: 'arrow_forward',
        ),
        'minimal': PresetInfo(
          name: 'Minimal',
          description: 'Essential shortcuts only, less to remember',
          shortcuts: minimal,
          icon: 'minimize',
        ),
        'i3Style': PresetInfo(
          name: 'i3 Style',
          description:
              'Keyboard shortcuts inspired by the i3 window manager',
          shortcuts: i3Style,
          icon: 'grid_view',
        ),
        'stackFocused': PresetInfo(
          name: 'Stack Focused',
          description:
              'Shortcuts optimized for managing stacked/tabbed windows',
          shortcuts: stackFocused,
          icon: 'layers',
        ),
      };
}

/// Metadata about a shortcut preset
class PresetInfo {
  final String name;
  final String description;
  final List<Shortcut> shortcuts;
  final String icon;

  const PresetInfo({
    required this.name,
    required this.description,
    required this.shortcuts,
    required this.icon,
  });

  /// Get shortcuts grouped by category
  Map<String, List<Shortcut>> get byCategory {
    final result = <String, List<Shortcut>>{};
    for (final shortcut in shortcuts) {
      final category = shortcut.category ?? ShortcutCategory.custom;
      result.putIfAbsent(category, () => []).add(shortcut);
    }
    return result;
  }

  /// Get count of shortcuts
  int get count => shortcuts.length;
}
