/// Window rule for Yabai window management
///
/// Defines rules for how specific windows should be handled by Yabai.
/// Rules can match windows by app name or title using regex patterns.
class WindowRule {
  /// Unique identifier for this rule
  final String id;

  /// Regex pattern to match application name
  final String? appName;

  /// Regex pattern to match window title
  final String? title;

  /// Whether Yabai should manage this window (manage=on/off)
  final bool manage;

  /// Whether the window should be sticky (visible on all spaces)
  final bool? sticky;

  /// Window layer: 'above', 'normal', or 'below'
  final String? layer;

  /// Assign window to specific space index
  final int? space;

  /// Whether this rule is currently enabled
  final bool enabled;

  /// Valid layer values
  static const List<String> validLayers = ['above', 'normal', 'below'];

  const WindowRule({
    required this.id,
    this.appName,
    this.title,
    this.manage = true,
    this.sticky,
    this.layer,
    this.space,
    this.enabled = true,
  }) : assert(
          layer == null ||
              layer == 'above' ||
              layer == 'normal' ||
              layer == 'below',
          'layer must be one of: above, normal, below',
        );

  /// Creates a copy of this WindowRule with the given fields replaced
  WindowRule copyWith({
    String? id,
    String? appName,
    String? title,
    bool? manage,
    bool? sticky,
    String? layer,
    int? space,
    bool? enabled,
    bool clearAppName = false,
    bool clearTitle = false,
    bool clearSticky = false,
    bool clearLayer = false,
    bool clearSpace = false,
  }) {
    return WindowRule(
      id: id ?? this.id,
      appName: clearAppName ? null : (appName ?? this.appName),
      title: clearTitle ? null : (title ?? this.title),
      manage: manage ?? this.manage,
      sticky: clearSticky ? null : (sticky ?? this.sticky),
      layer: clearLayer ? null : (layer ?? this.layer),
      space: clearSpace ? null : (space ?? this.space),
      enabled: enabled ?? this.enabled,
    );
  }

  /// Creates a WindowRule from JSON
  factory WindowRule.fromJson(Map<String, dynamic> json) {
    return WindowRule(
      id: json['id'] as String,
      appName: json['app_name'] as String?,
      title: json['title'] as String?,
      manage: json['manage'] as bool? ?? true,
      sticky: json['sticky'] as bool?,
      layer: json['layer'] as String?,
      space: json['space'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// Converts this WindowRule to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (appName != null) 'app_name': appName,
      if (title != null) 'title': title,
      'manage': manage,
      if (sticky != null) 'sticky': sticky,
      if (layer != null) 'layer': layer,
      if (space != null) 'space': space,
      'enabled': enabled,
    };
  }

  /// Generates yabai rule command(s) for this rule
  List<String> toYabaiCommands() {
    if (!enabled) return [];

    final commands = <String>[];
    final selector = _buildSelector();

    if (selector.isEmpty) return [];

    // manage command
    commands.add('yabai -m rule --add $selector manage=${manage ? 'on' : 'off'}');

    // sticky command
    if (sticky != null) {
      commands.add('yabai -m rule --add $selector sticky=${sticky! ? 'on' : 'off'}');
    }

    // layer command
    if (layer != null) {
      commands.add('yabai -m rule --add $selector layer=$layer');
    }

    // space command
    if (space != null) {
      commands.add('yabai -m rule --add $selector space=$space');
    }

    return commands;
  }

  String _buildSelector() {
    final parts = <String>[];
    if (appName != null) parts.add('app="$appName"');
    if (title != null) parts.add('title="$title"');
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowRule &&
        other.id == id &&
        other.appName == appName &&
        other.title == title &&
        other.manage == manage &&
        other.sticky == sticky &&
        other.layer == layer &&
        other.space == space &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      appName,
      title,
      manage,
      sticky,
      layer,
      space,
      enabled,
    );
  }

  @override
  String toString() {
    return 'WindowRule(id: $id, appName: $appName, title: $title, '
        'manage: $manage, sticky: $sticky, layer: $layer, '
        'space: $space, enabled: $enabled)';
  }
}
