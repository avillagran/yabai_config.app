import 'dart:io';

/// Yabai layout modes for window tiling
class YabaiLayouts {
  YabaiLayouts._();

  static const String bsp = 'bsp';
  static const String float = 'float';
  static const String stack = 'stack';

  static const List<String> all = [bsp, float, stack];

  /// Human-readable names for layouts
  static const Map<String, String> displayNames = {
    bsp: 'Binary Space Partition',
    float: 'Floating',
    stack: 'Stack',
  };

  /// Descriptions for each layout
  static const Map<String, String> descriptions = {
    bsp: 'Windows are automatically tiled in a binary tree structure',
    float: 'Windows can be freely positioned and resized',
    stack: 'Windows are stacked on top of each other',
  };
}

/// Yabai window/space events that can trigger actions
class YabaiEvents {
  YabaiEvents._();

  // Application events
  static const String applicationLaunched = 'application_launched';
  static const String applicationTerminated = 'application_terminated';
  static const String applicationFrontSwitched = 'application_front_switched';
  static const String applicationActivated = 'application_activated';
  static const String applicationDeactivated = 'application_deactivated';
  static const String applicationVisible = 'application_visible';
  static const String applicationHidden = 'application_hidden';

  // Window events
  static const String windowCreated = 'window_created';
  static const String windowDestroyed = 'window_destroyed';
  static const String windowFocused = 'window_focused';
  static const String windowMoved = 'window_moved';
  static const String windowResized = 'window_resized';
  static const String windowMinimized = 'window_minimized';
  static const String windowDeminimized = 'window_deminimized';
  static const String windowTitleChanged = 'window_title_changed';

  // Space events
  static const String spaceCreated = 'space_created';
  static const String spaceDestroyed = 'space_destroyed';
  static const String spaceChanged = 'space_changed';

  // Display events
  static const String displayAdded = 'display_added';
  static const String displayRemoved = 'display_removed';
  static const String displayMoved = 'display_moved';
  static const String displayResized = 'display_resized';
  static const String displayChanged = 'display_changed';

  // Mission control events
  static const String missionControlEnter = 'mission_control_enter';
  static const String missionControlExit = 'mission_control_exit';

  // Dock events
  static const String dockDidChangePref = 'dock_did_change_pref';
  static const String dockDidRestart = 'dock_did_restart';

  // Menu bar events
  static const String menuBarHiddenChanged = 'menu_bar_hidden_changed';

  // System events
  static const String systemWoke = 'system_woke';

  static const List<String> all = [
    // Application events
    applicationLaunched,
    applicationTerminated,
    applicationFrontSwitched,
    applicationActivated,
    applicationDeactivated,
    applicationVisible,
    applicationHidden,
    // Window events
    windowCreated,
    windowDestroyed,
    windowFocused,
    windowMoved,
    windowResized,
    windowMinimized,
    windowDeminimized,
    windowTitleChanged,
    // Space events
    spaceCreated,
    spaceDestroyed,
    spaceChanged,
    // Display events
    displayAdded,
    displayRemoved,
    displayMoved,
    displayResized,
    displayChanged,
    // Mission control events
    missionControlEnter,
    missionControlExit,
    // Dock events
    dockDidChangePref,
    dockDidRestart,
    // Menu bar events
    menuBarHiddenChanged,
    // System events
    systemWoke,
  ];

  /// Grouped events by category
  static const Map<String, List<String>> byCategory = {
    'Application': [
      applicationLaunched,
      applicationTerminated,
      applicationFrontSwitched,
      applicationActivated,
      applicationDeactivated,
      applicationVisible,
      applicationHidden,
    ],
    'Window': [
      windowCreated,
      windowDestroyed,
      windowFocused,
      windowMoved,
      windowResized,
      windowMinimized,
      windowDeminimized,
      windowTitleChanged,
    ],
    'Space': [
      spaceCreated,
      spaceDestroyed,
      spaceChanged,
    ],
    'Display': [
      displayAdded,
      displayRemoved,
      displayMoved,
      displayResized,
      displayChanged,
    ],
    'Mission Control': [
      missionControlEnter,
      missionControlExit,
    ],
    'Dock': [
      dockDidChangePref,
      dockDidRestart,
    ],
    'Menu Bar': [
      menuBarHiddenChanged,
    ],
    'System': [
      systemWoke,
    ],
  };

