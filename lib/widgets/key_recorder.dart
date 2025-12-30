import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

/// A widget that captures keyboard shortcuts
class KeyRecorder extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onKeyComboChanged;
  final String placeholder;

  const KeyRecorder({
    super.key,
    this.initialValue,
    required this.onKeyComboChanged,
    this.placeholder = 'Click and press keys...',
  });

  @override
  State<KeyRecorder> createState() => _KeyRecorderState();
}

class _KeyRecorderState extends State<KeyRecorder> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isRecording = false;
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final Set<String> _modifiers = {};
  String? _mainKey;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isRecording = _focusNode.hasFocus;
      if (!_isRecording) {
        _pressedKeys.clear();
        _modifiers.clear();
        _mainKey = null;
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      _updateKeyCombo(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  void _updateKeyCombo(LogicalKeyboardKey key) {
    // Check for modifiers
    _modifiers.clear();

    if (HardwareKeyboard.instance.isAltPressed) {
      _modifiers.add('alt');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      _modifiers.add('shift');
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      _modifiers.add('ctrl');
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      _modifiers.add('cmd');
    }

    // Get the main key (non-modifier)
    if (!_isModifierKey(key)) {
      _mainKey = _getKeyLabel(key);
    }

    // Build the combo string
    if (_mainKey != null) {
      final combo = _buildComboString();
      _controller.text = combo;
      widget.onKeyComboChanged(combo);
    }

    setState(() {});
  }

  bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  String _getKeyLabel(LogicalKeyboardKey key) {
    // Handle special keys
    final specialKeys = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.space: 'space',
      LogicalKeyboardKey.enter: 'return',
      LogicalKeyboardKey.escape: 'escape',
      LogicalKeyboardKey.tab: 'tab',
      LogicalKeyboardKey.backspace: 'backspace',
      LogicalKeyboardKey.delete: 'delete',
      LogicalKeyboardKey.arrowUp: 'up',
      LogicalKeyboardKey.arrowDown: 'down',
      LogicalKeyboardKey.arrowLeft: 'left',
      LogicalKeyboardKey.arrowRight: 'right',
      LogicalKeyboardKey.home: 'home',
      LogicalKeyboardKey.end: 'end',
      LogicalKeyboardKey.pageUp: 'pageup',
      LogicalKeyboardKey.pageDown: 'pagedown',
      LogicalKeyboardKey.f1: 'f1',
      LogicalKeyboardKey.f2: 'f2',
      LogicalKeyboardKey.f3: 'f3',
      LogicalKeyboardKey.f4: 'f4',
      LogicalKeyboardKey.f5: 'f5',
      LogicalKeyboardKey.f6: 'f6',
      LogicalKeyboardKey.f7: 'f7',
      LogicalKeyboardKey.f8: 'f8',
      LogicalKeyboardKey.f9: 'f9',
      LogicalKeyboardKey.f10: 'f10',
      LogicalKeyboardKey.f11: 'f11',
      LogicalKeyboardKey.f12: 'f12',
    };

    if (specialKeys.containsKey(key)) {
      return specialKeys[key]!;
    }

    // For regular keys, use the key label
    final label = key.keyLabel;
    if (label.isNotEmpty) {
      return label.toLowerCase();
    }

    return '';
  }

  String _buildComboString() {
    final parts = <String>[];

    // Add modifiers in consistent order
    if (_modifiers.contains('ctrl')) parts.add('ctrl');
    if (_modifiers.contains('alt')) parts.add('alt');
    if (_modifiers.contains('shift')) parts.add('shift');
    if (_modifiers.contains('cmd')) parts.add('cmd');

    // Add main key
    if (_mainKey != null && _mainKey!.isNotEmpty) {
      // Use skhd format: modifiers + " - " + key
      if (parts.isNotEmpty) {
        return '${parts.join(' + ')} - $_mainKey';
      }
      return _mainKey!;
    }

    return parts.join(' + ');
  }

  void _clear() {
    _controller.clear();
    _modifiers.clear();
    _mainKey = null;
    _pressedKeys.clear();
    widget.onKeyComboChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isRecording
                ? MacosColors.controlAccentColor.withOpacity(0.1)
                : MacosColors.textBackgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isRecording
                  ? MacosColors.controlAccentColor
                  : MacosColors.separatorColor,
              width: _isRecording ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _controller.text.isEmpty
                      ? (_isRecording ? 'Recording...' : widget.placeholder)
                      : _controller.text,
                  style: TextStyle(
                    color: _controller.text.isEmpty
                        ? MacosColors.placeholderTextColor
                        : MacosColors.textColor,
                    fontSize: 13,
                    fontFamily: 'SF Mono',
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                MacosIconButton(
                  icon: const MacosIcon(
                    CupertinoIcons.clear_circled_solid,
                    size: 16,
                    color: MacosColors.systemGrayColor,
                  ),
                  onPressed: _clear,
                  padding: EdgeInsets.zero,
                  boxConstraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                ),
              const SizedBox(width: 4),
              MacosIcon(
                _isRecording
                    ? CupertinoIcons.keyboard
                    : CupertinoIcons.keyboard_chevron_compact_down,
                size: 16,
                color: _isRecording
                    ? MacosColors.controlAccentColor
                    : MacosColors.systemGrayColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact key badge widget to display individual keys
class KeyBadge extends StatelessWidget {
  final String keyLabel;

  const KeyBadge({
    super.key,
    required this.keyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MacosColors.systemGrayColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: MacosColors.systemGrayColor.withOpacity(0.4),
        ),
      ),
      child: Text(
        keyLabel,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'SF Mono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Widget to display a formatted key combination
class KeyComboDisplay extends StatelessWidget {
  final String keyCombo;
  final double fontSize;

  const KeyComboDisplay({
    super.key,
    required this.keyCombo,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (keyCombo.isEmpty) {
      return const Text(
        'No shortcut',
        style: TextStyle(
          color: MacosColors.placeholderTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Parse the key combo
    final parts = keyCombo.split(' ');
    final widgets = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part == '+' || part == '-') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            part,
            style: TextStyle(
              color: MacosColors.systemGrayColor,
              fontSize: fontSize,
            ),
          ),
        ));
      } else if (part.isNotEmpty) {
        widgets.add(_buildKeyBadge(part));
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }

  Widget _buildKeyBadge(String key) {
    // Map key names to symbols
    final symbols = <String, String>{
      'cmd': '\u2318',
      'alt': '\u2325',
      'ctrl': '\u2303',
      'shift': '\u21E7',
      'return': '\u23CE',
      'tab': '\u21E5',
      'escape': '\u238B',
      'space': '\u2423',
      'backspace': '\u232B',
      'delete': '\u2326',
      'up': '\u2191',
      'down': '\u2193',
      'left': '\u2190',
      'right': '\u2192',
    };

    final displayText = symbols[key.toLowerCase()] ?? key.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MacosColors.systemGrayColor.withOpacity(0.1),
            MacosColors.systemGrayColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: MacosColors.systemGrayColor.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'SF Mono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
