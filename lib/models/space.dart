/// Model representing a Yabai space/desktop
class YabaiSpace {
  final int index;
  final String? label;
  final int displayIndex;
  final String? layout;
  final int? gapOverride;
  final List<YabaiWindow> windows;
  final bool hasFocus;
  final bool isVisible;
  final bool isNativeFullscreen;

  const YabaiSpace({
    required this.index,
    this.label,
    required this.displayIndex,
    this.layout,
    this.gapOverride,
    this.windows = const [],
    this.hasFocus = false,
    this.isVisible = false,
    this.isNativeFullscreen = false,
  });

  YabaiSpace copyWith({
    int? index,
    String? label,
    int? displayIndex,
    String? layout,
    int? gapOverride,
    List<YabaiWindow>? windows,
    bool? hasFocus,
    bool? isVisible,
    bool? isNativeFullscreen,
  }) {
    return YabaiSpace(
      index: index ?? this.index,
      label: label ?? this.label,
      displayIndex: displayIndex ?? this.displayIndex,
      layout: layout ?? this.layout,
      gapOverride: gapOverride ?? this.gapOverride,
      windows: windows ?? this.windows,
      hasFocus: hasFocus ?? this.hasFocus,
      isVisible: isVisible ?? this.isVisible,
      isNativeFullscreen: isNativeFullscreen ?? this.isNativeFullscreen,
    );
  }

  factory YabaiSpace.fromJson(Map<String, dynamic> json) {
    return YabaiSpace(
      index: json['index'] as int? ?? 0,
      label: json['label'] as String?,
      displayIndex: json['display'] as int? ?? 1,
      layout: json['type'] as String?,
      hasFocus: json['has-focus'] as bool? ?? false,
      isVisible: json['is-visible'] as bool? ?? false,
      isNativeFullscreen: json['is-native-fullscreen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'label': label,
      'display': displayIndex,
      'type': layout,
      'has-focus': hasFocus,
      'is-visible': isVisible,
      'is-native-fullscreen': isNativeFullscreen,
    };
  }
}

/// Model representing a window in Yabai
class YabaiWindow {
  final int id;
  final String app;
  final String title;
  final int spaceIndex;
  final int displayIndex;
  final bool hasFocus;
  final bool isMinimized;
  final bool isFloating;
  final bool isVisible;
  final WindowFrame? frame;

  const YabaiWindow({
    required this.id,
    required this.app,
    required this.title,
    required this.spaceIndex,
    required this.displayIndex,
    this.hasFocus = false,
    this.isMinimized = false,
    this.isFloating = false,
    this.isVisible = true,
    this.frame,
  });

  factory YabaiWindow.fromJson(Map<String, dynamic> json) {
    return YabaiWindow(
      id: json['id'] as int? ?? 0,
      app: json['app'] as String? ?? 'Unknown',
      title: json['title'] as String? ?? '',
      spaceIndex: json['space'] as int? ?? 0,
      displayIndex: json['display'] as int? ?? 1,
      hasFocus: json['has-focus'] as bool? ?? false,
      isMinimized: json['is-minimized'] as bool? ?? false,
      isFloating: json['is-floating'] as bool? ?? false,
      isVisible: json['is-visible'] as bool? ?? true,
      frame: json['frame'] != null
          ? WindowFrame.fromJson(json['frame'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model representing a window's frame/position
class WindowFrame {
  final double x;
  final double y;
  final double width;
  final double height;

  const WindowFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory WindowFrame.fromJson(Map<String, dynamic> json) {
    return WindowFrame(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['w'] as num?)?.toDouble() ?? 0,
      height: (json['h'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Model representing a display/monitor
class YabaiDisplay {
  final int index;
  final String uuid;
  final int spaceCount;
  final List<int> spaceIndices;
  final DisplayFrame? frame;

  const YabaiDisplay({
    required this.index,
    required this.uuid,
    this.spaceCount = 0,
    this.spaceIndices = const [],
    this.frame,
  });

  factory YabaiDisplay.fromJson(Map<String, dynamic> json) {
    return YabaiDisplay(
      index: json['index'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      spaceCount: (json['spaces'] as List?)?.length ?? 0,
      spaceIndices: (json['spaces'] as List?)?.cast<int>() ?? [],
      frame: json['frame'] != null
          ? DisplayFrame.fromJson(json['frame'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model representing a display's frame
class DisplayFrame {
  final double x;
  final double y;
  final double width;
  final double height;

  const DisplayFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DisplayFrame.fromJson(Map<String, dynamic> json) {
    return DisplayFrame(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['w'] as num?)?.toDouble() ?? 0,
      height: (json['h'] as num?)?.toDouble() ?? 0,
    );
  }
}
