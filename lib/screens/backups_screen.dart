import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/backup_info.dart';
import '../providers/backups_provider.dart';
import '../services/backup_service.dart';
import '../widgets/status_indicator.dart';

/// Screen for managing configuration backups
class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  int _selectedTab = 0;
  late MacosTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = MacosTabController(initialIndex: _selectedTab, length: 3);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _selectedTab = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupsState = ref.watch(backupsProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Backups'),
        actions: [
          ToolBarIconButton(
            label: 'Create Backup',
            icon: const MacosIcon(CupertinoIcons.plus),
            showLabel: false,
            onPressed: () => _showCreateBackupDialog(),
          ),
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            onPressed: () => ref.read(backupsProvider.notifier).refresh(),
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (backupsState.isLoading && backupsState.totalCount == 0) {
              return const Center(
                child: ProgressCircle(),
              );
            }

            if (backupsState.error != null && backupsState.totalCount == 0) {
              return _buildErrorView(backupsState.error!);
            }

            return _buildBackupsContent(backupsState, scrollController);
          },
        ),
      ],
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Backups',
            style: MacosTheme.of(context).typography.title2,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: MacosTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: () => ref.read(backupsProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsContent(BackupsState state, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          _buildSummaryRow(state),
          const SizedBox(height: 24),

          // Tabs for filtering
          _buildTabs(state),
          const SizedBox(height: 16),

          // Backups list or empty state
          if (_getFilteredBackups(state).isEmpty)
            _buildEmptyView()
          else
            ..._getFilteredBackups(state).map((backup) => _BackupCard(
                  backup: backup,
                  onView: () => _showBackupPreview(backup),
                  onCompare: () => _showCompareDialog(backup),
                  onRestore: () => _confirmRestoreBackup(backup),
                  onDelete: () => _confirmDeleteBackup(backup),
                )),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BackupsState state) {
    return Row(
      children: [
        _SummaryCard(
          icon: CupertinoIcons.archivebox,
          label: 'Total Backups',
          value: state.totalCount.toString(),
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: CupertinoIcons.doc_text,
          label: 'Yabai Backups',
          value: state.yabaiBackups.length.toString(),
          color: CupertinoColors.systemBlue,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: CupertinoIcons.keyboard,
          label: 'SKHD Backups',
          value: state.skhdBackups.length.toString(),
          color: CupertinoColors.systemPurple,
        ),
      ],
    );
  }

  Widget _buildTabs(BackupsState state) {
    return MacosSegmentedControl(
      controller: _tabController,
      tabs: [
        MacosTab(
          label: 'All (${state.totalCount})',
          active: _selectedTab == 0,
        ),
        MacosTab(
          label: 'Yabai (${state.yabaiBackups.length})',
          active: _selectedTab == 1,
        ),
        MacosTab(
          label: 'SKHD (${state.skhdBackups.length})',
          active: _selectedTab == 2,
        ),
      ],
    );
  }

  List<BackupInfo> _getFilteredBackups(BackupsState state) {
    switch (_selectedTab) {
      case 1:
        return state.yabaiBackups;
      case 2:
        return state.skhdBackups;
      default:
        return state.allBackups;
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MacosIcon(
              CupertinoIcons.archivebox,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Backups Found',
              style: MacosTheme.of(context).typography.title2,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a backup to preserve your configuration.',
              style: MacosTheme.of(context).typography.body,
            ),
            const SizedBox(height: 24),
            PushButton(
              controlSize: ControlSize.large,
              onPressed: () => _showCreateBackupDialog(),
              child: const Text('Create Backup'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBackupDialog() {
    showMacosSheet(
      context: context,
      builder: (context) => _CreateBackupDialog(
        onCreateYabai: () async {
          final success = await ref.read(backupsProvider.notifier).createYabaiBackup();
          if (success && mounted) {
            Navigator.of(context).pop();
            _showSuccessMessage('Yabai backup created successfully');
          }
        },
        onCreateSkhd: () async {
          final success = await ref.read(backupsProvider.notifier).createSkhdBackup();
          if (success && mounted) {
            Navigator.of(context).pop();
            _showSuccessMessage('SKHD backup created successfully');
          }
        },
      ),
    );
  }

  void _showBackupPreview(BackupInfo backup) async {
    final content = await ref.read(backupsProvider.notifier).getBackupContent(backup);

    if (!mounted) return;

    showMacosSheet(
      context: context,
      builder: (context) => _BackupPreviewDialog(
        backup: backup,
        content: content ?? 'Unable to load backup content',
      ),
    );
  }

  void _showCompareDialog(BackupInfo backup) async {
    await ref.read(backupsProvider.notifier).compareWithCurrent(backup);

    if (!mounted) return;

    final state = ref.read(backupsProvider);
    if (state.currentDiff != null) {
      showMacosSheet(
        context: context,
        builder: (context) => _DiffViewDialog(
          backup: backup,
          diff: state.currentDiff!,
        ),
      );
    }
  }

  void _confirmRestoreBackup(BackupInfo backup) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.arrow_counterclockwise,
          size: 56,
          color: CupertinoColors.systemOrange,
        ),
        title: const Text('Restore Backup'),
        message: Text(
          'Are you sure you want to restore this backup from ${backup.relativeTime}?\n\n'
          'A backup of your current configuration will be created before restoring.',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await ref.read(backupsProvider.notifier).restoreBackup(backup);
            if (success && mounted) {
              _showSuccessMessage('Backup restored successfully');
            }
          },
          child: const Text('Restore'),
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

  void _confirmDeleteBackup(BackupInfo backup) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 56,
          color: CupertinoColors.systemRed,
        ),
        title: const Text('Delete Backup'),
        message: Text(
          'Are you sure you want to delete this backup from ${backup.relativeTime}?\n\n'
          'This action cannot be undone.',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await ref.read(backupsProvider.notifier).deleteBackup(backup);
            if (success && mounted) {
              _showSuccessMessage('Backup deleted');
            }
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

  void _showSuccessMessage(String message) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.checkmark_circle,
          size: 56,
          color: CupertinoColors.systemGreen,
        ),
        title: const Text('Success'),
        message: Text(message),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ),
    );
  }
}

