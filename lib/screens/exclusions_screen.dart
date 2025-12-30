import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/exclusion_rule.dart';
import '../providers/exclusions_provider.dart';
import '../widgets/app_picker.dart';

/// Screen for managing window exclusion rules
class ExclusionsScreen extends ConsumerWidget {
  const ExclusionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(exclusionsProvider);
    final enabledCount = ref.watch(enabledExclusionsCountProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Window Rules'),
        titleWidth: 200,
        actions: [
          ToolBarIconButton(
            label: 'Add Rule',
            icon: const MacosIcon(CupertinoIcons.add_circled),
            showLabel: true,
            onPressed: () => _showAddRuleSheet(context, ref),
          ),
          ToolBarIconButton(
            label: 'Reset',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: true,
            onPressed: () => _showResetConfirmation(context, ref),
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (rules.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const MacosIcon(
                      CupertinoIcons.square_stack_3d_up,
                      size: 64,
                      color: MacosColors.systemGrayColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Window Rules',
                      style: MacosTheme.of(context).typography.title2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add rules to exclude apps from window management\nor customize their behavior.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MacosColors.systemGrayColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () => _showAddRuleSheet(context, ref),
                      child: const Text('Add First Rule'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildHeader(context, rules.length, enabledCount),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: rules.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _RuleCard(
                        rule: rules[index],
                        onToggle: () => ref
                            .read(exclusionsProvider.notifier)
                            .toggleRule(rules[index].id),
                        onEdit: () =>
                            _showEditRuleSheet(context, ref, rules[index]),
                        onDelete: () =>
                            _showDeleteConfirmation(context, ref, rules[index]),
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

  Widget _buildHeader(BuildContext context, int total, int enabled) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final secondaryLabelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final tertiaryLabelColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final controlBgColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.systemBackground.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: controlBgColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: separatorColor,
          ),
        ),
      ),
      child: Row(
        children: [
          MacosIcon(
            CupertinoIcons.info_circle,
            size: 16,
            color: CupertinoColors.activeBlue.resolveFrom(context),
          ),
          const SizedBox(width: 8),
          Text(
            '$total rules ($enabled enabled)',
            style: TextStyle(
              fontSize: 12,
              color: secondaryLabelColor,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              'Rules are applied in order from top to bottom',
              style: TextStyle(
                fontSize: 12,
                color: tertiaryLabelColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref) {
    showMacosSheet(
      context: context,
      builder: (context) => ExclusionRuleSheet(
        onSave: (rule) {
          ref.read(exclusionsProvider.notifier).addRule(rule);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditRuleSheet(
      BuildContext context, WidgetRef ref, ExclusionRule rule) {
    showMacosSheet(
      context: context,
      builder: (context) => ExclusionRuleSheet(
        rule: rule,
        onSave: (updatedRule) {
          ref.read(exclusionsProvider.notifier).updateRule(updatedRule);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, ExclusionRule rule) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 56,
          color: MacosColors.systemRedColor,
        ),
        title: const Text('Delete Rule'),
        message: Text('Are you sure you want to delete the rule for "${rule.appName}"?'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemRedColor,
          onPressed: () {
            ref.read(exclusionsProvider.notifier).deleteRule(rule.id);
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

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.refresh,
          size: 56,
          color: MacosColors.systemOrangeColor,
        ),
        title: const Text('Reset to Defaults'),
        message: const Text(
            'This will replace all your rules with the default set. This action cannot be undone.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemOrangeColor,
          onPressed: () {
            ref.read(exclusionsProvider.notifier).resetToDefaults();
            Navigator.of(context).pop();
          },
          child: const Text('Reset'),
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
}

/// Card widget for displaying a single exclusion rule
class _RuleCard extends StatelessWidget {
  final ExclusionRule rule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final controlBgColor = isDark
        ? const Color(0xFF2D2D2D)
        : CupertinoColors.white;
    final separatorColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.systemGrey4;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final disabledTextColor = CupertinoColors.systemGrey;
    final secondaryLabelColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel.resolveFrom(context);
    final systemRedColor = CupertinoColors.systemRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rule.isEnabled
            ? controlBgColor
            : controlBgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: separatorColor),
      ),
      child: Row(
        children: [
          // Checkbox
          MacosCheckbox(
            value: rule.isEnabled,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 12),
          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.appName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: rule.isEnabled ? textColor : disabledTextColor,
                  ),
                ),
                if (rule.titlePattern != null && rule.titlePattern!.isNotEmpty)
                  Text(
                    'Title: ${rule.titlePattern}',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryLabelColor,
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (rule.manageOff) _buildBadge(context, 'manage=off', CupertinoIcons.nosign),
                    if (rule.sticky) _buildBadge(context, 'sticky', CupertinoIcons.pin),
                    if (rule.layer != WindowLayer.normal)
                      _buildBadge(context, 'layer=${rule.layer.name}', CupertinoIcons.layers),
                    if (rule.assignedSpace != null)
                      _buildBadge(context, 'space=${rule.assignedSpace}', CupertinoIcons.square_grid_2x2),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          MacosIconButton(
            icon: const MacosIcon(CupertinoIcons.pencil, size: 14),
            onPressed: onEdit,
          ),
          MacosIconButton(
            icon: MacosIcon(CupertinoIcons.trash, size: 14, color: systemRedColor),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final systemGrayColor = CupertinoColors.systemGrey.resolveFrom(context);
    final secondaryLabelColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: systemGrayColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            size: 12,
            color: secondaryLabelColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'SF Mono',
              color: secondaryLabelColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet for adding or editing an exclusion rule
class ExclusionRuleSheet extends StatefulWidget {
  final ExclusionRule? rule;
  final ValueChanged<ExclusionRule> onSave;

  const ExclusionRuleSheet({
    super.key,
    this.rule,
    required this.onSave,
  });

  @override
  State<ExclusionRuleSheet> createState() => _ExclusionRuleSheetState();
}

class _ExclusionRuleSheetState extends State<ExclusionRuleSheet> {
  late final TextEditingController _appNameController;
  late final TextEditingController _titlePatternController;
  late final TextEditingController _spaceController;

  late bool _manageOff;
  late bool _sticky;
  late WindowLayer _layer;
  bool _hasSpace = false;

  bool get isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController(text: widget.rule?.appName ?? '');
    _titlePatternController =
        TextEditingController(text: widget.rule?.titlePattern ?? '');
    _spaceController = TextEditingController(
        text: widget.rule?.assignedSpace?.toString() ?? '');
    _manageOff = widget.rule?.manageOff ?? true;
    _sticky = widget.rule?.sticky ?? false;
    _layer = widget.rule?.layer ?? WindowLayer.normal;
    _hasSpace = widget.rule?.assignedSpace != null;

    // Listen for changes to enable/disable save button
    _appNameController.addListener(_onAppNameChanged);
  }

  void _onAppNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _appNameController.removeListener(_onAppNameChanged);
    _appNameController.dispose();
    _titlePatternController.dispose();
    _spaceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_appNameController.text.isEmpty) {
      return;
    }

    final rule = ExclusionRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      appName: _appNameController.text,
      titlePattern: _titlePatternController.text.isEmpty
          ? null
          : _titlePatternController.text,
      manageOff: _manageOff,
      sticky: _sticky,
      layer: _layer,
      assignedSpace:
          _hasSpace ? int.tryParse(_spaceController.text) : null,
      isEnabled: widget.rule?.isEnabled ?? true,
    );

    widget.onSave(rule);
  }

  @override
  Widget build(BuildContext context) {
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
                    isEditing ? CupertinoIcons.pencil : CupertinoIcons.add,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Rule' : 'Add Rule',
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

              // App Name
              _buildLabel(context, 'Application Name'),
            const SizedBox(height: 8),
            AppPicker(
              selectedApp: _appNameController.text.isEmpty
                  ? null
                  : _appNameController.text,
              onAppSelected: (app) {
                setState(() {
                  _appNameController.text = app;
                });
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: MacosTextField(
                    controller: _appNameController,
                    placeholder: 'Or type app name manually...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Pattern
            _buildLabel(context, 'Title Pattern (regex, optional)'),
            const SizedBox(height: 8),
            MacosTextField(
              controller: _titlePatternController,
              placeholder: 'e.g., (Preferences|Settings)',
            ),
            const SizedBox(height: 16),

            // Options
            _buildLabel(context, 'Options'),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
                final textBgColor = isDark
                    ? const Color(0xFF2D2D2D)
                    : CupertinoColors.systemBackground.resolveFrom(context);
                final separatorColor = CupertinoColors.separator.resolveFrom(context);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: textBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: separatorColor),
                  ),
              child: Column(
                children: [
                  _buildCheckboxRow(
                    'Manage Off',
                    'Exclude from window management',
                    _manageOff,
                    (value) => setState(() => _manageOff = value),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckboxRow(
                    'Sticky',
                    'Window visible on all spaces',
                    _sticky,
                    (value) => setState(() => _sticky = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Layer:'),
                      const SizedBox(width: 12),
                      MacosPopupButton<WindowLayer>(
                        value: _layer,
                        items: WindowLayer.values.map((layer) {
                          return MacosPopupMenuItem(
                            value: layer,
                            child: Text(layer.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _layer = value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
              },
            ),
            const SizedBox(height: 16),

            // Space Assignment
            _buildLabel(context, 'Space Assignment (optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                MacosCheckbox(
                  value: _hasSpace,
                  onChanged: (value) {
                    setState(() {
                      _hasSpace = value;
                      if (!value) {
                        _spaceController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Assign to space'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: MacosTextField(
                    controller: _spaceController,
                    enabled: _hasSpace,
                    placeholder: '1-9',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
                  onPressed: _appNameController.text.isNotEmpty ? _save : null,
                  child: Text(isEditing ? 'Save' : 'Add Rule'),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final textColor = CupertinoColors.label.resolveFrom(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  Widget _buildCheckboxRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Builder(
      builder: (context) {
        final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
        final secondaryLabelColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel.resolveFrom(context);
        return Row(
          children: [
            MacosCheckbox(
              value: value,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryLabelColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
