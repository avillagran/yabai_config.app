import 'package:flutter/foundation.dart';

/// Layer options for window rules
enum WindowLayer {
  below,
  normal,
  above,
}

/// Model representing a window exclusion rule for Yabai
@immutable
class ExclusionRule {
  final String id;
  final String appName;
  final String? titlePattern;
  final bool manageOff;
  final bool sticky;
  final WindowLayer layer;
  final int? assignedSpace;
  final bool isEnabled;

  const ExclusionRule({
    required this.id,
    required this.appName,
    this.titlePattern,
    this.manageOff = true,
    this.sticky = false,
    this.layer = WindowLayer.normal,
    this.assignedSpace,
    this.isEnabled = true,
  });

  ExclusionRule copyWith({
    String? id,
    String? appName,
    String? titlePattern,
    bool? manageOff,
    bool? sticky,
    WindowLayer? layer,
    int? assignedSpace,
    bool? isEnabled,
    bool clearTitlePattern = false,
    bool clearAssignedSpace = false,
  }) {
    return ExclusionRule(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      titlePattern: clearTitlePattern ? null : (titlePattern ?? this.titlePattern),
      manageOff: manageOff ?? this.manageOff,
      sticky: sticky ?? this.sticky,
      layer: layer ?? this.layer,
      assignedSpace: clearAssignedSpace ? null : (assignedSpace ?? this.assignedSpace),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert to Yabai rule command
  String toYabaiCommand() {
    final conditions = <String>[];

    conditions.add('app="^$appName\$"');

    if (titlePattern != null && titlePattern!.isNotEmpty) {
      conditions.add('title="$titlePattern"');
    }

    final actions = <String>[];

    if (manageOff) {
      actions.add('manage=off');
    }

    if (sticky) {
      actions.add('sticky=on');
    }

    if (layer != WindowLayer.normal) {
      actions.add('layer=${layer.name}');
    }

    if (assignedSpace != null) {
      actions.add('space=$assignedSpace');
    }

    if (actions.isEmpty) {
      return '';
    }

    return 'yabai -m rule --add ${conditions.join(' ')} ${actions.join(' ')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'titlePattern': titlePattern,
      'manageOff': manageOff,
      'sticky': sticky,
      'layer': layer.name,
      'assignedSpace': assignedSpace,
      'isEnabled': isEnabled,
    };
  }

  factory ExclusionRule.fromJson(Map<String, dynamic> json) {
    return ExclusionRule(
      id: json['id'] as String,
      appName: json['appName'] as String,
      titlePattern: json['titlePattern'] as String?,
      manageOff: json['manageOff'] as bool? ?? true,
      sticky: json['sticky'] as bool? ?? false,
      layer: WindowLayer.values.firstWhere(
        (l) => l.name == json['layer'],
        orElse: () => WindowLayer.normal,
      ),
      assignedSpace: json['assignedSpace'] as int?,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExclusionRule &&
        other.id == id &&
        other.appName == appName &&
        other.titlePattern == titlePattern &&
        other.manageOff == manageOff &&
        other.sticky == sticky &&
        other.layer == layer &&
        other.assignedSpace == assignedSpace &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      appName,
      titlePattern,
      manageOff,
      sticky,
      layer,
      assignedSpace,
      isEnabled,
    );
  }
}
