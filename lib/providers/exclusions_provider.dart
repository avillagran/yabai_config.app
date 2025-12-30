import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exclusion_rule.dart';
import '../services/config_parser.dart';
import 'config_provider.dart';

/// State notifier for managing exclusion rules
class ExclusionsNotifier extends StateNotifier<List<ExclusionRule>> {
  final Ref _ref;

  ExclusionsNotifier(this._ref) : super([]) {
    _loadRules();
  }

  static const String _storageKey = 'yabai_exclusion_rules';

  Future<void> _loadRules() async {
    try {
      // Try to load from .yabairc file first
      final home = Platform.environment['HOME'] ?? '';
      final yabairc = File('$home/.yabairc');

      if (await yabairc.exists()) {
        final content = await yabairc.readAsString();
        var rules = ConfigParser.parseExclusionRules(content);

        if (rules.isNotEmpty) {
          // Ensure yabai_config is always present
          rules = _ensureYabaiConfigRule(rules);
          state = rules;
          return;
        }
      }

      // Fallback to SharedPreferences if no rules found in file
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        var rules = jsonList
            .map((json) => ExclusionRule.fromJson(json as Map<String, dynamic>))
            .toList();
        // Ensure yabai_config is always present
        rules = _ensureYabaiConfigRule(rules);
        state = rules;
      } else {
        // Load default rules for common apps
        state = _getDefaultRules();
        await _saveRules();
      }
    } catch (e) {
      state = _getDefaultRules();
    }
  }

  /// Ensures yabai_config exclusion rule is always present (cannot be deleted)
  List<ExclusionRule> _ensureYabaiConfigRule(List<ExclusionRule> rules) {
    final hasYabaiConfig = rules.any((r) => r.appName == 'yabai_config');
    if (!hasYabaiConfig) {
      return [
        const ExclusionRule(
          id: 'system_yabai_config',
          appName: 'yabai_config',
          manageOff: true,
          sticky: false,
          layer: WindowLayer.normal,
        ),
        ...rules,
      ];
    }
    return rules;
  }

  Future<void> _saveRules() async {
    try {
      // Save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((rule) => rule.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));

      // Trigger config save to .yabairc file
      await _saveToYabairc();
    } catch (e) {
      // Handle save error silently
    }
  }

  /// Save exclusion rules to .yabairc file through config_provider
  Future<void> _saveToYabairc() async {
    try {
      // Pass current state directly to avoid timing issues
      final configNotifier = _ref.read(yabaiConfigProvider.notifier);
      await configNotifier.saveConfigWithExclusions(state);
      // Restart yabai to apply changes
      await _restartYabai();
    } catch (e) {
      // Handle save error silently
    }
  }

  /// Restart yabai to apply changes
  Future<void> _restartYabai() async {
    try {
      final paths = ['/opt/homebrew/bin/yabai', '/usr/local/bin/yabai'];
      for (final path in paths) {
        if (await File(path).exists()) {
          await Process.run(path, ['--restart-service']);
          return;
        }
      }
      await Process.run('/bin/bash', ['-c', 'yabai --restart-service']);
    } catch (e) {
      // Ignore errors
    }
  }

  List<ExclusionRule> _getDefaultRules() {
    return [
      const ExclusionRule(
        id: 'default_0',
        appName: 'yabai_config',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
      const ExclusionRule(
        id: 'default_1',
        appName: 'System Preferences',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
      const ExclusionRule(
        id: 'default_2',
        appName: 'System Settings',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
      const ExclusionRule(
        id: 'default_3',
        appName: 'Calculator',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
      const ExclusionRule(
        id: 'default_4',
        appName: 'Archive Utility',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
      const ExclusionRule(
        id: 'default_5',
        appName: 'Finder',
        titlePattern: '(Copy|Move|Trash)',
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      ),
    ];
  }

  void addRule(ExclusionRule rule) {
    state = [...state, rule];
    _saveRules();
  }

  void updateRule(ExclusionRule rule) {
    state = [
      for (final r in state)
        if (r.id == rule.id) rule else r
    ];
    _saveRules();
  }

  void deleteRule(String id) {
    // Prevent deleting the yabai_config rule
    final rule = state.firstWhere((r) => r.id == id, orElse: () => state.first);
    if (rule.appName == 'yabai_config') {
      return;
    }
    state = state.where((rule) => rule.id != id).toList();
    _saveRules();
  }

  void toggleRule(String id) {
    // Prevent disabling the yabai_config rule
    final rule = state.firstWhere((r) => r.id == id, orElse: () => state.first);
    if (rule.appName == 'yabai_config') {
      return;
    }
    state = [
      for (final rule in state)
        if (rule.id == id) rule.copyWith(isEnabled: !rule.isEnabled) else rule
    ];
    _saveRules();
  }

  void reorderRules(int oldIndex, int newIndex) {
    final newState = List<ExclusionRule>.from(state);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = newState.removeAt(oldIndex);
    newState.insert(newIndex, item);
    state = newState;
    _saveRules();
  }

  /// Generate the complete Yabai rules configuration
  String generateConfig() {
    final buffer = StringBuffer();
    buffer.writeln('# Yabai Window Rules');
    buffer.writeln('# Generated by Yabai Config');
    buffer.writeln();

    for (final rule in state) {
      if (rule.isEnabled) {
        final command = rule.toYabaiCommand();
        if (command.isNotEmpty) {
          buffer.writeln(command);
        }
      } else {
        buffer.writeln('# Disabled: ${rule.appName}');
      }
    }

    return buffer.toString();
  }

  /// Reset to default rules
  void resetToDefaults() {
    state = _getDefaultRules();
    _saveRules();
  }
}

/// Provider for exclusion rules
final exclusionsProvider =
    StateNotifierProvider<ExclusionsNotifier, List<ExclusionRule>>((ref) {
  return ExclusionsNotifier(ref);
});

/// Provider for enabled rules only
final enabledExclusionsProvider = Provider<List<ExclusionRule>>((ref) {
  final rules = ref.watch(exclusionsProvider);
  return rules.where((rule) => rule.isEnabled).toList();
});

/// Provider for rules count
final exclusionsCountProvider = Provider<int>((ref) {
  return ref.watch(exclusionsProvider).length;
});

/// Provider for enabled rules count
final enabledExclusionsCountProvider = Provider<int>((ref) {
  return ref.watch(enabledExclusionsProvider).length;
});