  /// Human-readable names for events
  static String displayName(String event) {
    return event
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Common yabai action commands
class YabaiActions {
  YabaiActions._();

  // Focus window
  static const String focusWest = 'yabai -m window --focus west';
  static const String focusEast = 'yabai -m window --focus east';
  static const String focusNorth = 'yabai -m window --focus north';
  static const String focusSouth = 'yabai -m window --focus south';
  static const String focusRecent = 'yabai -m window --focus recent';

  // Swap window
  static const String swapWest = 'yabai -m window --swap west';
  static const String swapEast = 'yabai -m window --swap east';
  static const String swapNorth = 'yabai -m window --swap north';
  static const String swapSouth = 'yabai -m window --swap south';
  static const String swapRecent = 'yabai -m window --swap recent';

  // Warp window
  static const String warpWest = 'yabai -m window --warp west';
  static const String warpEast = 'yabai -m window --warp east';
  static const String warpNorth = 'yabai -m window --warp north';
  static const String warpSouth = 'yabai -m window --warp south';

  // Window toggles
  static const String toggleFloat = 'yabai -m window --toggle float';
  static const String toggleFullscreen = 'yabai -m window --toggle zoom-fullscreen';
  static const String toggleZoomParent = 'yabai -m window --toggle zoom-parent';
  static const String toggleSplit = 'yabai -m window --toggle split';
  static const String toggleBorder = 'yabai -m window --toggle border';
  static const String toggleShadow = 'yabai -m window --toggle shadow';
  static const String toggleSticky = 'yabai -m window --toggle sticky';
  static const String toggleTopmost = 'yabai -m window --toggle topmost';
  static const String togglePip = 'yabai -m window --toggle pip';

  // Window sizing
  static const String balanceWindows = 'yabai -m space --balance';
  static const String rotateClockwise = 'yabai -m space --rotate 90';
  static const String rotateCounterClockwise = 'yabai -m space --rotate 270';
  static const String flipX = 'yabai -m space --mirror x-axis';
  static const String flipY = 'yabai -m space --mirror y-axis';

  // Space management
  static const String createSpace = 'yabai -m space --create';
  static const String destroySpace = 'yabai -m space --destroy';
  static const String focusPrevSpace = 'yabai -m space --focus prev';
  static const String focusNextSpace = 'yabai -m space --focus next';
  static const String focusRecentSpace = 'yabai -m space --focus recent';

  // Display management
  static const String focusPrevDisplay = 'yabai -m display --focus prev';
  static const String focusNextDisplay = 'yabai -m display --focus next';
  static const String focusRecentDisplay = 'yabai -m display --focus recent';

  // Query commands
  static const String queryWindows = 'yabai -m query --windows';
  static const String querySpaces = 'yabai -m query --spaces';
  static const String queryDisplays = 'yabai -m query --displays';

  // Service commands
  static const String startService = 'yabai --start-service';
  static const String stopService = 'yabai --stop-service';
  static const String restartService = 'yabai --restart-service';

  /// All common actions grouped by category
  static const Map<String, List<String>> byCategory = {
    'Focus Window': [focusWest, focusEast, focusNorth, focusSouth, focusRecent],
    'Swap Window': [swapWest, swapEast, swapNorth, swapSouth, swapRecent],
    'Warp Window': [warpWest, warpEast, warpNorth, warpSouth],
    'Window Toggles': [
      toggleFloat,
      toggleFullscreen,
      toggleZoomParent,
      toggleSplit,
      toggleBorder,
      toggleShadow,
      toggleSticky,
      toggleTopmost,
      togglePip,
    ],
    'Space Layout': [
      balanceWindows,
      rotateClockwise,
      rotateCounterClockwise,
      flipX,
      flipY,
    ],
    'Space Management': [
      createSpace,
      destroySpace,
      focusPrevSpace,
      focusNextSpace,
      focusRecentSpace,
    ],
    'Display': [focusPrevDisplay, focusNextDisplay, focusRecentDisplay],
  };
}

/// SKHD modifier keys
class SkhdModifiers {
  SkhdModifiers._();

  static const String alt = 'alt';
  static const String shift = 'shift';
  static const String ctrl = 'ctrl';
  static const String cmd = 'cmd';
  static const String fn = 'fn';
  static const String hyper = 'hyper'; // cmd + alt + ctrl + shift

  static const List<String> all = [alt, shift, ctrl, cmd, fn, hyper];

  /// Display symbols for modifiers (macOS style)
  static const Map<String, String> symbols = {
    alt: '\u2325', // Option symbol
    shift: '\u21E7', // Shift symbol
    ctrl: '\u2303', // Control symbol
    cmd: '\u2318', // Command symbol
    fn: 'fn',
    hyper: '\u2303\u2325\u21E7\u2318', // All modifier symbols
  };

  /// Human-readable names
  static const Map<String, String> displayNames = {
    alt: 'Option',
    shift: 'Shift',
    ctrl: 'Control',
    cmd: 'Command',
    fn: 'Function',
    hyper: 'Hyper',
  };
}

/// Common key codes for SKHD
class SkhdKeys {
  SkhdKeys._();

  // Arrow keys
  static const String left = 'left';
  static const String right = 'right';
  static const String up = 'up';
  static const String down = 'down';

  // Function keys
  static const String f1 = 'f1';
  static const String f2 = 'f2';
  static const String f3 = 'f3';
  static const String f4 = 'f4';
  static const String f5 = 'f5';
  static const String f6 = 'f6';
  static const String f7 = 'f7';
  static const String f8 = 'f8';
  static const String f9 = 'f9';
  static const String f10 = 'f10';
  static const String f11 = 'f11';
  static const String f12 = 'f12';

  // Special keys
  static const String space = 'space';
  static const String tab = 'tab';
  static const String escape = 'escape';
  static const String returnKey = 'return';
  static const String delete = 'delete';
  static const String forwardDelete = 'forwarddelete';
  static const String home = 'home';
  static const String end = 'end';
  static const String pageUp = 'pageup';
  static const String pageDown = 'pagedown';

  static const List<String> functionKeys = [
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
  ];

  static const List<String> specialKeys = [
    space,
    tab,
    escape,
    returnKey,
    delete,
    forwardDelete,
    home,
    end,
    pageUp,
    pageDown,
    left,
    right,
    up,
    down,
  ];

  /// All letter keys
  static List<String> get letters =>
      List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i));

