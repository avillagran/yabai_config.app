/// Barrel file for all Riverpod providers
///
/// This file exports all providers for the Yabai Config application.
/// Import this file to access all providers in one place:
///
/// ```dart
/// import 'package:yabai_config/providers/providers.dart';
/// ```
library providers;

// Core providers
export 'settings_provider.dart';
// Note: yabai_provider.dart defines the main yabaiConfigProvider, yabaiServiceProvider, backupServiceProvider
export 'yabai_provider.dart';
export 'skhd_provider.dart';

// Feature providers
// backups_provider.dart has a different backupServiceProvider - hide it to avoid conflict
export 'backups_provider.dart' hide backupServiceProvider;
// config_provider.dart has different providers that conflict - hide them
export 'config_provider.dart' hide yabaiConfigProvider, YabaiConfigNotifier, autoSaveEnabledProvider;
export 'exclusions_provider.dart';
export 'navigation_provider.dart';
export 'service_provider.dart';
export 'shortcuts_provider.dart';
export 'signals_provider.dart';
// spaces_provider.dart has a different yabaiServiceProvider - hide it to avoid conflict
export 'spaces_provider.dart' hide yabaiServiceProvider;
