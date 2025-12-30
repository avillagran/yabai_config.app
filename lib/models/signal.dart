/// Yabai signal configuration
///
/// Signals allow executing commands in response to Yabai events
/// such as window creation, space changes, etc.
class YabaiSignal {
  /// Unique identifier for this signal
  final String id;

  /// Event type that triggers this signal
  final String event;

  /// Command to execute when the event occurs
  final String action;

  /// Optional label for the signal
  final String? label;

  /// Whether this signal is currently enabled
  final bool enabled;

  /// Valid Yabai signal events
  static const List<String> validEvents = [
    'application_launched',
    'application_terminated',
    'application_front_switched',
    'application_activated',
    'application_deactivated',
    'application_visible',
    'application_hidden',
    'window_created',
    'window_destroyed',
    'window_focused',
    'window_moved',
    'window_resized',
    'window_minimized',
    'window_deminimized',
    'window_title_changed',
    'space_created',
    'space_destroyed',
    'space_changed',
    'display_added',
    'display_removed',
    'display_moved',
    'display_resized',
    'display_changed',
    'mission_control_enter',
    'mission_control_exit',
    'dock_did_restart',
    'menu_bar_hidden_changed',
    'system_woke',
  ];

  /// Event type enum for type-safe event handling
  static const Map<String, String> eventDescriptions = {
    'application_launched': 'When an application is launched',
    'application_terminated': 'When an application is terminated',
    'application_front_switched': 'When the frontmost application changes',
    'application_activated': 'When an application is activated',
    'application_deactivated': 'When an application is deactivated',
    'application_visible': 'When an application becomes visible',
    'application_hidden': 'When an application is hidden',
    'window_created': 'When a window is created',
    'window_destroyed': 'When a window is destroyed',
    'window_focused': 'When a window gains focus',
    'window_moved': 'When a window is moved',
    'window_resized': 'When a window is resized',
    'window_minimized': 'When a window is minimized',
    'window_deminimized': 'When a window is restored from dock',
    'window_title_changed': 'When a window title changes',
    'space_created': 'When a space is created',
    'space_destroyed': 'When a space is destroyed',
    'space_changed': 'When the active space changes',
    'display_added': 'When a display is added',
    'display_removed': 'When a display is removed',
    'display_moved': 'When a display is moved',
    'display_resized': 'When a display is resized',
    'display_changed': 'When the active display changes',
    'mission_control_enter': 'When Mission Control is activated',
    'mission_control_exit': 'When Mission Control is exited',
    'dock_did_restart': 'When the Dock restarts',
    'menu_bar_hidden_changed': 'When menu bar visibility changes',
    'system_woke': 'When the system wakes from sleep',
  };

  const YabaiSignal({
    required this.id,
    required this.event,
    required this.action,
    this.label,
    this.enabled = true,
  });

  /// Creates a copy of this YabaiSignal with the given fields replaced
  YabaiSignal copyWith({
    String? id,
    String? event,
    String? action,
    String? label,
    bool? enabled,
    bool clearLabel = false,
  }) {
    return YabaiSignal(
      id: id ?? this.id,
      event: event ?? this.event,
      action: action ?? this.action,
      label: clearLabel ? null : (label ?? this.label),
      enabled: enabled ?? this.enabled,
    );
  }

  /// Creates a YabaiSignal from JSON
  factory YabaiSignal.fromJson(Map<String, dynamic> json) {
    return YabaiSignal(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      event: json['event'] as String,
      action: json['action'] as String,
      label: json['label'] as String?,
      enabled: json['enabled'] as bool? ?? json['isEnabled'] as bool? ?? true,
    );
  }

  /// Converts this YabaiSignal to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event,
      'action': action,
      if (label != null) 'label': label,
      'enabled': enabled,
    };
  }

  /// Generates yabai signal command for this signal
  String toYabaiCommand() {
    if (!enabled) return '';

    final buffer = StringBuffer('yabai -m signal --add');

    if (label != null && label!.isNotEmpty) {
      buffer.write(' label="$label"');
    }

    buffer.write(' event=$event');
    buffer.write(' action="$action"');

    return buffer.toString();
  }

  /// Validates if the event is a known Yabai event
  bool get isValidEvent => validEvents.contains(event);

  /// Returns a human-readable description of the event
  String get eventDescription => eventDescriptions[event] ?? 'Unknown event: $event';

  /// Returns the event display name (formatted)
  String get eventDisplayName {
    return event.split('_').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YabaiSignal &&
        other.id == id &&
        other.event == event &&
        other.action == action &&
        other.label == label &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      event,
      action,
      label,
      enabled,
    );
  }

  @override
  String toString() {
    return 'YabaiSignal(id: $id, event: $event, action: $action, '
        'label: $label, enabled: $enabled)';
  }
}
