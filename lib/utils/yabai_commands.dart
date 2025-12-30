/// Helper class for building Yabai commands programmatically.
///
/// Provides type-safe methods for constructing yabai CLI commands.
class YabaiCommands {
  YabaiCommands._();

  // ==================== Window Focus ====================

  /// Focus window in the specified direction
  static String focus(String direction) =>
      'yabai -m window --focus $direction';

  /// Focus window by ID
  static String focusWindow(int windowId) =>
      'yabai -m window --focus $windowId';

  /// Focus the most recent window
  static String focusRecent() => 'yabai -m window --focus recent';

  /// Focus first window in stack
  static String focusStackFirst() =>
      'yabai -m window --focus stack.first';

  /// Focus last window in stack
  static String focusStackLast() =>
      'yabai -m window --focus stack.last';

  /// Focus next window in stack
  static String focusStackNext() =>
      'yabai -m window --focus stack.next';

  /// Focus previous window in stack
  static String focusStackPrev() =>
      'yabai -m window --focus stack.prev';

  // ==================== Window Swap ====================

  /// Swap window in the specified direction
  static String swap(String direction) =>
      'yabai -m window --swap $direction';

  /// Swap window with window by ID
  static String swapWith(int windowId) =>
      'yabai -m window --swap $windowId';

  /// Swap with recent window
  static String swapRecent() => 'yabai -m window --swap recent';

  // ==================== Window Warp ====================

  /// Warp window in the specified direction
  static String warp(String direction) =>
      'yabai -m window --warp $direction';

  /// Warp window to window by ID
  static String warpTo(int windowId) =>
      'yabai -m window --warp $windowId';

  // ==================== Window Stack ====================

  /// Stack window in the specified direction
  static String stack(String direction) =>
      'yabai -m window --stack $direction';

  /// Stack window with window by ID
  static String stackWith(int windowId) =>
      'yabai -m window --stack $windowId';

  // ==================== Window Resize ====================

  /// Resize window edge in a direction
  /// [side] is one of: left, right, top, bottom
  /// [dx] and [dy] are pixel offsets (can be negative)
  static String resize(String side, int dx, int dy) =>
      'yabai -m window --resize $side:$dx:$dy';

  /// Increase window size on an edge
  static String resizeGrow(String edge, int amount) {
    switch (edge) {
      case 'left':
        return resize('left', -amount, 0);
      case 'right':
        return resize('right', amount, 0);
      case 'top':
        return resize('top', 0, -amount);
      case 'bottom':
        return resize('bottom', 0, amount);
      default:
        throw ArgumentError('Invalid edge: $edge');
    }
  }

  /// Decrease window size on an edge
  static String resizeShrink(String edge, int amount) {
    switch (edge) {
      case 'left':
        return resize('left', amount, 0);
      case 'right':
        return resize('right', -amount, 0);
      case 'top':
        return resize('top', 0, amount);
      case 'bottom':
        return resize('bottom', 0, -amount);
      default:
        throw ArgumentError('Invalid edge: $edge');
    }
  }

  /// Resize window by ratio (for resize mode shortcuts)
  static String resizeByRatio(String side, double ratio) {
    final amount = (100 * ratio).round();
    return resize(side, amount, amount);
  }

  // ==================== Window Move ====================

  /// Move window by offset
  static String move(int dx, int dy) =>
      'yabai -m window --move rel:$dx:$dy';

  /// Move window to absolute position
  static String moveTo(int x, int y) =>
      'yabai -m window --move abs:$x:$y';

  // ==================== Window Toggles ====================

  /// Toggle window floating state
  static String toggleFloat() => 'yabai -m window --toggle float';

  /// Toggle window fullscreen zoom
  static String toggleFullscreen() =>
      'yabai -m window --toggle zoom-fullscreen';

  /// Toggle window parent zoom
  static String toggleZoomParent() =>
      'yabai -m window --toggle zoom-parent';

  /// Toggle window native fullscreen
  static String toggleNativeFullscreen() =>
      'yabai -m window --toggle native-fullscreen';

  /// Toggle window split orientation
  static String toggleSplit() => 'yabai -m window --toggle split';

  /// Toggle window border
  static String toggleBorder() => 'yabai -m window --toggle border';

  /// Toggle window shadow
  static String toggleShadow() => 'yabai -m window --toggle shadow';

  /// Toggle window sticky (visible on all spaces)
  static String toggleSticky() => 'yabai -m window --toggle sticky';

  /// Toggle window topmost (always on top)
  static String toggleTopmost() => 'yabai -m window --toggle topmost';

  /// Toggle picture-in-picture mode
  static String togglePip() => 'yabai -m window --toggle pip';

  /// Toggle window expose
  static String toggleExpose() => 'yabai -m window --toggle expose';

  // ==================== Window Properties ====================

  /// Set window opacity
  static String setOpacity(double opacity) =>
      'yabai -m window --opacity $opacity';

  /// Set window grid position
  /// Format: <rows>:<cols>:<start-x>:<start-y>:<width>:<height>
  static String setGrid(
    int rows,
    int cols,
    int startX,
    int startY,
    int width,
    int height,
  ) =>
      'yabai -m window --grid $rows:$cols:$startX:$startY:$width:$height';

