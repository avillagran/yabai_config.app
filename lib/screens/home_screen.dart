import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/service_status.dart';
import '../models/config_enums.dart';
import '../providers/service_provider.dart';
import '../providers/config_provider.dart';

/// Home screen / Dashboard showing service status and quick actions
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceStatus = ref.watch(serviceStatusProvider);
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final layout = ref.watch(layoutProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Dashboard'),
        titleWidth: 200,
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            onPressed: () {
              ref.read(serviceStatusProvider.notifier).checkStatus();
              ref.read(dashboardStatsProvider.notifier).loadStats();
            },
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
                  // Service Status Section
                  _buildSectionTitle(context, 'Service Status'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceStatusCard(
                          title: 'Yabai',
                          status: serviceStatus.yabaiState,
                          version: serviceStatus.yabaiVersion,
                          onRestart: () async {
                            await ref
                                .read(serviceStatusProvider.notifier)
                                .restartYabai();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ServiceStatusCard(
                          title: 'skhd',
                          status: serviceStatus.skhdState,
                          version: serviceStatus.skhdVersion,
                          onRestart: () async {
                            await ref
                                .read(serviceStatusProvider.notifier)
                                .restartSkhd();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () async {
                          await ref
                              .read(serviceStatusProvider.notifier)
                              .startAll();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MacosIcon(
                              CupertinoIcons.play_fill,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text('Start All'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () async {
                          await ref
                              .read(serviceStatusProvider.notifier)
                              .stopAll();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MacosIcon(
                              CupertinoIcons.stop_fill,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text('Stop All'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () async {
                          await ref
                              .read(serviceStatusProvider.notifier)
                              .restartYabai();
                          await ref
                              .read(serviceStatusProvider.notifier)
                              .restartSkhd();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MacosIcon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text('Restart All'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Stats Section
                  _buildSectionTitle(context, 'Quick Stats'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Rules',
                          value: '${dashboardStats.ruleCount}',
                          icon: CupertinoIcons.list_bullet,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Shortcuts',
                          value: '${dashboardStats.shortcutCount}',
                          icon: CupertinoIcons.keyboard,
                          color: CupertinoColors.systemPurple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Signals',
                          value: '${dashboardStats.signalCount}',
                          icon: CupertinoIcons.bolt_fill,
                          color: CupertinoColors.systemOrange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Current Layout Section
                  _buildSectionTitle(context, 'Current Layout'),
                  const SizedBox(height: 12),
                  _LayoutDisplayCard(layout: layout),

                  const SizedBox(height: 32),

                  // Last Backup Section
                  _buildSectionTitle(context, 'Last Backup'),
                  const SizedBox(height: 12),
                  _BackupInfoCard(
                    lastBackup: dashboardStats.lastBackupFormatted,
                    backupPath: dashboardStats.lastBackupPath,
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
}

/// Card showing service status with restart button
class _ServiceStatusCard extends StatelessWidget {
  final String title;
  final ServiceState status;
  final String? version;
  final VoidCallback onRestart;

  const _ServiceStatusCard({
    required this.title,
    required this.status,
    this.version,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D3D3D)
              : CupertinoColors.systemGrey5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIndicator(status: status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: MacosTheme.of(context).typography.headline.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: onRestart,
                child: const MacosIcon(
                  CupertinoIcons.arrow_clockwise,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _getStatusText(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (version != null) ...[
                const SizedBox(width: 12),
                Text(
                  version!,
                  style: MacosTheme.of(context).typography.caption1.copyWith(
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.secondaryLabel,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(ServiceState status) {
    switch (status) {
      case ServiceState.running:
        return 'Running';
      case ServiceState.stopped:
        return 'Stopped';
      case ServiceState.unknown:
        return 'Unknown';
    }
  }

  Color _getStatusColor(ServiceState status) {
    switch (status) {
      case ServiceState.running:
        return CupertinoColors.systemGreen;
      case ServiceState.stopped:
        return CupertinoColors.systemRed;
      case ServiceState.unknown:
        return CupertinoColors.systemGrey;
    }
  }
}

/// Colored status indicator dot
class _StatusIndicator extends StatelessWidget {
  final ServiceState status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ServiceState.running:
        color = CupertinoColors.systemGreen;
        break;
      case ServiceState.stopped:
        color = CupertinoColors.systemRed;
        break;
      case ServiceState.unknown:
        color = CupertinoColors.systemGrey;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Card showing a statistic value
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D3D3D)
              : CupertinoColors.systemGrey5,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MacosIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: MacosTheme.of(context).typography.title1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                title,
                style: MacosTheme.of(context).typography.caption1.copyWith(
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.secondaryLabel,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card displaying current layout with visual representation
class _LayoutDisplayCard extends StatelessWidget {
  final YabaiLayout layout;

  const _LayoutDisplayCard({required this.layout});

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D3D3D)
              : CupertinoColors.systemGrey5,
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
          _LayoutVisual(layout: layout),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                layout.displayName,
                style: MacosTheme.of(context).typography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 300,
                child: Text(
                  layout.description,
                  style: MacosTheme.of(context).typography.caption1.copyWith(
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.secondaryLabel,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Visual representation of layout type
class _LayoutVisual extends StatelessWidget {
  final YabaiLayout layout;

  const _LayoutVisual({required this.layout});

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final borderColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey3;
    final fillColor = CupertinoColors.systemBlue.withOpacity(0.2);

    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(4),
      child: _buildLayoutPreview(fillColor, borderColor),
    );
  }

  Widget _buildLayoutPreview(Color fillColor, Color borderColor) {
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
            const SizedBox(width: 3),
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
                  const SizedBox(height: 3),
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
              left: 5,
              top: 5,
              child: Container(
                width: 35,
                height: 25,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                width: 30,
                height: 20,
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
              left: 8,
              top: 3,
              child: Container(
                width: 55,
                height: 40,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.3),
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 6,
              child: Container(
                width: 55,
                height: 40,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.5),
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 9,
              child: Container(
                width: 55,
                height: 40,
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

/// Card showing last backup information
class _BackupInfoCard extends StatelessWidget {
  final String lastBackup;
  final String? backupPath;

  const _BackupInfoCard({
    required this.lastBackup,
    this.backupPath,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3D3D3D)
              : CupertinoColors.systemGrey5,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const MacosIcon(
              CupertinoIcons.archivebox_fill,
              color: CupertinoColors.systemGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastBackup,
                  style: MacosTheme.of(context).typography.headline.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (backupPath != null)
                  Text(
                    backupPath!,
                    style: MacosTheme.of(context).typography.caption1.copyWith(
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.secondaryLabel,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
