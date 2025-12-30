import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText, Scrollbar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

/// Screen for viewing and editing raw configuration files
class RawConfigScreen extends ConsumerStatefulWidget {
  const RawConfigScreen({super.key});

  @override
  ConsumerState<RawConfigScreen> createState() => _RawConfigScreenState();
}

class _RawConfigScreenState extends ConsumerState<RawConfigScreen> {
  String _yabaiContent = '';
  String _skhdContent = '';
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      final home = Platform.environment['HOME'] ?? '';

      final yabairc = File('$home/.yabairc');
      if (await yabairc.exists()) {
        _yabaiContent = await yabairc.readAsString();
      } else {
        _yabaiContent = '# ~/.yabairc not found';
      }

      final skhdrc = File('$home/.skhdrc');
      if (await skhdrc.exists()) {
        _skhdContent = await skhdrc.readAsString();
      } else {
        _skhdContent = '# ~/.skhdrc not found';
      }
    } catch (e) {
      _yabaiContent = '# Error loading config: $e';
      _skhdContent = '# Error loading config: $e';
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Raw Config'),
        titleWidth: 200,
        actions: [
          ToolBarIconButton(
            label: 'Reload',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            onPressed: _loadConfigs,
          ),
          ToolBarIconButton(
            label: 'Copy',
            icon: const MacosIcon(CupertinoIcons.doc_on_clipboard),
            showLabel: false,
            onPressed: () {
              final content = _selectedTab == 0 ? _yabaiContent : _skhdContent;
              Clipboard.setData(ClipboardData(text: content));
              // Show feedback
            },
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (_isLoading) {
              return const Center(
                child: ProgressCircle(),
              );
            }

            return Column(
              children: [
                // Tab bar
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PushButton(
                        controlSize: ControlSize.regular,
                        secondary: _selectedTab != 0,
                        onPressed: () {
                          setState(() => _selectedTab = 0);
                          _loadConfigs(); // Reload when switching tabs
                        },
                        child: const Text('.yabairc'),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.regular,
                        secondary: _selectedTab != 1,
                        onPressed: () {
                          setState(() => _selectedTab = 1);
                          _loadConfigs(); // Reload when switching tabs
                        },
                        child: const Text('.skhdrc'),
                      ),
                    ],
                  ),
                ),
                // Config content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF5F5F5),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? const Color(0xFF3D3D3D)
                              : CupertinoColors.systemGrey4,
                        ),
                      ),
                    ),
                    child: Scrollbar(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildSyntaxHighlightedCode(
                            _selectedTab == 0 ? _yabaiContent : _skhdContent,
                            isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSyntaxHighlightedCode(String content, bool isDark) {
    final lines = content.split('\n');

    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'SF Mono, Menlo, Monaco, monospace',
          fontSize: 12,
          height: 1.5,
          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1E1E1E),
        ),
        children: lines.asMap().entries.map((entry) {
          final lineNum = entry.key + 1;
          final line = entry.value;
          return TextSpan(
            children: [
              // Line number
              TextSpan(
                text: '${lineNum.toString().padLeft(3)} │ ',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF999999),
                ),
              ),
              // Syntax highlighted line
              ..._highlightLine(line, isDark),
              const TextSpan(text: '\n'),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<TextSpan> _highlightLine(String line, bool isDark) {
    final spans = <TextSpan>[];
    final trimmed = line.trim();

    // Comment
    if (trimmed.startsWith('#')) {
      spans.add(TextSpan(
        text: line,
        style: TextStyle(
          color: isDark ? const Color(0xFF6A9955) : const Color(0xFF008000),
          fontStyle: FontStyle.italic,
        ),
      ));
      return spans;
    }

    // Shebang
    if (trimmed.startsWith('#!')) {
      spans.add(TextSpan(
        text: line,
        style: TextStyle(
          color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
        ),
      ));
      return spans;
    }

    // yabai command
    if (trimmed.startsWith('yabai')) {
      return _highlightYabaiCommand(line, isDark);
    }

    // skhd shortcut (contains : but not ::)
    if (trimmed.contains(':') && !trimmed.startsWith('::')) {
      return _highlightSkhdShortcut(line, isDark);
    }

    // Default
    spans.add(TextSpan(text: line));
    return spans;
  }

  List<TextSpan> _highlightYabaiCommand(String line, bool isDark) {
    final spans = <TextSpan>[];

    // Pattern: yabai -m config/rule/signal ...
    final pattern = RegExp(
      r'^(\s*)(yabai)(\s+-m\s+)(config|rule|signal)(\s+--?\w+)?(.*)$',
    );
    final match = pattern.firstMatch(line);

    if (match != null) {
      // Leading whitespace
      if (match.group(1)!.isNotEmpty) {
        spans.add(TextSpan(text: match.group(1)));
      }

      // 'yabai' keyword
      spans.add(TextSpan(
        text: match.group(2),
        style: TextStyle(
          color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
          fontWeight: FontWeight.bold,
        ),
      ));

      // '-m'
      spans.add(TextSpan(
        text: match.group(3),
        style: TextStyle(
          color: isDark ? const Color(0xFF9CDCFE) : const Color(0xFF001080),
        ),
      ));

      // 'config/rule/signal'
      spans.add(TextSpan(
        text: match.group(4),
        style: TextStyle(
          color: isDark ? const Color(0xFFDCDCAA) : const Color(0xFF795E26),
          fontWeight: FontWeight.bold,
        ),
      ));

      // '--add' or other flags
      if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: TextStyle(
            color: isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515),
          ),
        ));
      }

      // Rest of the line - highlight values
      if (match.group(6) != null) {
        spans.addAll(_highlightValues(match.group(6)!, isDark));
      }
    } else {
      spans.add(TextSpan(text: line));
    }

    return spans;
  }

  List<TextSpan> _highlightValues(String text, bool isDark) {
    final spans = <TextSpan>[];

    // Match key=value or key="value" patterns
    final pattern = RegExp(r'''(\s*)(\w+)(=)("[^"]*"|'[^']*'|\S+)''');
    var lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add any text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Whitespace
      spans.add(TextSpan(text: match.group(1)));

      // Key
      spans.add(TextSpan(
        text: match.group(2),
        style: TextStyle(
          color: isDark ? const Color(0xFF9CDCFE) : const Color(0xFF001080),
        ),
      ));

      // =
      spans.add(TextSpan(
        text: match.group(3),
        style: TextStyle(
          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000),
        ),
      ));

      // Value
      final value = match.group(4)!;
      Color valueColor;
      if (value.startsWith('"') || value.startsWith("'")) {
        valueColor = isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
      } else if (value == 'on' || value == 'off' || value == 'true' || value == 'false') {
        valueColor = isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF);
      } else if (RegExp(r'^\d+\.?\d*$').hasMatch(value)) {
        valueColor = isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658);
      } else {
        valueColor = isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
      }

      spans.add(TextSpan(
        text: value,
        style: TextStyle(color: valueColor),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  List<TextSpan> _highlightSkhdShortcut(String line, bool isDark) {
    final spans = <TextSpan>[];

    // Pattern: modifiers - key : command
    final colonIndex = line.indexOf(':');
    if (colonIndex > 0) {
      final shortcutPart = line.substring(0, colonIndex);
      final commandPart = line.substring(colonIndex);

      // Highlight modifiers and key
      final modifiers = ['alt', 'cmd', 'ctrl', 'shift', 'fn', 'hyper', 'meh'];
      var remaining = shortcutPart;

      for (final mod in modifiers) {
        if (remaining.contains(mod)) {
          final index = remaining.indexOf(mod);
          if (index > 0) {
            spans.add(TextSpan(text: remaining.substring(0, index)));
          }
          spans.add(TextSpan(
            text: mod,
            style: TextStyle(
              color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
              fontWeight: FontWeight.bold,
            ),
          ));
          remaining = remaining.substring(index + mod.length);
        }
      }

      if (remaining.isNotEmpty) {
        // Highlight the key
        spans.add(TextSpan(
          text: remaining,
          style: TextStyle(
            color: isDark ? const Color(0xFFDCDCAA) : const Color(0xFF795E26),
          ),
        ));
      }

      // Colon
      spans.add(TextSpan(
        text: ':',
        style: TextStyle(
          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000),
          fontWeight: FontWeight.bold,
        ),
      ));

      // Command
      spans.add(TextSpan(
        text: commandPart.substring(1),
        style: TextStyle(
          color: isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515),
        ),
      ));
    } else {
      spans.add(TextSpan(text: line));
    }

    return spans;
  }
}