  /// Set window ratio
  static String setRatio(String ratio) =>
      'yabai -m window --ratio $ratio';

  /// Minimize window
  static String minimize() => 'yabai -m window --minimize';

  /// Deminimize/restore window
  static String deminimize() => 'yabai -m window --deminimize';

  /// Close window
  static String close() => 'yabai -m window --close';

  // ==================== Space Focus ====================

  /// Focus space by index
  static String focusSpace(int index) =>
      'yabai -m space --focus $index';

  /// Focus space by label
  static String focusSpaceByLabel(String label) =>
      'yabai -m space --focus $label';

  /// Focus previous space
  static String focusPrevSpace() => 'yabai -m space --focus prev';

  /// Focus next space
  static String focusNextSpace() => 'yabai -m space --focus next';

  /// Focus recent space
  static String focusRecentSpace() => 'yabai -m space --focus recent';

  /// Focus first space
  static String focusFirstSpace() => 'yabai -m space --focus first';

  /// Focus last space
  static String focusLastSpace() => 'yabai -m space --focus last';

  // ==================== Window to Space ====================

  /// Move window to space by index
  static String moveToSpace(int index) =>
      'yabai -m window --space $index';

  /// Move window to space by label
  static String moveToSpaceByLabel(String label) =>
      'yabai -m window --space $label';

  /// Move window to previous space
  static String moveToPrevSpace() => 'yabai -m window --space prev';

  /// Move window to next space
  static String moveToNextSpace() => 'yabai -m window --space next';

  /// Move window to recent space
  static String moveToRecentSpace() => 'yabai -m window --space recent';

  // ==================== Window to Display ====================

  /// Move window to display by index
  static String moveToDisplay(int index) =>
      'yabai -m window --display $index';

  /// Move window to previous display
  static String moveToPrevDisplay() => 'yabai -m window --display prev';

  /// Move window to next display
  static String moveToNextDisplay() => 'yabai -m window --display next';

  /// Move window to recent display
  static String moveToRecentDisplay() =>
      'yabai -m window --display recent';

  // ==================== Display Focus ====================

  /// Focus display by index
  static String focusDisplay(int index) =>
      'yabai -m display --focus $index';

  /// Focus previous display
  static String focusPrevDisplay() => 'yabai -m display --focus prev';

  /// Focus next display
  static String focusNextDisplay() => 'yabai -m display --focus next';

  /// Focus recent display
  static String focusRecentDisplay() =>
      'yabai -m display --focus recent';

  // ==================== Space Management ====================

  /// Create a new space
  static String createSpace() => 'yabai -m space --create';

  /// Create a new space on a specific display
  static String createSpaceOnDisplay(int displayIndex) =>
      'yabai -m display --space $displayIndex --create';

  /// Destroy current space
  static String destroySpace() => 'yabai -m space --destroy';

  /// Destroy space by index
  static String destroySpaceAt(int index) =>
      'yabai -m space $index --destroy';

  /// Set space layout
  static String setLayout(String layout) =>
      'yabai -m space --layout $layout';

  /// Set space layout for specific space
  static String setLayoutFor(int spaceIndex, String layout) =>
      'yabai -m space $spaceIndex --layout $layout';

  /// Set space label
  static String setSpaceLabel(String label) =>
      'yabai -m space --label $label';

  /// Set space label for specific space
  static String setSpaceLabelFor(int spaceIndex, String label) =>
      'yabai -m space $spaceIndex --label $label';

  // ==================== Space Layout Operations ====================

  /// Balance all windows in space
  static String balanceSpace() => 'yabai -m space --balance';

  /// Balance windows in specific space
  static String balanceSpaceAt(int spaceIndex) =>
      'yabai -m space $spaceIndex --balance';

  /// Rotate space layout
  static String rotateSpace(int degrees) =>
      'yabai -m space --rotate $degrees';

  /// Mirror space on X axis
  static String mirrorX() => 'yabai -m space --mirror x-axis';

  /// Mirror space on Y axis
  static String mirrorY() => 'yabai -m space --mirror y-axis';

  // ==================== Space Padding ====================

  /// Set space padding
  static String setPadding(int top, int bottom, int left, int right) =>
      'yabai -m space --padding abs:$top:$bottom:$left:$right';

  /// Adjust space padding relatively
  static String adjustPadding(int top, int bottom, int left, int right) =>
      'yabai -m space --padding rel:$top:$bottom:$left:$right';

  /// Set window gap
  static String setGap(int gap) => 'yabai -m space --gap abs:$gap';

  /// Adjust window gap relatively
  static String adjustGap(int delta) => 'yabai -m space --gap rel:$delta';

  /// Toggle padding for space
  static String togglePadding() => 'yabai -m space --toggle padding';

  /// Toggle gap for space
  static String toggleGap() => 'yabai -m space --toggle gap';

  // ==================== Global Config ====================

  /// Set global configuration option
  static String setConfig(String key, dynamic value) =>
      'yabai -m config $key $value';

