import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/config_enums.dart';
import '../providers/config_provider.dart';

/// General configuration screen for Yabai settings
class GeneralConfigScreen extends ConsumerStatefulWidget {
  const GeneralConfigScreen({super.key});

  @override
  ConsumerState<GeneralConfigScreen> createState() =>
      _GeneralConfigScreenState();
}

class _GeneralConfigScreenState extends ConsumerState<GeneralConfigScreen> {
  bool _hasChanges = false;

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
      ref.read(hasUnsavedChangesProvider.notifier).state = true;
    }
  }

  Future<void> _saveConfig() async {
    ref.read(isSavingProvider.notifier).state = true;
    final success = await ref.read(yabaiConfigProvider.notifier).saveConfig();
    ref.read(isSavingProvider.notifier).state = false;

    if (success) {
      setState(() {
        _hasChanges = false;
      });
      ref.read(hasUnsavedChangesProvider.notifier).state = false;

      if (mounted) {
        // Show success indicator
        showMacosAlertDialog(
          context: context,
          builder: (context) => MacosAlertDialog(
            appIcon: const MacosIcon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.systemGreen,
              size: 56,
            ),
            title: const Text('Configuration Saved'),
            message: const Text(
              'Your Yabai configuration has been saved successfully.',
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        showMacosAlertDialog(
          context: context,
          builder: (context) => MacosAlertDialog(
            appIcon: const MacosIcon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemRed,
              size: 56,
            ),
            title: const Text('Save Failed'),
            message: const Text(
              'Failed to save the configuration. Please check file permissions.',
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(yabaiConfigProvider);
    final layout = ref.watch(layoutProvider);
    final windowPlacement = ref.watch(windowPlacementProvider);
    final mouseFollowsFocus = ref.watch(mouseFollowsFocusProvider);
    final mouseModifier = ref.watch(mouseModifierProvider);
    final mouseAction1 = ref.watch(mouseAction1Provider);
    final mouseAction2 = ref.watch(mouseAction2Provider);
    final mouseDropAction = ref.watch(mouseDropActionProvider);
    final isSaving = ref.watch(isSavingProvider);
    final autoSave = ref.watch(autoSaveEnabledProvider);
    final windowGap = config.windowGap;

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('General Config'),
        titleWidth: 200,
        actions: [
          // Status indicator
          CustomToolbarItem(
            inToolbarBuilder: (context) {
              final hasChanges = ref.watch(hasUnsavedChangesProvider);
              if (!hasChanges && !autoSave) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (hasChanges && autoSave) ...[
                      const CupertinoActivityIndicator(radius: 6),
                      const SizedBox(width: 6),
                      Builder(
                        builder: (context) {
                          final isDark = MacosTheme.of(context).brightness == Brightness.dark;
                          return Text(
                            'Auto-saving...',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ] else if (hasChanges && !autoSave) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Builder(
                        builder: (context) {
                          final isDark = MacosTheme.of(context).brightness == Brightness.dark;
                          return Text(
                            'Unsaved changes',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (!autoSave)
            ToolBarIconButton(
              label: 'Save',
              icon: const MacosIcon(CupertinoIcons.floppy_disk),
              showLabel: true,
              onPressed: isSaving ? null : _saveConfig,
            ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layout Section
                  _buildSectionTitle(context, 'Layout'),
                  const SizedBox(height: 12),
                  _LayoutSelector(
                    selectedLayout: layout,
                    onLayoutChanged: (newLayout) {
                      ref
                          .read(yabaiConfigProvider.notifier)
                          .updateLayout(newLayout);
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Window Gap Section
                  _buildSectionTitle(context, 'Window Gap'),
                  const SizedBox(height: 12),
                  _WindowGapSlider(
                    value: windowGap.toDouble(),
                    onChanged: (value) {
                      ref
                          .read(yabaiConfigProvider.notifier)
                          .updateWindowGap(value.round());
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Window Placement Section
                  _buildSectionTitle(context, 'Window Placement'),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final isDark = MacosTheme.of(context).brightness == Brightness.dark;
                      return Text(
                        'Position of new windows relative to existing windows',
                        style: MacosTheme.of(context).typography.caption1.copyWith(
                              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _WindowPlacementSelector(
                    selectedPlacement: windowPlacement,
                    onChanged: (placement) {
                      ref
                          .read(yabaiConfigProvider.notifier)
                          .updateWindowPlacement(placement);
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Mouse Settings Section
                  _buildSectionTitle(context, 'Mouse Settings'),
                  const SizedBox(height: 12),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        // Mouse Follows Focus
                        _SettingRow(
                          title: 'Mouse Follows Focus',
                          subtitle:
                              'Automatically move mouse to focused window',
                          child: MacosSwitch(
                            value: mouseFollowsFocus,
                            onChanged: (value) {
                              ref
                                  .read(yabaiConfigProvider.notifier)
                                  .updateMouseFollowsFocus(value);
                              _markChanged();
                            },
                          ),
                        ),
                        const _SettingDivider(),

                        // Mouse Modifier
                        _SettingRow(
                          title: 'Modifier Key',
                          subtitle: 'Key to hold for mouse window operations',
                          child: MacosPopupButton<MouseModifier>(
                            value: mouseModifier,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(yabaiConfigProvider.notifier)
                                    .updateMouseModifier(value);
                                _markChanged();
                              }
                            },
                            items: MouseModifier.values
                                .map(
                                  (m) => MacosPopupMenuItem(
                                    value: m,
                                    child: Text(m.displayName),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const _SettingDivider(),

                        // Mouse Action 1
                        _SettingRow(
                          title: 'Left Click Action',
                          subtitle: 'Action when holding modifier + left click',
                          child: MacosPopupButton<MouseAction>(
                            value: mouseAction1,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(yabaiConfigProvider.notifier)
                                    .updateMouseAction1(value);
                                _markChanged();
                              }
                            },
                            items: MouseAction.values
                                .map(
                                  (a) => MacosPopupMenuItem(
                                    value: a,
                                    child: Text(a.displayName),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const _SettingDivider(),

                        // Mouse Action 2
                        _SettingRow(
                          title: 'Right Click Action',
                          subtitle:
                              'Action when holding modifier + right click',
                          child: MacosPopupButton<MouseAction>(
                            value: mouseAction2,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(yabaiConfigProvider.notifier)
                                    .updateMouseAction2(value);
                                _markChanged();
                              }
                            },
                            items: MouseAction.values
                                .map(
                                  (a) => MacosPopupMenuItem(
                                    value: a,
                                    child: Text(a.displayName),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const _SettingDivider(),

                        // Mouse Drop Action
                        _SettingRow(
                          title: 'Drop Action',
                          subtitle:
                              'What happens when dropping window on another',
                          child: MacosPopupButton<MouseDropAction>(
                            value: mouseDropAction,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(yabaiConfigProvider.notifier)
                                    .updateMouseDropAction(value);
                                _markChanged();
                              }
                            },
                            items: MouseDropAction.values
                                .map(
                                  (a) => MacosPopupMenuItem(
                                    value: a,
                                    child: Text(a.displayName),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Auto-save Section
                  _buildSectionTitle(context, 'Auto Settings'),
                  const SizedBox(height: 12),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'Auto-save',
                          subtitle: 'Automatically save changes after 1.5s',
                          child: MacosSwitch(
                            value: autoSave,
                            onChanged: (value) {
                              ref.read(autoSaveEnabledProvider.notifier).state =
                                  value;
                            },
                          ),
                        ),
                        const _SettingDivider(),
                        _SettingRow(
                          title: 'Auto-apply',
                          subtitle: 'Restart yabai after saving to apply changes',
                          child: MacosSwitch(
                            value: ref.watch(autoApplyEnabledProvider),
                            onChanged: (value) {
                              ref.read(autoApplyEnabledProvider.notifier).state =
                                  value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Last save indicator
                  if (ref.watch(lastSaveTimeProvider) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const MacosIcon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.systemGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (context) {
                              final isDark = MacosTheme.of(context).brightness == Brightness.dark;
                              return Text(
                                'Last saved: ${_formatTime(ref.watch(lastSaveTimeProvider)!)}',
                                style: TextStyle(
                                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: MacosTheme.of(context).typography.title2.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Visual layout selector with cards
class _LayoutSelector extends StatelessWidget {
  final YabaiLayout selectedLayout;
  final ValueChanged<YabaiLayout> onLayoutChanged;

  const _LayoutSelector({
    required this.selectedLayout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: YabaiLayout.values.map((layout) {
          final isSelected = layout == selectedLayout;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _LayoutCard(
              layout: layout,
              isSelected: isSelected,
              onTap: () => onLayoutChanged(layout),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual layout card
class _LayoutCard extends StatelessWidget {
  final YabaiLayout layout;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutCard({
    required this.layout,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.systemBlue
                : (isDark
                    ? const Color(0xFF3D3D3D)
                    : CupertinoColors.systemGrey5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? CupertinoColors.systemBlue.withOpacity(0.2)
                  : CupertinoColors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _LayoutPreview(layout: layout),
            const SizedBox(height: 8),
            Text(
              layout.displayName,
              style: MacosTheme.of(context).typography.headline.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? CupertinoColors.systemBlue
                        : MacosTheme.of(context).typography.headline.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout preview visual
class _LayoutPreview extends StatelessWidget {
  final YabaiLayout layout;

  const _LayoutPreview({required this.layout});

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final borderColor =
        isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3;
    final fillColor = CupertinoColors.systemBlue.withOpacity(0.2);

    return Container(
      width: 120,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(6),
      child: _buildPreview(fillColor, borderColor),
    );
  }

  Widget _buildPreview(Color fillColor, Color borderColor) {
    switch (layout) {
      case YabaiLayout.bsp:
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        border: Border.all(color: borderColor, width: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        border: Border.all(color: borderColor, width: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case YabaiLayout.float:
        return Stack(
          children: [
            Positioned(
              left: 8,
              top: 5,
              child: Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 5,
              child: Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      case YabaiLayout.stack:
        return Stack(
          children: [
            Positioned(
              left: 15,
              top: 5,
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.3),
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.5),
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 1,
              top: 11,
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
    }
  }
}

/// Window gap slider with value display
class _WindowGapSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _WindowGapSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: MacosSlider(
              value: value,
              min: 0,
              max: 50,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1D1D1D)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${value.round()}px',
              textAlign: TextAlign.center,
              style: MacosTheme.of(context).typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Window placement segmented control
class _WindowPlacementSelector extends StatelessWidget {
  final WindowPlacement selectedPlacement;
  final ValueChanged<WindowPlacement> onChanged;

  const _WindowPlacementSelector({
    required this.selectedPlacement,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MacosSegmentedControl(
      tabs: WindowPlacement.values
          .map(
            (p) => MacosTab(
              label: p.displayName,
              active: p == selectedPlacement,
            ),
          )
          .toList(),
      controller: MacosTabController(
        initialIndex: selectedPlacement.index,
        length: WindowPlacement.values.length,
      ),
    );
  }
}

/// A setting row with title, subtitle, and control widget
class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MacosTheme.of(context).typography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: MacosTheme.of(context).typography.caption1.copyWith(
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          child,
        ],
      ),
    );
  }
}

/// Divider for settings list
class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey5,
    );
  }
}
