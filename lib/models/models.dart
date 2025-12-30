// Data models for Yabai Config application
//
// This barrel file exports all model classes for convenient importing.
// Note: skhd_config.dart contains Shortcut and ShortcutCategory which are used
// throughout the app. keyboard_shortcut.dart and shortcut.dart are not exported
// here to avoid ambiguous exports - import them directly if needed.

export 'yabai_config.dart';
export 'skhd_config.dart';
export 'window_rule.dart';
export 'signal.dart';
export 'space_config.dart';
export 'exclusion_rule.dart';
// keyboard_shortcut.dart - not exported (ShortcutCategory conflicts with skhd_config.dart)
// shortcut.dart - not exported (Shortcut and ShortcutCategory conflict with skhd_config.dart)
export 'space.dart';
export 'backup_info.dart';
export 'config_enums.dart';