  /// All number keys
  static List<String> get numbers =>
      List.generate(10, (i) => String.fromCharCode('0'.codeUnitAt(0) + i));

  /// Display names for special keys
  static const Map<String, String> displayNames = {
    left: '\u2190', // Left arrow
    right: '\u2192', // Right arrow
    up: '\u2191', // Up arrow
    down: '\u2193', // Down arrow
    space: 'Space',
    tab: '\u21E5', // Tab symbol
    escape: '\u238B', // Escape symbol
    returnKey: '\u23CE', // Return symbol
    delete: '\u232B', // Delete symbol
    forwardDelete: '\u2326', // Forward delete symbol
    home: 'Home',
    end: 'End',
    pageUp: 'Page Up',
    pageDown: 'Page Down',
  };
}

/// Application paths and directories
class AppPaths {
  AppPaths._();

  /// User's home directory
  static String get homeDir => Platform.environment['HOME'] ?? '/Users';

  /// Yabai configuration file path
  static String get yabairc => '$homeDir/.yabairc';

  /// SKHD configuration file path
  static String get skhdrc => '$homeDir/.skhdrc';

  /// Yabai config directory
  static String get yabaiConfigDir => '$homeDir/.config/yabai';

  /// SKHD config directory
  static String get skhdConfigDir => '$homeDir/.config/skhd';

  /// Backup directory for configurations
  static String get backupDir => '$homeDir/.config/yabai-config-app/backups';

  /// App preferences directory
  static String get prefsDir => '$homeDir/.config/yabai-config-app';

  /// Check if yabairc exists
  static bool get yabaiConfigExists => File(yabairc).existsSync();

  /// Check if skhdrc exists
  static bool get skhdConfigExists => File(skhdrc).existsSync();
}

/// Default values for Yabai configuration
class YabaiDefaults {
  YabaiDefaults._();

  // Layout defaults
  static const String layout = YabaiLayouts.bsp;
  static const int paddingTop = 10;
  static const int paddingBottom = 10;
  static const int paddingLeft = 10;
  static const int paddingRight = 10;
  static const int windowGap = 10;

  // Window defaults
  static const bool windowShadow = true;
  static const double windowOpacity = 1.0;
  static const bool windowBorder = false;
  static const int windowBorderWidth = 4;
  static const int activeWindowBorderColor = 0xff775759;
  static const int normalWindowBorderColor = 0xff555555;

  // Mouse defaults
  static const String mouseFollowsFocus = 'off';
  static const String focusFollowsMouse = 'off';
  static const String mouseModifier = 'fn';
  static const String mouseAction1 = 'move';
  static const String mouseAction2 = 'resize';
  static const String mouseDropAction = 'swap';

  // Split defaults
  static const double splitRatio = 0.5;
  static const String splitType = 'auto';
  static const bool autoBalance = false;

  // Insert feedback
  static const int insertFeedbackColor = 0xffd75f5f;
}
