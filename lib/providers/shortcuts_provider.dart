import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/keyboard_shortcut.dart';
import '../models/skhd_config.dart' hide ShortcutCategory;

/// State notifier for managing keyboard shortcuts
class ShortcutsNotifier extends StateNotifier<List<KeyboardShortcut>> {
  ShortcutsNotifier() : super([]) {
    _loadShortcuts();
  }

  /// Load shortcuts directly from ~/.skhdrc file
  Future<void> _loadShortcuts() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final skhdrc = File('$home/.skhdrc');

      if (!await skhdrc.exists()) {
        state = [];
        return;
      }

      final content = await skhdrc.readAsString();
      final config = SkhdConfig.fromSkhdrc(content);

      // Convert Shortcut to KeyboardShortcut
      state = config.shortcuts.map((s) => KeyboardShortcut(
        id: s.id,
        keyCombo: s.toSkhdHotkey(),
        action: s.action,
        description: s.description ?? _inferDescription(s.action),
        category: _mapCategory(s.category),
        isEnabled: s.enabled,
      )).toList();
    } catch (e) {
      state = [];
    }
  }

  /// Infer description from yabai action
  String _inferDescription(String action) {
    // Try to match common yabai commands
    if (action.contains('--focus west')) return 'Focus window to the west';
    if (action.contains('--focus east')) return 'Focus window to the east';
    if (action.contains('--focus north')) return 'Focus window to the north';
    if (action.contains('--focus south')) return 'Focus window to the south';
    if (action.contains('--swap west')) return 'Swap with window to the west';
    if (action.contains('--swap east')) return 'Swap with window to the east';
    if (action.contains('--swap north')) return 'Swap with window to the north';
    if (action.contains('--swap south')) return 'Swap with window to the south';
    if (action.contains('--toggle float')) return 'Toggle window float';
    if (action.contains('--toggle zoom-fullscreen')) return 'Toggle fullscreen';
    if (action.contains('--layout bsp')) return 'Set BSP layout';
    if (action.contains('--layout stack')) return 'Set stack layout';
    if (action.contains('--layout float')) return 'Set float layout';
    if (action.contains('space --focus')) {
      final match = RegExp(r'space --focus (\d+)').firstMatch(action);
      if (match != null) return 'Focus space ${match.group(1)}';
      return 'Focus space';
    }
    if (action.contains('window --space')) {
      final match = RegExp(r'window --space (\d+)').firstMatch(action);
      if (match != null) return 'Move to space ${match.group(1)}';
      return 'Move to space';
    }
    return action;
  }

  /// Map skhd category string to ShortcutCategory enum
  ShortcutCategory _mapCategory(String? category) {
    if (category == null) return ShortcutCategory.custom;
    switch (category.toLowerCase()) {
      case 'focus':
        return ShortcutCategory.focus;
      case 'move':
        return ShortcutCategory.move;
      case 'resize':
        return ShortcutCategory.resize;
      case 'layout':
        return ShortcutCategory.layout;
      case 'space':
      case 'spaces':
        return ShortcutCategory.spaces;
      default:
        return ShortcutCategory.custom;
    }
  }

  void addShortcut(KeyboardShortcut shortcut) {
    // Auto-detect category if set to custom
    final finalShortcut = shortcut.category == ShortcutCategory.custom
        ? shortcut.copyWith(
            category: KeyboardShortcut.detectCategoryFromAction(shortcut.action))
        : shortcut;
    state = [...state, finalShortcut];
    _saveToFile();
  }

  void updateShortcut(KeyboardShortcut shortcut) {
    // Re-detect category based on updated action
    final detectedCategory = KeyboardShortcut.detectCategoryFromAction(shortcut.action);
    final finalShortcut = shortcut.copyWith(category: detectedCategory);

    state = [
      for (final s in state)
        if (s.id == finalShortcut.id) finalShortcut else s
    ];
    _saveToFile();
  }

  void deleteShortcut(String id) {
    state = state.where((shortcut) => shortcut.id != id).toList();
    _saveToFile();
  }

  void toggleShortcut(String id) {
    state = [
      for (final shortcut in state)
        if (shortcut.id == id)
          shortcut.copyWith(isEnabled: !shortcut.isEnabled)
        else
          shortcut
    ];
    _saveToFile();
  }

  /// Save shortcuts to ~/.skhdrc file and reload skhd
  Future<void> _saveToFile() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final skhdrc = File('$home/.skhdrc');
      final content = generateConfig();
      await skhdrc.writeAsString(content);
      // Reload skhd to apply changes
      await Process.run('skhd', ['--reload']);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load preset shortcuts (vim-style)
  void loadPreset() {
    final presets = PresetShortcuts.vimStylePreset;

    // Merge with existing, avoiding duplicates by keyCombo
    final existingKeyCombos = state.map((s) => s.keyCombo).toSet();
    final newShortcuts = presets
        .where((preset) => !existingKeyCombos.contains(preset.keyCombo))
        .toList();

    if (newShortcuts.isNotEmpty) {
      state = [...state, ...newShortcuts];
      _saveToFile();
    }
  }

  /// Replace all shortcuts with preset
  void replaceWithPreset() {
    state = PresetShortcuts.vimStylePreset;
    _saveToFile();
  }

  /// Clear all shortcuts
  void clearAll() {
    state = [];
    _saveToFile();
  }

  /// Refresh shortcuts from file
  Future<void> refresh() async {
    await _loadShortcuts();
  }

  /// Generate the complete skhd configuration
  String generateConfig() {
    final buffer = StringBuffer();
    buffer.writeln('# skhd Configuration');
    buffer.writeln('# Generated by Yabai Config');
    buffer.writeln();

    // Group by category
    final grouped = <ShortcutCategory, List<KeyboardShortcut>>{};
    for (final shortcut in state) {
      grouped.putIfAbsent(shortcut.category, () => []).add(shortcut);
    }

    for (final category in ShortcutCategory.values) {
      final shortcuts = grouped[category];
      if (shortcuts != null && shortcuts.isNotEmpty) {
        buffer.writeln('# ${category.displayName}');
        for (final shortcut in shortcuts) {
          buffer.writeln(shortcut.toSkhdConfig());
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Check for conflicting key combinations
  List<String> findConflicts() {
    final conflicts = <String>[];
    final keyCombos = <String, List<String>>{};

    for (final shortcut in state.where((s) => s.isEnabled)) {
      keyCombos.putIfAbsent(shortcut.keyCombo, () => []).add(shortcut.id);
    }

    for (final entry in keyCombos.entries) {
      if (entry.value.length > 1) {
        conflicts.add(entry.key);
      }
    }

    return conflicts;
  }
}

/// Provider for keyboard shortcuts
final shortcutsProvider =
    StateNotifierProvider<ShortcutsNotifier, List<KeyboardShortcut>>((ref) {
  return ShortcutsNotifier();
});

/// Provider for shortcuts grouped by category
final shortcutsByCategoryProvider =
    Provider<Map<ShortcutCategory, List<KeyboardShortcut>>>((ref) {
  final shortcuts = ref.watch(shortcutsProvider);
  final grouped = <ShortcutCategory, List<KeyboardShortcut>>{};

  for (final category in ShortcutCategory.values) {
    grouped[category] =
        shortcuts.where((s) => s.category == category).toList();
  }

  return grouped;
});

/// Provider for shortcuts count
final shortcutsCountProvider = Provider<int>((ref) {
  return ref.watch(shortcutsProvider).length;
});

/// Provider for enabled shortcuts count
final enabledShortcutsCountProvider = Provider<int>((ref) {
  final shortcuts = ref.watch(shortcutsProvider);
  return shortcuts.where((s) => s.isEnabled).length;
});

/// Provider for conflicting shortcuts
final shortcutConflictsProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(shortcutsProvider.notifier);
  return notifier.findConflicts();
});
