import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/shortcut.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// An inline editor for a single keyboard shortcut.
///
/// Provides:
/// - Key combination display with modifier badges
/// - Inline editing for quick changes
/// - Action preview with validation
/// - Category and description editing
class ShortcutEditor extends StatefulWidget {
  /// The shortcut to edit
  final Shortcut shortcut;

  /// Called when the shortcut is modified
  final ValueChanged<Shortcut>? onChanged;

  /// Called when the shortcut should be deleted
  final VoidCallback? onDelete;

  /// Called when editing is complete
  final VoidCallback? onEditingComplete;

  /// Whether the editor is in read-only mode
  final bool readOnly;

  /// Whether to show the delete button
  final bool showDelete;

  /// Whether to show the category selector
  final bool showCategory;

  /// Whether to show the description field
  final bool showDescription;

  /// Whether to start in edit mode
  final bool initialEditMode;

  /// Compact display mode
  final bool compact;

  const ShortcutEditor({
    super.key,
    required this.shortcut,
    this.onChanged,
    this.onDelete,
    this.onEditingComplete,
    this.readOnly = false,
    this.showDelete = true,
    this.showCategory = true,
    this.showDescription = true,
    this.initialEditMode = false,
    this.compact = false,
  });

  @override
  State<ShortcutEditor> createState() => _ShortcutEditorState();
}

class _ShortcutEditorState extends State<ShortcutEditor> {
  late bool _isEditing;
  late List<String> _modifiers;
  late String _key;
  late String _action;
  late String? _category;
  late String? _description;
  late bool _enabled;

  late TextEditingController _keyController;
  late TextEditingController _actionController;
  late TextEditingController _descriptionController;

  final FocusNode _keyFocusNode = FocusNode();
  final FocusNode _actionFocusNode = FocusNode();

  String? _keyError;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
    _initFromShortcut(widget.shortcut);

