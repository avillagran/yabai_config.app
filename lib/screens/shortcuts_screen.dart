import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/keyboard_shortcut.dart';
import '../providers/shortcuts_provider.dart';
import '../widgets/key_recorder.dart';

/// Screen for managing skhd keyboard shortcuts
class ShortcutsScreen extends ConsumerWidget {
  const ShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutsByCategory = ref.watch(shortcutsByCategoryProvider);
    final shortcuts = ref.watch(shortcutsProvider);
    final conflicts = ref.watch(shortcutConflictsProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Keyboard Shortcuts'),
        titleWidth: 200,
        actions: [
          ToolBarIconButton(
            label: 'Add',
            icon: const MacosIcon(CupertinoIcons.add_circled),
            showLabel: true,
            onPressed: () => _showAddShortcutSheet(context, ref),
          ),
          ToolBarIconButton(
            label: 'Load Presets',
            icon: const MacosIcon(CupertinoIcons.sparkles),
            showLabel: true,
            onPressed: () => _showPresetsDialog(context, ref),
          ),
          ToolBarIconButton(
            label: 'Clear All',
            icon: const MacosIcon(CupertinoIcons.trash),
            showLabel: true,
            onPressed: shortcuts.isEmpty
                ? null
                : () => _showClearAllConfirmation(context, ref),
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (shortcuts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const MacosIcon(
                      CupertinoIcons.keyboard,
                      size: 64,
                      color: MacosColors.systemGrayColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Shortcuts Configured',
                      style: MacosTheme.of(context).typography.title2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add custom shortcuts or load the vim-style preset\nto get started with Yabai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MacosColors.systemGrayColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PushButton(
                          controlSize: ControlSize.large,
                          secondary: true,
                          onPressed: () => _showAddShortcutSheet(context, ref),
                          child: const Text('Add Shortcut'),
                        ),
                        const SizedBox(width: 12),
                        PushButton(
                          controlSize: ControlSize.large,
                          onPressed: () {
                            ref.read(shortcutsProvider.notifier).loadPreset();
                          },
                          child: const Text('Load Vim Presets'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (conflicts.isNotEmpty) _buildConflictsWarning(conflicts),
                _buildHeader(context, shortcuts.length,
                    shortcuts.where((s) => s.isEnabled).length),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: ShortcutCategory.values.length,
                    itemBuilder: (context, index) {
                      final category = ShortcutCategory.values[index];
                      final categoryShortcuts =
                          shortcutsByCategory[category] ?? [];

                      if (categoryShortcuts.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _CategorySection(
                        category: category,
                        shortcuts: categoryShortcuts,
                        onToggle: (id) => ref
                            .read(shortcutsProvider.notifier)
                            .toggleShortcut(id),
                        onEdit: (shortcut) =>
                            _showEditShortcutSheet(context, ref, shortcut),
                        onDelete: (shortcut) =>
                            _showDeleteConfirmation(context, ref, shortcut),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConflictsWarning(List<String> conflicts) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      decoration: BoxDecoration(
        color: MacosColors.systemYellowColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacosColors.systemYellowColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 20,
            color: MacosColors.systemYellowColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conflicting Shortcuts Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The following key combinations are used more than once: ${conflicts.join(", ")}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MacosColors.secondaryLabelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total, int enabled) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey4;
    final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;
    final tertiaryColor = isDark ? CupertinoColors.systemGrey2 : CupertinoColors.tertiaryLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          const MacosIcon(
            CupertinoIcons.keyboard,
            size: 16,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(width: 8),
          Text(
            '$total shortcuts ($enabled enabled)',
            style: TextStyle(
              fontSize: 12,
              color: secondaryColor,
            ),
          ),
          const Spacer(),
          Text(
            'Shortcuts are managed by skhd',
            style: TextStyle(
              fontSize: 12,
              color: tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShortcutSheet(BuildContext context, WidgetRef ref) {
    showMacosSheet(
      context: context,
      builder: (context) => ShortcutSheet(
        onSave: (shortcut) {
          ref.read(shortcutsProvider.notifier).addShortcut(shortcut);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditShortcutSheet(
      BuildContext context, WidgetRef ref, KeyboardShortcut shortcut) {
    showMacosSheet(
      context: context,
      builder: (context) => ShortcutSheet(
        shortcut: shortcut,
        onSave: (updatedShortcut) {
          ref.read(shortcutsProvider.notifier).updateShortcut(updatedShortcut);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, KeyboardShortcut shortcut) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 56,
          color: MacosColors.systemRedColor,
        ),
        title: const Text('Delete Shortcut'),
        message: Text(
            'Are you sure you want to delete the shortcut "${shortcut.keyCombo}"?'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemRedColor,
          onPressed: () {
            ref.read(shortcutsProvider.notifier).deleteShortcut(shortcut.id);
            Navigator.of(context).pop();
          },
          child: const Text('Delete'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 56,
          color: MacosColors.systemRedColor,
        ),
        title: const Text('Clear All Shortcuts'),
        message: const Text(
            'This will remove all your keyboard shortcuts. This action cannot be undone.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemRedColor,
          onPressed: () {
            ref.read(shortcutsProvider.notifier).clearAll();
            Navigator.of(context).pop();
          },
          child: const Text('Clear All'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPresetsDialog(BuildContext context, WidgetRef ref) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.sparkles,
          size: 56,
          color: MacosColors.systemPurpleColor,
        ),
        title: const Text('Load Preset Shortcuts'),
        message: const Text(
            'This will load the vim-style preset shortcuts. You can either merge them with your existing shortcuts or replace all.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () {
            ref.read(shortcutsProvider.notifier).loadPreset();
            Navigator.of(context).pop();
          },
          child: const Text('Merge'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemOrangeColor,
          onPressed: () {
            ref.read(shortcutsProvider.notifier).replaceWithPreset();
            Navigator.of(context).pop();
          },
          child: const Text('Replace All'),
        ),
      ),
    );
  }
}

/// Section widget for a category of shortcuts
class _CategorySection extends StatelessWidget {
  final ShortcutCategory category;
  final List<KeyboardShortcut> shortcuts;
  final ValueChanged<String> onToggle;
  final ValueChanged<KeyboardShortcut> onEdit;
  final ValueChanged<KeyboardShortcut> onDelete;

  const _CategorySection({
    required this.category,
    required this.shortcuts,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final borderColor = isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Row(
            children: [
              MacosIcon(
                _getCategoryIcon(),
                size: 18,
                color: MacosColors.controlAccentColor,
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: MacosTheme.of(context).typography.title3,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3D3D3D)
                      : CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${shortcuts.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < shortcuts.length; i++) ...[
                _ShortcutTile(
                  shortcut: shortcuts[i],
                  onToggle: () => onToggle(shortcuts[i].id),
                  onEdit: () => onEdit(shortcuts[i]),
                  onDelete: () => onDelete(shortcuts[i]),
                ),
                if (i < shortcuts.length - 1)
                  const Divider(height: 1, indent: 52),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case ShortcutCategory.focus:
        return CupertinoIcons.viewfinder;
      case ShortcutCategory.move:
        return CupertinoIcons.arrow_right_arrow_left;
      case ShortcutCategory.resize:
        return CupertinoIcons.resize;
      case ShortcutCategory.layout:
        return CupertinoIcons.square_grid_2x2;
      case ShortcutCategory.spaces:
        return CupertinoIcons.square_stack_3d_up;
      case ShortcutCategory.custom:
        return CupertinoIcons.star;
    }
  }
}

/// Tile widget for displaying a single shortcut
class _ShortcutTile extends StatelessWidget {
  final KeyboardShortcut shortcut;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShortcutTile({
    required this.shortcut,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.secondaryLabel;
    final disabledColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.tertiaryLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: KeyComboDisplay(keyCombo: shortcut.keyCombo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: shortcut.isEnabled ? textColor : disabledColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shortcut.action,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'SF Mono',
                    color: shortcut.isEnabled ? secondaryColor : disabledColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          MacosSwitch(
            value: shortcut.isEnabled,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 8),
          MacosIconButton(
            icon: const MacosIcon(
              CupertinoIcons.pencil,
              size: 16,
            ),
            onPressed: onEdit,
          ),
          MacosIconButton(
            icon: const MacosIcon(
              CupertinoIcons.trash,
              size: 16,
              color: MacosColors.systemRedColor,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Sheet for adding or editing a shortcut
class ShortcutSheet extends StatefulWidget {
  final KeyboardShortcut? shortcut;
  final ValueChanged<KeyboardShortcut> onSave;

  const ShortcutSheet({
    super.key,
    this.shortcut,
    required this.onSave,
  });

  @override
  State<ShortcutSheet> createState() => _ShortcutSheetState();
}

class _ShortcutSheetState extends State<ShortcutSheet> {
  late String _keyCombo;
  late ShortcutCategory _category;
  late String _selectedAction;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customCommandController;

  bool _useCustomCommand = false;

  bool get isEditing => widget.shortcut != null;

  @override
  void initState() {
    super.initState();
    _keyCombo = widget.shortcut?.keyCombo ?? '';
    _category = widget.shortcut?.category ?? ShortcutCategory.focus;
    _selectedAction = widget.shortcut?.action ?? '';
    _descriptionController =
        TextEditingController(text: widget.shortcut?.description ?? '');
    _customCommandController = TextEditingController(
        text: widget.shortcut?.action ?? '');

    // Check if it's a custom command
    final commands = YabaiCommands.allCommands;
    _useCustomCommand = widget.shortcut != null &&
        !commands.containsKey(widget.shortcut!.action);

    if (!_useCustomCommand && widget.shortcut != null) {
      _selectedAction = widget.shortcut!.action;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customCommandController.dispose();
    super.dispose();
  }

  void _save() {
    if (_keyCombo.isEmpty) return;

    // Use edited command if available, otherwise fall back to selected action
    final action = _customCommandController.text.isNotEmpty
        ? _customCommandController.text
        : _selectedAction;
    if (action.isEmpty) return;

    String description = _descriptionController.text;
    if (description.isEmpty) {
      description =
          _useCustomCommand ? 'Custom action' : (YabaiCommands.allCommands[action] ?? 'Action');
    }

    final shortcut = KeyboardShortcut(
      id: widget.shortcut?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      keyCombo: _keyCombo,
      action: action,
      description: description,
      category: _category,
      isEnabled: widget.shortcut?.isEnabled ?? true,
    );

    widget.onSave(shortcut);
  }

  @override
  Widget build(BuildContext context) {
    final categoryCommands = YabaiCommands.commandsForCategory(_category);

    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                MacosIcon(
                  isEditing
                      ? CupertinoIcons.pencil
                      : CupertinoIcons.keyboard_chevron_compact_down,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Shortcut' : 'Add Shortcut',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Recorder
            _buildLabel('Key Combination'),
            const SizedBox(height: 8),
            KeyRecorder(
              initialValue: _keyCombo,
              onKeyComboChanged: (combo) {
                setState(() {
                  _keyCombo = combo;
                });
              },
            ),
            const SizedBox(height: 16),

            // Category
            _buildLabel('Category'),
            const SizedBox(height: 8),
            MacosPopupButton<ShortcutCategory>(
              value: _category,
              items: ShortcutCategory.values.map((category) {
                return MacosPopupMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                    _selectedAction = '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Action
            _buildLabel('Action'),
            const SizedBox(height: 8),
            Row(
              children: [
                MacosCheckbox(
                  value: _useCustomCommand,
                  onChanged: (value) {
                    setState(() {
                      _useCustomCommand = value;
                      if (!value) {
                        _selectedAction = '';
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Use custom command'),
              ],
            ),
            const SizedBox(height: 8),
            if (_useCustomCommand)
              MacosTextField(
                controller: _customCommandController,
                placeholder: 'yabai -m window --focus west',
                maxLines: 2,
              )
            else if (categoryCommands.isNotEmpty)
              Builder(
                builder: (context) {
                  final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
                  final subtitleColor = isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.secondaryLabel;
                  final bgColor = isDark
                      ? const Color(0xFF2D2D2D)
                      : CupertinoColors.systemBackground.resolveFrom(context);
                  final borderColor = isDark
                      ? const Color(0xFF3D3D3D)
                      : CupertinoColors.separator.resolveFrom(context);

                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    height: 150,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: categoryCommands.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (context, index) {
                        final command = categoryCommands.keys.elementAt(index);
                        final description = categoryCommands[command]!;
                        final isSelected = _selectedAction == command;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAction = command;
                              _customCommandController.text = command;
                              if (_descriptionController.text.isEmpty) {
                                _descriptionController.text = description;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            color: isSelected
                                ? MacosColors.controlAccentColor.withOpacity(0.15)
                                : null,
                            child: Row(
                              children: [
                                if (isSelected)
                                  const MacosIcon(
                                    CupertinoIcons.checkmark,
                                    size: 14,
                                    color: MacosColors.controlAccentColor,
                                  )
                                else
                                  const SizedBox(width: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        command,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'SF Mono',
                                          color: subtitleColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            else
              Builder(
                builder: (context) {
                  final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
                  final bgColor = isDark
                      ? const Color(0xFF2D2D2D)
                      : CupertinoColors.systemBackground.resolveFrom(context);
                  final borderColor = isDark
                      ? const Color(0xFF3D3D3D)
                      : CupertinoColors.separator.resolveFrom(context);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Center(
                      child: Text(
                        'No predefined commands for this category.\nEnable "Use custom command" to enter your own.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MacosColors.systemGrayColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Command editor (when action is selected)
            if (!_useCustomCommand && _selectedAction.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildLabel('Edit Command'),
              const SizedBox(height: 8),
              MacosTextField(
                controller: _customCommandController,
                placeholder: 'Edit command parameters...',
                style: const TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Description
            _buildLabel('Description'),
            const SizedBox(height: 8),
            MacosTextField(
              controller: _descriptionController,
              placeholder: 'What does this shortcut do?',
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: _keyCombo.isNotEmpty &&
                          ((_useCustomCommand &&
                                  _customCommandController.text.isNotEmpty) ||
                              (!_useCustomCommand && _selectedAction.isNotEmpty))
                      ? _save
                      : null,
                  child: Text(isEditing ? 'Save' : 'Add Shortcut'),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