  /// Get global configuration option
  static String getConfig(String key) => 'yabai -m config $key';

  /// Set mouse modifier
  static String setMouseModifier(String modifier) =>
      'yabai -m config mouse_modifier $modifier';

  /// Set mouse action 1
  static String setMouseAction1(String action) =>
      'yabai -m config mouse_action1 $action';

  /// Set mouse action 2
  static String setMouseAction2(String action) =>
      'yabai -m config mouse_action2 $action';

  /// Set focus follows mouse
  static String setFocusFollowsMouse(String mode) =>
      'yabai -m config focus_follows_mouse $mode';

  /// Set mouse follows focus
  static String setMouseFollowsFocus(String mode) =>
      'yabai -m config mouse_follows_focus $mode';

  // ==================== Window Rules ====================

  /// Add window rule
  static String addRule({
    String? app,
    String? title,
    String? label,
    bool? manage,
    bool? sticky,
    bool? mouseFollowsFocus,
    bool? subLayer,
    bool? native,
    bool? topmost,
    bool? border,
    bool? shadow,
    double? opacity,
    int? display,
    int? space,
    String? grid,
  }) {
    final parts = <String>['yabai -m rule --add'];

    if (app != null) parts.add('app="$app"');
    if (title != null) parts.add('title="$title"');
    if (label != null) parts.add('label="$label"');
    if (manage != null) parts.add('manage=${manage ? 'on' : 'off'}');
    if (sticky != null) parts.add('sticky=${sticky ? 'on' : 'off'}');
    if (mouseFollowsFocus != null) {
      parts.add('mouse_follows_focus=${mouseFollowsFocus ? 'on' : 'off'}');
    }
    if (subLayer != null) parts.add('sub-layer=${subLayer ? 'above' : 'normal'}');
    if (native != null) parts.add('native-fullscreen=${native ? 'on' : 'off'}');
    if (topmost != null) parts.add('topmost=${topmost ? 'on' : 'off'}');
    if (border != null) parts.add('border=${border ? 'on' : 'off'}');
    if (shadow != null) parts.add('shadow=${shadow ? 'on' : 'off'}');
    if (opacity != null) parts.add('opacity=$opacity');
    if (display != null) parts.add('display=$display');
    if (space != null) parts.add('space=$space');
    if (grid != null) parts.add('grid=$grid');

    return parts.join(' ');
  }

  /// Remove rule by label
  static String removeRule(String label) =>
      'yabai -m rule --remove "$label"';

  // ==================== Signals ====================

  /// Add signal
  static String addSignal({
    required String event,
    required String action,
    String? label,
    String? app,
    String? title,
  }) {
    final parts = <String>[
      'yabai -m signal --add',
      'event=$event',
      'action="$action"',
    ];

    if (label != null) parts.add('label="$label"');
    if (app != null) parts.add('app="$app"');
    if (title != null) parts.add('title="$title"');

    return parts.join(' ');
  }

  /// Remove signal by label
  static String removeSignal(String label) =>
      'yabai -m signal --remove "$label"';

  // ==================== Query Commands ====================

  /// Query all windows
  static String queryWindows() => 'yabai -m query --windows';

  /// Query windows on current space
  static String queryWindowsOnSpace() =>
      'yabai -m query --windows --space';

  /// Query windows on specific space
  static String queryWindowsOnSpaceAt(int spaceIndex) =>
      'yabai -m query --windows --space $spaceIndex';

  /// Query focused window
  static String queryFocusedWindow() =>
      'yabai -m query --windows --window';

  /// Query all spaces
  static String querySpaces() => 'yabai -m query --spaces';

  /// Query current space
  static String queryCurrentSpace() =>
      'yabai -m query --spaces --space';

  /// Query specific space
  static String querySpaceAt(int spaceIndex) =>
      'yabai -m query --spaces --space $spaceIndex';

  /// Query all displays
  static String queryDisplays() => 'yabai -m query --displays';

  /// Query current display
  static String queryCurrentDisplay() =>
      'yabai -m query --displays --display';

  // ==================== Service Commands ====================

  /// Start yabai service
  static String startService() => 'yabai --start-service';

  /// Stop yabai service
  static String stopService() => 'yabai --stop-service';

  /// Restart yabai service
  static String restartService() => 'yabai --restart-service';

  /// Check yabai version
  static String version() => 'yabai --version';

  // ==================== Utility Methods ====================

  /// Build a compound command (multiple commands separated by ;)
  static String compound(List<String> commands) => commands.join(' ; ');

  /// Build a chain of commands (stops on first failure)
  static String chain(List<String> commands) => commands.join(' && ');

  /// Wrap command with conditional
  static String ifThen(String condition, String command) =>
      '[ $condition ] && $command';
}

/// Extension to add utility methods to command strings
extension YabaiCommandExtension on String {
  /// Combine with another command using &&
  String andThen(String other) => '$this && $other';

  /// Combine with another command using ||
  String orElse(String other) => '$this || $other';

  /// Combine with another command using ;
  String then(String other) => '$this ; $other';
}
