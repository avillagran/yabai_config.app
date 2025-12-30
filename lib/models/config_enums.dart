/// Layout types supported by Yabai
enum YabaiLayout {
  bsp('bsp', 'Binary Space Partition', 'Automatically tiles windows in a binary tree structure'),
  float('float', 'Floating', 'Windows float freely and can be moved/resized manually'),
  stack('stack', 'Stacking', 'Windows stack on top of each other');

  final String value;
  final String displayName;
  final String description;

  const YabaiLayout(this.value, this.displayName, this.description);

  static YabaiLayout fromString(String? value) {
    if (value == null) return YabaiLayout.bsp;
    return YabaiLayout.values.firstWhere(
      (l) => l.value == value,
      orElse: () => YabaiLayout.bsp,
    );
  }
}

/// Window placement options
enum WindowPlacement {
  firstChild('first_child', 'First Child'),
  secondChild('second_child', 'Second Child');

  final String value;
  final String displayName;

  const WindowPlacement(this.value, this.displayName);

  static WindowPlacement fromString(String? value) {
    if (value == null) return WindowPlacement.secondChild;
    return WindowPlacement.values.firstWhere(
      (p) => p.value == value,
      orElse: () => WindowPlacement.secondChild,
    );
  }
}

/// Mouse modifier keys
enum MouseModifier {
  alt('alt', 'Option (Alt)'),
  cmd('cmd', 'Command'),
  ctrl('ctrl', 'Control'),
  shift('shift', 'Shift');

  final String value;
  final String displayName;

  const MouseModifier(this.value, this.displayName);

  static MouseModifier fromString(String? value) {
    if (value == null) return MouseModifier.alt;
    return MouseModifier.values.firstWhere(
      (m) => m.value == value,
      orElse: () => MouseModifier.alt,
    );
  }
}

/// Mouse actions
enum MouseAction {
  move('move', 'Move Window'),
  resize('resize', 'Resize Window');

  final String value;
  final String displayName;

  const MouseAction(this.value, this.displayName);

  static MouseAction fromString(String? value) {
    if (value == null) return MouseAction.move;
    return MouseAction.values.firstWhere(
      (a) => a.value == value,
      orElse: () => MouseAction.move,
    );
  }
}

/// Mouse drop actions
enum MouseDropAction {
  swap('swap', 'Swap Windows'),
  stack('stack', 'Stack Windows');

  final String value;
  final String displayName;

  const MouseDropAction(this.value, this.displayName);

  static MouseDropAction fromString(String? value) {
    if (value == null) return MouseDropAction.swap;
    return MouseDropAction.values.firstWhere(
      (a) => a.value == value,
      orElse: () => MouseDropAction.swap,
    );
  }
}
