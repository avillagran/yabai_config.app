/// Space (desktop) configuration for Yabai
///
/// Allows per-space customization of layout and gaps,
/// overriding global settings for specific spaces.
class SpaceConfig {
  /// Space index (1-based, matching macOS space numbering)
  final int index;

  /// Optional custom label for this space
  final String? label;

  /// Layout override for this space (bsp, float, stack)
  /// If null, uses the global layout setting
  final String? layout;

  /// Window gap override for this space
  /// If null, uses the global gap setting
  final int? gap;

  /// Valid layout values
  static const List<String> validLayouts = ['bsp', 'float', 'stack'];

  const SpaceConfig({
    required this.index,
    this.label,
    this.layout,
    this.gap,
  }) : assert(index >= 1, 'Space index must be >= 1'),
       assert(
         layout == null || layout == 'bsp' || layout == 'float' || layout == 'stack',
         'layout must be one of: bsp, float, stack',
       ),
       assert(gap == null || gap >= 0, 'gap must be >= 0');

  /// Creates a copy of this SpaceConfig with the given fields replaced
  SpaceConfig copyWith({
    int? index,
    String? label,
    String? layout,
    int? gap,
    bool clearLabel = false,
    bool clearLayout = false,
    bool clearGap = false,
  }) {
    return SpaceConfig(
      index: index ?? this.index,
      label: clearLabel ? null : (label ?? this.label),
      layout: clearLayout ? null : (layout ?? this.layout),
      gap: clearGap ? null : (gap ?? this.gap),
    );
  }

  /// Creates a SpaceConfig from JSON
  factory SpaceConfig.fromJson(Map<String, dynamic> json) {
    return SpaceConfig(
      index: json['index'] as int,
      label: json['label'] as String?,
      layout: json['layout'] as String?,
      gap: json['gap'] as int?,
    );
  }

  /// Converts this SpaceConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      if (label != null) 'label': label,
      if (layout != null) 'layout': layout,
      if (gap != null) 'gap': gap,
    };
  }

  /// Generates yabai commands to configure this space
  List<String> toYabaiCommands() {
    final commands = <String>[];

    if (label != null) {
      commands.add('yabai -m space $index --label "$label"');
    }

    if (layout != null) {
      commands.add('yabai -m config --space $index layout $layout');
    }

    if (gap != null) {
      commands.add('yabai -m config --space $index window_gap $gap');
    }

    return commands;
  }

  /// Returns a display name for this space
  String get displayName {
    if (label != null && label!.isNotEmpty) {
      return label!;
    }
    return 'Space $index';
  }

  /// Returns a human-readable description of the layout
  String get layoutDescription {
    switch (layout) {
      case 'bsp':
        return 'Binary Space Partitioning';
      case 'float':
        return 'Floating';
      case 'stack':
        return 'Stacked';
      default:
        return 'Default (inherited)';
    }
  }

  /// Whether this space has any custom configuration
  bool get hasCustomization {
    return label != null || layout != null || gap != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpaceConfig &&
        other.index == index &&
        other.label == label &&
        other.layout == layout &&
        other.gap == gap;
  }

  @override
  int get hashCode {
    return Object.hash(
      index,
      label,
      layout,
      gap,
    );
  }

  @override
  String toString() {
    return 'SpaceConfig(index: $index, label: $label, '
        'layout: $layout, gap: $gap)';
  }
}