/// Summary card widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final secondaryTextColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(icon, size: 24, color: color ?? CupertinoColors.systemBlue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: MacosTheme.of(context).typography.title2,
              ),
              Text(
                label,
                style: MacosTheme.of(context).typography.caption1.copyWith(
                      color: secondaryTextColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Backup card widget
class _BackupCard extends StatelessWidget {
  final BackupInfo backup;
  final VoidCallback onView;
  final VoidCallback onCompare;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupCard({
    required this.backup,
    required this.onView,
    required this.onCompare,
    required this.onRestore,
    required this.onDelete,
  });

  bool get isYabai => backup.originalPath.contains('yabairc');

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final secondaryTextColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;
    final tertiaryTextColor = isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isYabai ? CupertinoColors.systemBlue : CupertinoColors.systemPurple)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: MacosIcon(
                isYabai ? CupertinoIcons.doc_text : CupertinoIcons.keyboard,
                size: 24,
                color: isYabai ? CupertinoColors.systemBlue : CupertinoColors.systemPurple,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Backup info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isYabai ? '.yabairc' : '.skhdrc',
                      style: MacosTheme.of(context).typography.headline,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      status: isYabai ? StatusType.running : StatusType.warning,
                      label: isYabai ? 'Yabai' : 'SKHD',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MacosIcon(
                      CupertinoIcons.clock,
                      size: 12,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      backup.relativeTime,
                      style: MacosTheme.of(context).typography.caption1.copyWith(
                            color: secondaryTextColor,
                          ),
                    ),
                    const SizedBox(width: 16),
                    MacosIcon(
                      CupertinoIcons.doc,
                      size: 12,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      backup.sizeString,
                      style: MacosTheme.of(context).typography.caption1.copyWith(
                            color: secondaryTextColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  backup.timestampString,
                  style: MacosTheme.of(context).typography.caption2.copyWith(
                        color: tertiaryTextColor,
                      ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.eye,
                  size: 16,
                  color: CupertinoColors.systemBlue,
                ),
                onPressed: onView,
              ),
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.arrow_right_arrow_left,
                  size: 16,
                  color: CupertinoColors.systemIndigo,
                ),
                onPressed: onCompare,
              ),
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.arrow_counterclockwise,
                  size: 16,
                  color: CupertinoColors.systemOrange,
                ),
                onPressed: onRestore,
              ),
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.trash,
                  size: 16,
                  color: CupertinoColors.systemRed,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Create backup dialog
