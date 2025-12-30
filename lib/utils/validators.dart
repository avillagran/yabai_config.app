/// Input validation utilities for Yabai Config app.
///
/// Provides validation methods for various input types used throughout the app.
class Validators {
  Validators._();

  // ==================== App Name Validation ====================

  /// Validates an application name pattern.
  ///
  /// App names can be:
  /// - Simple app names like "Firefox", "Safari"
  /// - Bundle identifiers like "com.apple.Safari"
  /// - Regex patterns when prefixed with ^
  ///
  /// Returns null if valid, or an error message if invalid.
  static String? appNamePattern(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'App name is required';
    }

    final trimmed = value.trim();

    // Check for invalid characters in simple app names
    if (!trimmed.startsWith('^')) {
      // Simple app name or bundle identifier
      if (!_isValidAppName(trimmed)) {
        return 'Invalid app name format';
      }
    } else {
      // Regex pattern - validate it's a valid regex
      final regexError = regexPattern(trimmed);
      if (regexError != null) {
        return regexError;
      }
    }

    return null;
  }

  /// Check if a string is a valid app name or bundle identifier
  static bool _isValidAppName(String name) {
    // Allow alphanumeric, dots, spaces, hyphens, underscores
    final validPattern = RegExp(r'^[\w\s.\-]+$');
    return validPattern.hasMatch(name);
  }

  // ==================== Regex Validation ====================

  /// Validates a regular expression pattern.
  ///
  /// Returns null if valid, or an error message if invalid.
  static String? regexPattern(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pattern is required';
    }

    try {
      RegExp(value);
      return null;
    } on FormatException catch (e) {
      return 'Invalid regex: ${e.message}';
    }
  }

  /// Check if a string is a valid regex pattern
  static bool isValidRegex(String pattern) {
    try {
      RegExp(pattern);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== Shortcut Key Validation ====================

  /// Validates a shortcut key.
  ///
  /// Valid keys are:
  /// - Single letters (a-z)
  /// - Single digits (0-9)
  /// - Function keys (f1-f20)
  /// - Special keys (space, tab, return, etc.)
  ///
  /// Returns null if valid, or an error message if invalid.
  static String? shortcutKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Key is required';
    }

    final key = value.trim().toLowerCase();

    if (!isValidKey(key)) {
      return 'Invalid key: $key';
    }

    return null;
  }

  /// Check if a string is a valid SKHD key
  static bool isValidKey(String key) {
    final normalized = key.toLowerCase().trim();

    // Single letter
    if (normalized.length == 1 && RegExp(r'^[a-z]$').hasMatch(normalized)) {
      return true;
    }

    // Single digit
    if (normalized.length == 1 && RegExp(r'^[0-9]$').hasMatch(normalized)) {
      return true;
    }

    // Function keys
    if (RegExp(r'^f([1-9]|1[0-9]|20)$').hasMatch(normalized)) {
      return true;
    }

    // Special keys
    const specialKeys = {
      'space',
      'tab',
      'return',
      'escape',
      'delete',
      'forwarddelete',
      'home',
      'end',
      'pageup',
      'pagedown',
      'left',
      'right',
      'up',
      'down',
      'caps_lock',
      'help',
      'insert',
    };

    if (specialKeys.contains(normalized)) {
      return true;
    }

    // Keypad keys
    if (normalized.startsWith('kp_') ||
        RegExp(r'^kp[0-9]$').hasMatch(normalized)) {
      return true;
    }

    return false;
  }

  // ==================== Modifier Validation ====================

  /// Validates a modifier key.
  ///
  /// Returns null if valid, or an error message if invalid.
  static String? modifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Modifier is required';
    }

    if (!isValidModifier(value.trim())) {
      return 'Invalid modifier: $value';
    }

    return null;
  }

  /// Check if a string is a valid SKHD modifier
  static bool isValidModifier(String modifier) {
    const validModifiers = {
      'alt',
      'lalt',
      'ralt',
      'shift',
      'lshift',
      'rshift',
      'cmd',
      'lcmd',
      'rcmd',
      'ctrl',
      'lctrl',
      'rctrl',
      'fn',
      'hyper',
      'meh',
    };

    return validModifiers.contains(modifier.toLowerCase().trim());
  }

  // ==================== Yabai Command Validation ====================

  /// Check if a string is a valid yabai command.
  ///
  /// This performs basic syntax checking, not full command validation.
  static bool isValidYabaiCommand(String cmd) {
    if (cmd.trim().isEmpty) {
      return false;
    }

    final trimmed = cmd.trim();

    // Check if it starts with yabai
    if (!trimmed.startsWith('yabai')) {
      return false;
    }

    // Check for basic command structure
    if (!trimmed.contains('-m')) {
      // Could be service commands or version
      if (trimmed.contains('--start-service') ||
          trimmed.contains('--stop-service') ||
          trimmed.contains('--restart-service') ||
          trimmed.contains('--version') ||
          trimmed.contains('--help')) {
        return true;
      }
      return false;
    }

    // Check for valid domain
    final domains = ['window', 'space', 'display', 'query', 'rule', 'signal', 'config'];
    final hasDomain = domains.any((d) => trimmed.contains(d));

    return hasDomain;
  }

  /// Validate yabai command with detailed error
  static String? validateYabaiCommand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Command is required';
    }

    if (!isValidYabaiCommand(value)) {
      return 'Invalid yabai command format';
    }

    return null;
  }

  // ==================== Shortcut String Validation ====================

  /// Validates a full shortcut string (e.g., "alt + shift - h").
  ///
  /// Returns null if valid, or an error message if invalid.
  static String? shortcutString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shortcut is required';
    }

    final parts = _parseShortcutString(value);
    if (parts == null) {
      return 'Invalid shortcut format. Use: modifier + key or modifier - key';
    }

    final modifiers = parts['modifiers'] as List<String>;
    final key = parts['key'] as String;

    // Validate all modifiers
    for (final mod in modifiers) {
      if (!isValidModifier(mod)) {
        return 'Invalid modifier: $mod';
      }
    }

    // Validate key
    if (!isValidKey(key)) {
      return 'Invalid key: $key';
    }

    return null;
  }

  /// Parse a shortcut string into components
  static Map<String, dynamic>? _parseShortcutString(String shortcut) {
    final trimmed = shortcut.trim();

    // Split by the last '-' or ' ' to separate key
    // Format: "modifier + modifier - key" or "modifier - key"
    final lastDash = trimmed.lastIndexOf(' - ');
    if (lastDash == -1) {
      // Try simpler format: "modifier - key"
      final dashIndex = trimmed.indexOf('-');
      if (dashIndex == -1) return null;

      final modPart = trimmed.substring(0, dashIndex).trim();
      final key = trimmed.substring(dashIndex + 1).trim();

      if (key.isEmpty) return null;

      final modifiers = modPart
          .split('+')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      return {'modifiers': modifiers, 'key': key};
    }

    final modPart = trimmed.substring(0, lastDash).trim();
    final key = trimmed.substring(lastDash + 3).trim();

    if (key.isEmpty) return null;

    final modifiers = modPart
        .split('+')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    return {'modifiers': modifiers, 'key': key};
  }

  // ==================== Numeric Validation ====================

  /// Validates a positive integer value.
  static String? positiveInt(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return '$fieldName must be a number';
    }

    if (parsed < 0) {
      return '$fieldName must be positive';
    }

    return null;
  }

  /// Validates an integer within a range.
  static String? intInRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return '$fieldName must be a number';
    }

    if (parsed < min || parsed > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validates a decimal value between 0 and 1 (e.g., for opacity).
  static String? decimal01(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      return '$fieldName must be a number';
    }

    if (parsed < 0.0 || parsed > 1.0) {
      return '$fieldName must be between 0.0 and 1.0';
    }

    return null;
  }

  // ==================== Color Validation ====================

  /// Validates a hex color value.
  static String? hexColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Color is required';
    }

    final trimmed = value.trim();

    // Allow formats: #RGB, #RRGGBB, #AARRGGBB, 0xRRGGBB, 0xAARRGGBB
    final patterns = [
      RegExp(r'^#[0-9A-Fa-f]{3}$'),
      RegExp(r'^#[0-9A-Fa-f]{6}$'),
      RegExp(r'^#[0-9A-Fa-f]{8}$'),
      RegExp(r'^0x[0-9A-Fa-f]{6}$'),
      RegExp(r'^0x[0-9A-Fa-f]{8}$'),
    ];

    if (!patterns.any((p) => p.hasMatch(trimmed))) {
      return 'Invalid color format. Use #RRGGBB or 0xRRGGBB';
    }

    return null;
  }

  /// Check if a string is a valid hex color
  static bool isValidHexColor(String color) {
    return hexColor(color) == null;
  }

  // ==================== Label Validation ====================

  /// Validates a space or rule label.
  static String? label(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Label is required';
    }

    final trimmed = value.trim();

    // Labels should be alphanumeric with underscores/hyphens
    if (!RegExp(r'^[\w\-]+$').hasMatch(trimmed)) {
      return 'Label can only contain letters, numbers, hyphens, and underscores';
    }

    if (trimmed.length > 50) {
      return 'Label is too long (max 50 characters)';
    }

    return null;
  }

  // ==================== Path Validation ====================

  /// Validates a file path.
  static String? filePath(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Path is required';
    }

    final trimmed = value.trim();

    // Basic path validation
    if (!trimmed.startsWith('/') && !trimmed.startsWith('~')) {
      return 'Path must be absolute (start with / or ~)';
    }

    // Check for suspicious patterns
    if (trimmed.contains('..')) {
      return 'Path cannot contain ".."';
    }

    return null;
  }
}

/// Extension to combine validators
extension ValidatorCombine on String? Function(String?) {
  /// Combine this validator with another, running both
  String? Function(String?) and(String? Function(String?) other) {
    return (String? value) {
      final first = this(value);
      if (first != null) return first;
      return other(value);
    };
  }

  /// Make this validator optional (allow empty values)
  String? Function(String?) get optional {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return this(value);
    };
  }
}