    _keyController = TextEditingController(text: _key);
    _actionController = TextEditingController(text: _action);
    _descriptionController = TextEditingController(text: _description ?? '');
  }

  void _initFromShortcut(Shortcut shortcut) {
    _modifiers = List.from(shortcut.modifiers);
    _key = shortcut.key;
    _action = shortcut.action;
    _category = shortcut.category;
    _description = shortcut.description;
    _enabled = shortcut.enabled;
  }

  @override
  void didUpdateWidget(ShortcutEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shortcut != oldWidget.shortcut) {
      _initFromShortcut(widget.shortcut);
      _keyController.text = _key;
      _actionController.text = _action;
      _descriptionController.text = _description ?? '';
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _actionController.dispose();
    _descriptionController.dispose();
    _keyFocusNode.dispose();
    _actionFocusNode.dispose();
    super.dispose();
  }

  void _toggleModifier(String modifier) {
    setState(() {
      if (_modifiers.contains(modifier)) {
        _modifiers.remove(modifier);
      } else {
        _modifiers.add(modifier);
      }
      _notifyChange();
    });
  }

  void _validateKey(String value) {
    setState(() {
      _key = value.toLowerCase().trim();
      _keyError = Validators.shortcutKey(_key);
    });
  }

  void _validateAction(String value) {
    setState(() {
      _action = value.trim();
      _actionError = Validators.validateYabaiCommand(_action);
    });
  }

  void _notifyChange() {
    if (widget.onChanged == null) return;

    final newShortcut = Shortcut(
      modifiers: _modifiers,
      key: _key,
      action: _action,
      category: _category,
      description: _description,
      enabled: _enabled,
    );

    widget.onChanged!(newShortcut);
  }

  void _saveChanges() {
    _validateKey(_key);
    _validateAction(_action);

    if (_keyError != null || _actionError != null) {
      return;
    }

    _description = _descriptionController.text.trim();
    if (_description?.isEmpty ?? true) {
      _description = null;
    }

    _notifyChange();

    setState(() {
      _isEditing = false;
    });

    widget.onEditingComplete?.call();
  }

  void _cancelEdit() {
    _initFromShortcut(widget.shortcut);
    _keyController.text = _key;
    _actionController.text = _action;
    _descriptionController.text = _description ?? '';

    setState(() {
      _isEditing = false;
      _keyError = null;
      _actionError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    final isDark = macosTheme.brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF2A2A2A)
        : CupertinoColors.tertiarySystemBackground.resolveFrom(context);

    final borderColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.separator.resolveFrom(context);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: widget.compact
          ? _buildCompactLayout(macosTheme)
          : _buildFullLayout(macosTheme),
    );
  }

  Widget _buildCompactLayout(MacosThemeData macosTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Enable/disable toggle
          MacosSwitch(
            value: _enabled,
            onChanged: widget.readOnly
                ? null
                : (value) {
                    setState(() {
                      _enabled = value;
                      _notifyChange();
                    });
                  },
          ),
          const SizedBox(width: 12),

          // Hotkey display
          _buildHotkeyBadge(macosTheme),
          const SizedBox(width: 12),

          // Action preview
          Expanded(
            child: _isEditing
                ? _buildActionInput(macosTheme)
                : _buildActionPreview(macosTheme),
          ),

          // Actions
          if (!widget.readOnly) ...[
            const SizedBox(width: 8),
            if (_isEditing) ...[
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.checkmark,
                  size: 16,
                  color: CupertinoColors.systemGreen,
                ),
                onPressed: _saveChanges,
              ),
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.xmark,
                  size: 16,
                  color: CupertinoColors.systemRed,
                ),
                onPressed: _cancelEdit,
              ),
            ] else ...[
              MacosIconButton(
                icon: MacosIcon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: macosTheme.primaryColor,
                ),
                onPressed: () => setState(() => _isEditing = true),
              ),
              if (widget.showDelete)
                MacosIconButton(
                  icon: const MacosIcon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: CupertinoColors.systemRed,
                  ),
                  onPressed: widget.onDelete,
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFullLayout(MacosThemeData macosTheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with enable toggle and actions
          Row(
            children: [
              MacosSwitch(
                value: _enabled,
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        setState(() {
                          _enabled = value;
                          _notifyChange();
                        });
                      },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _description ?? 'Keyboard shortcut',
                  style: macosTheme.typography.body.copyWith(
                    color: _enabled
                        ? null
                        : MacosColors.tertiaryLabelColor,
                  ),
                ),
              ),
              if (!widget.readOnly) ...[
                if (_isEditing) ...[
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: true,
                    onPressed: _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  PushButton(
                    controlSize: ControlSize.small,
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
                ] else ...[
                  MacosIconButton(
                    icon: MacosIcon(
                      CupertinoIcons.pencil,
                      size: 18,
                      color: macosTheme.primaryColor,
                    ),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                  if (widget.showDelete)
                    MacosIconButton(
                      icon: const MacosIcon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed: widget.onDelete,
                    ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Hotkey section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modifiers
              if (_isEditing)
                _buildModifierEditor(macosTheme)
              else
                _buildHotkeyBadge(macosTheme),
              const SizedBox(width: 12),

              // Key input
              if (_isEditing) ...[
                SizedBox(
                  width: 80,
                  child: _buildKeyInput(macosTheme),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Action section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Action',
                style: macosTheme.typography.caption1.copyWith(
                  color: MacosColors.secondaryLabelColor,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing)
                _buildActionInput(macosTheme)
              else
                _buildActionPreview(macosTheme),
            ],
          ),

          // Category and description (editing mode)
          if (_isEditing && widget.showCategory) ...[
            const SizedBox(height: 12),
            _buildCategorySelector(macosTheme),
          ],

          if (_isEditing && widget.showDescription) ...[
            const SizedBox(height: 12),
            _buildDescriptionInput(macosTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildHotkeyBadge(MacosThemeData macosTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._modifiers.map((mod) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _ModifierBadge(
                modifier: mod,
                active: true,
                enabled: _enabled,
              ),
            )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _enabled
                ? macosTheme.primaryColor.withOpacity(0.15)
                : MacosColors.tertiaryLabelColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _enabled
                  ? macosTheme.primaryColor.withOpacity(0.3)
                  : MacosColors.tertiaryLabelColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            _formatKeyDisplay(_key),
            style: macosTheme.typography.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _enabled ? null : MacosColors.tertiaryLabelColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModifierEditor(MacosThemeData macosTheme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: SkhdModifiers.all.map((mod) {
        final isActive = _modifiers.contains(mod);
        return GestureDetector(
          onTap: () => _toggleModifier(mod),
          child: _ModifierBadge(
            modifier: mod,
            active: isActive,
            enabled: _enabled,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyInput(MacosThemeData macosTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MacosTextField(
          controller: _keyController,
          focusNode: _keyFocusNode,
          placeholder: 'Key',
          maxLength: 20,
          onChanged: _validateKey,
          onSubmitted: (_) => _actionFocusNode.requestFocus(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
        ),
        if (_keyError != null) ...[
          const SizedBox(height: 4),
          Text(
            _keyError!,
            style: macosTheme.typography.caption2.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionInput(MacosThemeData macosTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MacosTextField(
          controller: _actionController,
          focusNode: _actionFocusNode,
          placeholder: 'yabai -m window --focus west',
          maxLines: widget.compact ? 1 : 2,
          onChanged: _validateAction,
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 4),
          Text(
            _actionError!,
            style: macosTheme.typography.caption2.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionPreview(MacosThemeData macosTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: MacosColors.tertiaryLabelColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _action,
        style: macosTheme.typography.body.copyWith(
          fontFamily: 'SF Mono',
          fontSize: 12,
          color: _enabled ? null : MacosColors.tertiaryLabelColor,
        ),
        maxLines: widget.compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCategorySelector(MacosThemeData macosTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: macosTheme.typography.caption1.copyWith(
            color: MacosColors.secondaryLabelColor,
          ),
        ),
        const SizedBox(height: 4),
        MacosPopupButton<String>(
          value: _category ?? ShortcutCategory.custom,
          items: ShortcutCategory.all
              .map((cat) => MacosPopupMenuItem(
                    value: cat,
                    child: Text(ShortcutCategory.displayNames[cat] ?? cat),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(MacosThemeData macosTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optional)',
          style: macosTheme.typography.caption1.copyWith(
            color: MacosColors.secondaryLabelColor,
          ),
        ),
        const SizedBox(height: 4),
        MacosTextField(
          controller: _descriptionController,
          placeholder: 'What does this shortcut do?',
          maxLength: 100,
        ),
      ],
    );
  }

  String _formatKeyDisplay(String key) {
    switch (key.toLowerCase()) {
      case 'left':
        return '\u2190';
      case 'right':
        return '\u2192';
      case 'up':
        return '\u2191';
      case 'down':
        return '\u2193';
      case 'space':
        return 'Space';
      case 'tab':
        return '\u21E5';
      case 'return':
        return '\u23CE';
      case 'escape':
        return '\u238B';
      case 'delete':
        return '\u232B';
      default:
        return key.toUpperCase();
    }
  }
}

/// A badge displaying a modifier key
class _ModifierBadge extends StatelessWidget {
  final String modifier;
  final bool active;
  final bool enabled;

  const _ModifierBadge({
    required this.modifier,
    required this.active,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    final isDark = macosTheme.brightness == Brightness.dark;

    final symbol = SkhdModifiers.symbols[modifier] ?? modifier;

    final activeColor = enabled
        ? macosTheme.primaryColor
        : MacosColors.tertiaryLabelColor;

    final inactiveColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.systemGrey5.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.15) : inactiveColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? activeColor.withOpacity(0.5) : Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Text(
        symbol,
        style: macosTheme.typography.caption1.copyWith(
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          color: active
              ? (enabled ? null : MacosColors.tertiaryLabelColor)
              : MacosColors.tertiaryLabelColor,
        ),
      ),
    );
  }
}

/// A simple hotkey display widget (non-editable)
class HotkeyDisplay extends StatelessWidget {
  final List<String> modifiers;
  final String triggerKey;
  final bool enabled;
  final double fontSize;

  const HotkeyDisplay({
    super.key,
    required this.modifiers,
    required this.triggerKey,
    this.enabled = true,
    this.fontSize = 13,
  });

  factory HotkeyDisplay.fromShortcut(Shortcut shortcut) {
    return HotkeyDisplay(
      modifiers: shortcut.modifiers,
      triggerKey: shortcut.key,
      enabled: shortcut.enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...modifiers.map((mod) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                SkhdModifiers.symbols[mod] ?? mod,
                style: macosTheme.typography.body.copyWith(
                  fontSize: fontSize,
                  color: enabled ? null : MacosColors.tertiaryLabelColor,
                ),
              ),
            )),
        Text(
          _formatKeyDisplay(triggerKey),
          style: macosTheme.typography.body.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: enabled ? null : MacosColors.tertiaryLabelColor,
          ),
        ),
      ],
    );
  }

  String _formatKeyDisplay(String keyValue) {
    switch (keyValue.toLowerCase()) {
      case 'left':
        return '\u2190';
      case 'right':
        return '\u2192';
      case 'up':
        return '\u2191';
      case 'down':
        return '\u2193';
      case 'space':
        return 'Space';
      case 'tab':
        return '\u21E5';
      case 'return':
        return '\u23CE';
      case 'escape':
        return '\u238B';
      case 'delete':
        return '\u232B';
      default:
        return keyValue.toUpperCase();
    }
  }
}
