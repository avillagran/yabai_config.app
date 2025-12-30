import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application settings for Yabai Config
@immutable
class AppSettings {
  final String yabaiConfigPath;
  final String skhdConfigPath;
  final bool autoSave;
  final int autoSaveDelay;
  final bool createBackupOnSave;
  final String theme;
  final bool showLineNumbers;
  final bool syntaxHighlighting;

  const AppSettings({
    String? yabaiConfigPath,
    String? skhdConfigPath,
    this.autoSave = true,
    this.autoSaveDelay = 1000,
    this.createBackupOnSave = true,
    this.theme = 'system',
    this.showLineNumbers = true,
    this.syntaxHighlighting = true,
  })  : yabaiConfigPath = yabaiConfigPath ?? '',
        skhdConfigPath = skhdConfigPath ?? '';

  /// Returns the default yabai config path
  static String get defaultYabaiConfigPath {
    final home = Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
    return '$home/.yabairc';
  }

  /// Returns the default skhd config path
  static String get defaultSkhdConfigPath {
    final home = Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
    return '$home/.skhdrc';
  }

  /// Returns the effective yabai config path (using default if empty)
  String get effectiveYabaiConfigPath {
    return yabaiConfigPath.isEmpty ? defaultYabaiConfigPath : yabaiConfigPath;
  }

  /// Returns the effective skhd config path (using default if empty)
  String get effectiveSkhdConfigPath {
    return skhdConfigPath.isEmpty ? defaultSkhdConfigPath : skhdConfigPath;
  }

  AppSettings copyWith({
    String? yabaiConfigPath,
    String? skhdConfigPath,
    bool? autoSave,
    int? autoSaveDelay,
    bool? createBackupOnSave,
    String? theme,
    bool? showLineNumbers,
    bool? syntaxHighlighting,
  }) {
    return AppSettings(
      yabaiConfigPath: yabaiConfigPath ?? this.yabaiConfigPath,
      skhdConfigPath: skhdConfigPath ?? this.skhdConfigPath,
      autoSave: autoSave ?? this.autoSave,
      autoSaveDelay: autoSaveDelay ?? this.autoSaveDelay,
      createBackupOnSave: createBackupOnSave ?? this.createBackupOnSave,
      theme: theme ?? this.theme,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yabaiConfigPath': yabaiConfigPath,
      'skhdConfigPath': skhdConfigPath,
      'autoSave': autoSave,
      'autoSaveDelay': autoSaveDelay,
      'createBackupOnSave': createBackupOnSave,
      'theme': theme,
      'showLineNumbers': showLineNumbers,
      'syntaxHighlighting': syntaxHighlighting,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      yabaiConfigPath: json['yabaiConfigPath'] as String? ?? '',
      skhdConfigPath: json['skhdConfigPath'] as String? ?? '',
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveDelay: json['autoSaveDelay'] as int? ?? 1000,
      createBackupOnSave: json['createBackupOnSave'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'system',
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      syntaxHighlighting: json['syntaxHighlighting'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.yabaiConfigPath == yabaiConfigPath &&
        other.skhdConfigPath == skhdConfigPath &&
        other.autoSave == autoSave &&
        other.autoSaveDelay == autoSaveDelay &&
        other.createBackupOnSave == createBackupOnSave &&
        other.theme == theme &&
        other.showLineNumbers == showLineNumbers &&
        other.syntaxHighlighting == syntaxHighlighting;
  }

  @override
  int get hashCode {
    return Object.hash(
      yabaiConfigPath,
      skhdConfigPath,
      autoSave,
      autoSaveDelay,
      createBackupOnSave,
      theme,
      showLineNumbers,
      syntaxHighlighting,
    );
  }
}