class _CreateBackupDialog extends StatelessWidget {
  final Future<void> Function() onCreateYabai;
  final Future<void> Function() onCreateSkhd;

  const _CreateBackupDialog({
    required this.onCreateYabai,
    required this.onCreateSkhd,
  });

  @override
  Widget build(BuildContext context) {
    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Backup',
              style: MacosTheme.of(context).typography.title1,
            ),
            const SizedBox(height: 8),
            Text(
              'Select which configuration file to backup:',
              style: MacosTheme.of(context).typography.body,
            ),
            const SizedBox(height: 24),

            // Yabai option
            _BackupOptionCard(
              icon: CupertinoIcons.doc_text,
              title: '.yabairc',
              subtitle: 'Yabai window manager configuration',
              color: CupertinoColors.systemBlue,
              onTap: onCreateYabai,
            ),
            const SizedBox(height: 12),

            // SKHD option
            _BackupOptionCard(
              icon: CupertinoIcons.keyboard,
              title: '.skhdrc',
              subtitle: 'SKHD hotkey daemon configuration',
              color: CupertinoColors.systemPurple,
              onTap: onCreateSkhd,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Backup option card
class _BackupOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Future<void> Function() onTap;

  const _BackupOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final secondaryTextColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: MacosTheme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: MacosIcon(icon, size: 24, color: color),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  Text(
                    subtitle,
                    style: MacosTheme.of(context).typography.caption1.copyWith(
                          color: secondaryTextColor,
                        ),
                  ),
                ],
              ),
            ),
            MacosIcon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Backup preview dialog
class _BackupPreviewDialog extends StatelessWidget {
  final BackupInfo backup;
  final String content;

  const _BackupPreviewDialog({
    required this.backup,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;

    return MacosSheet(
      child: SizedBox(
        width: 700,
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Backup Preview',
                    style: MacosTheme.of(context).typography.title1,
                  ),
                  const Spacer(),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.xmark, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${backup.originalFileName} - ${backup.timestampString}',
                style: MacosTheme.of(context).typography.body.copyWith(
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: MacosTheme.of(context).typography.body.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diff view dialog
class _DiffViewDialog extends StatelessWidget {
  final BackupInfo backup;
  final BackupDiff diff;

  const _DiffViewDialog({
    required this.backup,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final diffLines = diff.getLineDiff();

    return MacosSheet(
      child: SizedBox(
        width: 800,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Compare with Current',
                    style: MacosTheme.of(context).typography.title1,
                  ),
                  const Spacer(),
                  if (diff.identical)
                    const StatusBadge(
                      status: StatusType.running,
                      label: 'Identical',
                    )
                  else
                    const StatusBadge(
                      status: StatusType.warning,
                      label: 'Different',
                    ),
                  const SizedBox(width: 8),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.xmark, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Backup: ${backup.relativeTime}',
                style: MacosTheme.of(context).typography.body.copyWith(
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
                    ),
              ),
              const SizedBox(height: 16),

              // Legend
              Row(
                children: [
                  _DiffLegend(color: CupertinoColors.systemGreen, label: 'Added (in current)'),
                  const SizedBox(width: 16),
                  _DiffLegend(color: CupertinoColors.systemRed, label: 'Removed (was in backup)'),
                  const SizedBox(width: 16),
                  _DiffLegend(
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                    label: 'Unchanged',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: diffLines.map((line) => _DiffLineWidget(line: line)).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diff legend widget
class _DiffLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DiffLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: MacosTheme.of(context).typography.caption1,
        ),
      ],
    );
  }
}

/// Diff line widget
class _DiffLineWidget extends StatelessWidget {
  final DiffLine line;

  const _DiffLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String prefix;

    switch (line.type) {
      case DiffType.added:
        backgroundColor = CupertinoColors.systemGreen.withOpacity(0.2);
        prefix = '+ ';
        break;
      case DiffType.removed:
        backgroundColor = CupertinoColors.systemRed.withOpacity(0.2);
        prefix = '- ';
        break;
      case DiffType.unchanged:
        backgroundColor = const Color(0x00000000);
        prefix = '  ';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Text(
        '$prefix${line.content}',
        style: MacosTheme.of(context).typography.body.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
      ),
    );
  }
}
