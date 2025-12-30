import '../models/yabai_config.dart';
import '../models/skhd_config.dart';
import '../models/window_rule.dart';
import '../models/signal.dart';
import '../models/exclusion_rule.dart';

/// Service for parsing yabai and skhd configuration files
class ConfigParser {
  static int _ruleIdCounter = 0;
  static int _signalIdCounter = 0;
  static int _exclusionIdCounter = 0;

  /// Parse a .yabairc file content into a YabaiConfig object
  static YabaiConfig parseYabairc(String content) {
    final lines = content.split('\n');
    final settings = <String, dynamic>{};
    final rules = <WindowRule>[];
    final signals = <YabaiSignal>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      // Skip empty lines and comments
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Parse yabai commands
      if (trimmedLine.startsWith('yabai ')) {
        _parseYabaiCommand(trimmedLine, settings, rules, signals);
      }
    }

    // Build YabaiConfig from parsed settings
    return _buildYabaiConfig(settings, rules, signals);
  }

  /// Parse exclusion rules from .yabairc content
  static List<ExclusionRule> parseExclusionRules(String content) {
    final lines = content.split('\n');
    final exclusions = <ExclusionRule>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      // Skip empty lines and comments
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Parse rule commands: yabai -m rule --add <properties>
      final rulePattern = RegExp(r'yabai\s+-m\s+rule\s+--add\s+(.+)$');
      final ruleMatch = rulePattern.firstMatch(trimmedLine);
      if (ruleMatch != null) {
        final exclusion = _parseExclusionRule(ruleMatch.group(1)!);
        if (exclusion != null) {
          exclusions.add(exclusion);
        }
      }
    }

    return exclusions;
  }

  /// Parse a rule properties string into an ExclusionRule
  static ExclusionRule? _parseExclusionRule(String propertiesStr) {
    final properties = _parseProperties(propertiesStr);
    if (properties.isEmpty) return null;

    String? appName = properties['app'] as String?;
    final title = properties['title'] as String?;

    // Remove regex anchors if present
    if (appName != null) {
      appName = appName.replaceAll(RegExp(r'^\^'), '').replaceAll(RegExp(r'\$$'), '');
    }

    // If no app selector, skip
    if (appName == null || appName.isEmpty) return null;

    // Parse manage value (could be 'off', 'on', 'false', 'true')
    final manageValue = properties['manage'];
    bool manageOff = false;
    if (manageValue != null) {
      if (manageValue == 'off' || manageValue == false) {
        manageOff = true;
      }
    }

    // Parse sticky
    final stickyValue = properties['sticky'];
    bool sticky = false;
    if (stickyValue != null) {
      if (stickyValue == 'on' || stickyValue == true) {
        sticky = true;
      }
    }

    // Parse layer
    WindowLayer layer = WindowLayer.normal;
    final layerValue = properties['layer'] as String?;
    if (layerValue != null) {
      if (layerValue == 'below') {
        layer = WindowLayer.below;
      } else if (layerValue == 'above') {
        layer = WindowLayer.above;
      }
    }

    // Parse space
    final space = _parseInt(properties['space']);

    return ExclusionRule(
      id: 'exclusion_${_exclusionIdCounter++}',
      appName: appName,
      titlePattern: title,
      manageOff: manageOff,
      sticky: sticky,
      layer: layer,
      assignedSpace: space,
      isEnabled: true,
    );
  }

  /// Build a YabaiConfig from parsed settings map
  static YabaiConfig _buildYabaiConfig(
    Map<String, dynamic> settings,
    List<WindowRule> rules,
    List<YabaiSignal> signals,
  ) {
    return YabaiConfig(
      layout: _parseString(settings['layout']) ?? 'bsp',
      windowGap: _parseInt(settings['window_gap']) ?? 6,
      topPadding: _parseInt(settings['top_padding']) ?? 6,
      bottomPadding: _parseInt(settings['bottom_padding']) ?? 6,
      leftPadding: _parseInt(settings['left_padding']) ?? 6,
      rightPadding: _parseInt(settings['right_padding']) ?? 6,
      windowPlacement: _parseString(settings['window_placement']) ?? 'second_child',
      externalBar: _parseString(settings['external_bar']),
      mouseFollowsFocus: _parseBool(settings['mouse_follows_focus']) ?? false,
      focusFollowsMouse: _parseString(settings['focus_follows_mouse']) ?? 'off',
      mouseModifier: _parseString(settings['mouse_modifier']) ?? 'alt',
      mouseAction1: _parseString(settings['mouse_action1']) ?? 'move',
      mouseAction2: _parseString(settings['mouse_action2']) ?? 'resize',
      mouseDropAction: _parseString(settings['mouse_drop_action']) ?? 'swap',
      autoBalance: _parseBool(settings['auto_balance']) ?? false,
      splitRatio: _parseDouble(settings['split_ratio']) ?? 0.5,
      splitType: _parseString(settings['split_type']) ?? 'auto',
      windowOpacity: _parseBool(settings['window_opacity']) ?? false,
      activeWindowOpacity: _parseDouble(settings['active_window_opacity']) ?? 1.0,
      normalWindowOpacity: _parseDouble(settings['normal_window_opacity']) ?? 0.9,
      windowShadow: _parseString(settings['window_shadow']) ?? 'on',
      windowBorder: _parseBool(settings['window_border']) ?? false,
      windowBorderWidth: _parseInt(settings['window_border_width']) ?? 4,
      activeWindowBorderColor: _parseString(settings['active_window_border_color']) ?? '0xff775759',
      normalWindowBorderColor: _parseString(settings['normal_window_border_color']) ?? '0xff555555',
      insertFeedbackColor: _parseString(settings['insert_feedback_color']) ?? '0xffd75f5f',
      windowAnimationDuration: _parseDouble(settings['window_animation_duration']) ?? 0.0,
      rules: rules,
      signals: signals,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is bool) return value ? 'on' : 'off';
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'on' || lower == 'yes' || lower == 'true') return true;
      if (lower == 'off' || lower == 'no' || lower == 'false') return false;
    }
    return null;
  }

  /// Parse a single yabai command line
  static void _parseYabaiCommand(
    String line,
    Map<String, dynamic> settings,
    List<WindowRule> rules,
    List<YabaiSignal> signals,
  ) {
    // Remove trailing comments
    final commentIndex = line.indexOf(' #');
    final cleanLine = commentIndex > 0 ? line.substring(0, commentIndex).trim() : line;

    // Parse config commands: yabai -m config <key> <value>
    final configPattern = RegExp(r'yabai\s+-m\s+config\s+(\S+)\s+(.+)$');
    final configMatch = configPattern.firstMatch(cleanLine);
    if (configMatch != null) {
      final key = configMatch.group(1)!;
      final value = _parseValue(configMatch.group(2)!.trim());
      settings[key] = value;
      return;
    }

    // Parse rule commands: yabai -m rule --add <properties>
    final rulePattern = RegExp(r'yabai\s+-m\s+rule\s+--add\s+(.+)$');
    final ruleMatch = rulePattern.firstMatch(cleanLine);
    if (ruleMatch != null) {
      final rule = _parseRule(ruleMatch.group(1)!);
      if (rule != null) {
        rules.add(rule);
      }
      return;
    }

    // Parse signal commands: yabai -m signal --add <properties>
    final signalPattern = RegExp(r'yabai\s+-m\s+signal\s+--add\s+(.+)$');
    final signalMatch = signalPattern.firstMatch(cleanLine);
    if (signalMatch != null) {
      final signal = _parseSignal(signalMatch.group(1)!);
      if (signal != null) {
        signals.add(signal);
      }
      return;
    }
  }

  /// Parse a value string into the appropriate type
  static dynamic _parseValue(String value) {
    // Boolean values
    if (value == 'on' || value == 'yes' || value == 'true') return true;
    if (value == 'off' || value == 'no' || value == 'false') return false;

    // Integer values
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Double values
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;

    // String value (remove quotes if present)
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }

  /// Parse a rule properties string into a WindowRule
  static WindowRule? _parseRule(String propertiesStr) {
    final properties = _parseProperties(propertiesStr);
    if (properties.isEmpty) return null;

    final appName = properties['app'] as String?;
    final title = properties['title'] as String?;

    // If no app or title selector, skip
    if (appName == null && title == null) return null;

    return WindowRule(
      id: 'rule_${_ruleIdCounter++}',
      appName: appName,
      title: title,
      manage: _parseBool(properties['manage']) ?? true,
      sticky: _parseBool(properties['sticky']),
      layer: properties['layer'] as String?,
      space: _parseInt(properties['space']),
      enabled: true,
    );
  }

  /// Parse a signal properties string into a YabaiSignal
  static YabaiSignal? _parseSignal(String propertiesStr) {
    final properties = _parseProperties(propertiesStr);
    final event = properties['event']?.toString();
    final action = properties['action']?.toString();

    if (event == null || action == null) return null;

    return YabaiSignal(
      id: 'signal_${_signalIdCounter++}',
      event: event,
      action: action,
      label: properties['label']?.toString(),
      enabled: true,
    );
  }

  /// Parse a properties string like: app="Finder" manage=off
  static Map<String, dynamic> _parseProperties(String propertiesStr) {
    final properties = <String, dynamic>{};

    // Pattern to match key=value or key="value with spaces"
    final pattern = RegExp(r'''(\w+)=(?:"([^"]*?)"|'([^']*?)'|(\S+))''');
    final matches = pattern.allMatches(propertiesStr);

    for (final match in matches) {
      final key = match.group(1)!;
      // Value could be in group 2 (double quoted), 3 (single quoted), or 4 (unquoted)
      final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      properties[key] = _parseValue(value);
    }

    return properties;
  }

  /// Parse a .skhdrc file content into a SkhdConfig object
  /// Uses the built-in SkhdConfig.fromSkhdrc factory
  static SkhdConfig parseSkhdrc(String content) {
    return SkhdConfig.fromSkhdrc(content);
  }

  /// Parse a single skhd shortcut line
  /// Returns null if the line is not a valid shortcut
  static Shortcut? parseShortcutLine(String line, {String? id, String? category}) {
    return Shortcut.fromSkhdLine(line, id: id, precedingComment: null)?.copyWith(
      category: category,
    );
  }

  /// Validate yabairc content and return any errors
  static List<ConfigParseError> validateYabairc(String content) {
    final errors = <ConfigParseError>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      final lineNumber = i + 1;

      // Skip empty lines and comments
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Check for yabai commands
      if (trimmedLine.startsWith('yabai ')) {
        final error = _validateYabaiCommand(trimmedLine, lineNumber);
        if (error != null) {
          errors.add(error);
        }
      } else if (!trimmedLine.startsWith('echo ') &&
                 !trimmedLine.startsWith('#!/') &&
                 !trimmedLine.contains('=')) {
        errors.add(ConfigParseError(
          lineNumber: lineNumber,
          message: 'Unrecognized command',
          line: trimmedLine,
        ));
      }
    }

    return errors;
  }

  static ConfigParseError? _validateYabaiCommand(String line, int lineNumber) {
    // Check for valid command structure
    if (!line.contains('-m')) {
      return ConfigParseError(
        lineNumber: lineNumber,
        message: 'Missing -m flag in yabai command',
        line: line,
      );
    }

    // Check for config command
    final configPattern = RegExp(r'yabai\s+-m\s+config\s+(\S+)\s+(.+)$');
    if (line.contains('-m config')) {
      if (!configPattern.hasMatch(line)) {
        return ConfigParseError(
          lineNumber: lineNumber,
          message: 'Invalid config command format',
          line: line,
        );
      }
    }

    // Check for rule command
    if (line.contains('-m rule')) {
      if (!line.contains('--add') && !line.contains('--remove')) {
        return ConfigParseError(
          lineNumber: lineNumber,
          message: 'Rule command missing --add or --remove',
          line: line,
        );
      }
    }

    // Check for signal command
    if (line.contains('-m signal')) {
      if (!line.contains('--add') && !line.contains('--remove')) {
        return ConfigParseError(
          lineNumber: lineNumber,
          message: 'Signal command missing --add or --remove',
          line: line,
        );
      }
      if (line.contains('--add') && !line.contains('event=')) {
        return ConfigParseError(
          lineNumber: lineNumber,
          message: 'Signal --add missing event parameter',
          line: line,
        );
      }
      if (line.contains('--add') && !line.contains('action=')) {
        return ConfigParseError(
          lineNumber: lineNumber,
          message: 'Signal --add missing action parameter',
          line: line,
        );
      }
    }

    return null;
  }

  /// Validate skhdrc content and return any errors
  static List<ConfigParseError> validateSkhdrc(String content) {
    final errors = <ConfigParseError>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      final lineNumber = i + 1;

      // Skip empty lines and comments
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Skip mode declarations
      if (trimmedLine.startsWith('::')) {
        continue;
      }

      // Check for valid shortcut format
      if (!trimmedLine.contains(':')) {
        errors.add(ConfigParseError(
          lineNumber: lineNumber,
          message: 'Missing command separator ":"',
          line: trimmedLine,
        ));
        continue;
      }

      // Try to parse as shortcut
      final shortcut = Shortcut.fromSkhdLine(trimmedLine);
      if (shortcut == null) {
        errors.add(ConfigParseError(
          lineNumber: lineNumber,
          message: 'Invalid shortcut format',
          line: trimmedLine,
        ));
      }
    }

    return errors;
  }
}

/// Error encountered during config parsing
class ConfigParseError {
  final int lineNumber;
  final String message;
  final String line;

  const ConfigParseError({
    required this.lineNumber,
    required this.message,
    required this.line,
  });

  @override
  String toString() => 'Line $lineNumber: $message\n  $line';
}
