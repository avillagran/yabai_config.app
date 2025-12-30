import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Tooltip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/space.dart';
import '../models/exclusion_rule.dart';
import '../providers/config_provider.dart';
import '../providers/exclusions_provider.dart';
import '../providers/spaces_provider.dart';
import '../services/window_thumbnail_service.dart';

/// External bar mode
enum ExternalBarMode {
  off('Off', 'No external bar padding'),
  main('Main Display', 'Apply padding only on main display'),
  all('All Displays', 'Apply padding on all displays');

  final String displayName;
  final String description;
  const ExternalBarMode(this.displayName, this.description);
}

/// Screen for managing Yabai spaces/desktops
class SpacesScreen extends ConsumerStatefulWidget {
  const SpacesScreen({super.key});

  @override
  ConsumerState<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends ConsumerState<SpacesScreen> {
  Timer? _refreshTimer;
  YabaiSpace? _expandedSpace;
  List<YabaiWindow> _expandedSpaceWindows = [];

  @override
  void initState() {
    super.initState();
    // Auto-refresh windows every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(spacesProvider.notifier).refresh();
      // Update expanded space windows if we have one
      if (_expandedSpace != null) {
        final spacesState = ref.read(spacesProvider);
        final updatedSpace = spacesState.spaces.firstWhere(
          (s) => s.index == _expandedSpace!.index,
          orElse: () => _expandedSpace!,
        );
        final windows = spacesState.windowsForSpace(updatedSpace.index);
        if (mounted) {
          setState(() {
            _expandedSpace = updatedSpace;
            _expandedSpaceWindows = windows;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _expandSpace(YabaiSpace space, List<YabaiWindow> windows) {
    setState(() {
      _expandedSpace = space;
      _expandedSpaceWindows = windows;
    });
  }

  void _closeExpandedView() {
    setState(() {
      _expandedSpace = null;
      _expandedSpaceWindows = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacesState = ref.watch(spacesProvider);

    // Show expanded view if a space is expanded
    if (_expandedSpace != null) {
      return _ExpandedSpaceView(
        space: _expandedSpace!,
        windows: _expandedSpaceWindows,
        onClose: _closeExpandedView,
      );
    }

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Spaces'),
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            onPressed: () => ref.read(spacesProvider.notifier).refresh(),
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (spacesState.isLoading && spacesState.spaces.isEmpty) {
              return const Center(
                child: ProgressCircle(),
              );
            }

            if (spacesState.error != null && spacesState.spaces.isEmpty) {
              return _buildErrorView(spacesState.error!);
            }

            if (spacesState.spaces.isEmpty) {
              return _buildEmptyView();
            }

            return _buildSpacesContent(spacesState, scrollController);
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
            'Error Loading Spaces',
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
            onPressed: () => ref.read(spacesProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            CupertinoIcons.square_stack_3d_up,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Spaces Found',
            style: MacosTheme.of(context).typography.title2,
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure Yabai is running and try again.',
            style: MacosTheme.of(context).typography.body,
          ),
          const SizedBox(height: 24),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: () => ref.read(spacesProvider.notifier).refresh(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacesContent(SpacesState state, ScrollController scrollController) {
    final spacesByDisplay = state.spacesByDisplay;
    final displays = state.displays;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // External Bar Section
          _ExternalBarSection(displays: displays),
          const SizedBox(height: 16),

          // Summary row
          _buildSummaryRow(state),
          const SizedBox(height: 16),

          // Displays and their spaces
          if (displays.length > 1) ...[
            for (final display in displays) ...[
              _buildDisplaySection(display, spacesByDisplay[display.index] ?? [], state),
              const SizedBox(height: 16),
            ],
          ] else ...[
            _buildSpacesGrid(state.spaces, state),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(SpacesState state) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey4;

    return Row(
      children: [
        _SummaryCard(
          icon: CupertinoIcons.square_stack_3d_up,
          label: 'spaces',
          value: state.spaces.length.toString(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('·', style: TextStyle(color: dividerColor, fontSize: 16)),
        ),
        _SummaryCard(
          icon: CupertinoIcons.macwindow,
          label: 'windows',
          value: state.windows.length.toString(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('·', style: TextStyle(color: dividerColor, fontSize: 16)),
        ),
        _SummaryCard(
          icon: CupertinoIcons.desktopcomputer,
          label: 'displays',
          value: state.displays.length.toString(),
        ),
      ],
    );
  }

  Widget _buildDisplaySection(
    YabaiDisplay display,
    List<YabaiSpace> spaces,
    SpacesState state,
  ) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MacosIcon(CupertinoIcons.desktopcomputer, size: 14, color: secondaryColor),
            const SizedBox(width: 6),
            Text(
              'Display ${display.index}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondaryColor),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${spaces.length}',
                style: const TextStyle(fontSize: 11, color: CupertinoColors.systemBlue, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildSpacesGrid(spaces, state),
      ],
    );
  }

  Widget _buildSpacesGrid(List<YabaiSpace> spaces, SpacesState state) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: spaces.map((space) {
        final windows = state.windowsForSpace(space.index);
        return _SpaceCard(
          space: space,
          windows: windows,
          onTap: () => _expandSpace(space, windows),
          onEdit: () => _showEditSpaceDialog(space),
        );
      }).toList(),
    );
  }

  void _showEditSpaceDialog(YabaiSpace space) {
    showMacosSheet(
      context: context,
      builder: (context) => _EditSpaceDialog(
        space: space,
        onSave: (label, layout, gap) async {
          final notifier = ref.read(spacesProvider.notifier);
          if (label != null && label.isNotEmpty) {
            await notifier.updateSpaceLabel(space.index, label);
          }
          if (layout != null) {
            await notifier.updateSpaceLayout(space.index, layout);
          }
        },
      ),
    );
  }
}

/// Summary card widget - Compact inline design
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(icon, size: 14, color: CupertinoColors.systemBlue),
        const SizedBox(width: 6),
        Text(
          value,
          style: MacosTheme.of(context).typography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: secondaryColor),
        ),
      ],
    );
  }
}

/// Space card widget - Compact modern design
class _SpaceCard extends StatefulWidget {
  final YabaiSpace space;
  final List<YabaiWindow> windows;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SpaceCard({
    required this.space,
    required this.windows,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends State<_SpaceCard> {
  bool _isPressed = false;
  Map<int, Uint8List> _thumbnails = {};
  List<int>? _lastWindowIds;

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  @override
  void didUpdateWidget(_SpaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if windows changed
    final currentIds = widget.windows.map((w) => w.id).toList();
    if (_lastWindowIds == null || !_listEquals(currentIds, _lastWindowIds!)) {
      _loadThumbnails();
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadThumbnails() async {
    final windowIds = widget.windows
        .where((w) => w.frame != null && !w.isMinimized && w.isVisible)
        .map((w) => w.id)
        .toList();

    _lastWindowIds = windowIds;

    if (windowIds.isEmpty) return;

    final thumbnails = await WindowThumbnailService.instance.captureWindows(windowIds);
    if (mounted && thumbnails.isNotEmpty) {
      setState(() {
        _thumbnails = thumbnails;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final overlayColor = isDark
        ? const Color(0xFF000000).withOpacity(0.7)
        : const Color(0xFFFFFFFF).withOpacity(0.85);
    final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 220,
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.space.hasFocus
                ? CupertinoColors.systemBlue
                : (isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey4),
            width: widget.space.hasFocus ? 2 : 1,
          ),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              // Full background window preview
              Positioned.fill(
                child: _buildFullPreview(context, isDark),
              ),

              // Top overlay with space number and label
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        overlayColor,
                        overlayColor.withOpacity(0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.space.hasFocus
                              ? CupertinoColors.systemBlue
                              : (isDark ? const Color(0xFF3A3A3A) : CupertinoColors.white),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.space.hasFocus
                                ? CupertinoColors.systemBlue
                                : (isDark ? const Color(0xFF555555) : CupertinoColors.systemGrey4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.space.index}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.space.hasFocus
                                  ? CupertinoColors.white
                                  : (isDark ? CupertinoColors.white : CupertinoColors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.space.label?.isNotEmpty == true
                              ? widget.space.label!
                              : 'Space ${widget.space.index}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.space.hasFocus)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGreen.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom overlay with info and edit button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        overlayColor,
                        overlayColor.withOpacity(0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildInfoChip(context, widget.space.layout ?? 'bsp', isDark),
                      const SizedBox(width: 6),
                      _buildInfoChip(context, '${widget.windows.length} win', isDark),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF444444)
                                  : CupertinoColors.systemGrey4,
                            ),
                          ),
                          child: MacosIcon(
                            CupertinoIcons.pencil,
                            size: 14,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1D1D) : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }

  Widget _buildFullPreview(BuildContext context, bool isDark) {
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC);

    // Filter visible windows with frame data
    final visibleWindows = widget.windows.where((w) =>
      w.frame != null && !w.isMinimized && w.isVisible
    ).toList();

    if (visibleWindows.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the bounding box of all windows
    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final window in visibleWindows) {
      final frame = window.frame!;
      if (frame.x < minX) minX = frame.x;
      if (frame.y < minY) minY = frame.y;
      if (frame.x + frame.width > maxX) maxX = frame.x + frame.width;
      if (frame.y + frame.height > maxY) maxY = frame.y + frame.height;
    }

    final totalWidth = maxX - minX;
    final totalHeight = maxY - minY;

    if (totalWidth <= 0 || totalHeight <= 0) {
      return const SizedBox.shrink();
    }

    // Window colors based on app - more vibrant
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemYellow,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = constraints.maxWidth;
        final previewHeight = constraints.maxHeight;

        // Small padding from edges
        final padding = 4.0;
        final availableWidth = previewWidth - padding * 2;
        final availableHeight = previewHeight - padding * 2;

        // Calculate scale to fit all windows
        final scaleX = availableWidth / totalWidth;
        final scaleY = availableHeight / totalHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        // Center the preview
        final scaledWidth = totalWidth * scale;
        final scaledHeight = totalHeight * scale;
        final offsetX = padding + (availableWidth - scaledWidth) / 2;
        final offsetY = padding + (availableHeight - scaledHeight) / 2;

        return Stack(
          children: visibleWindows.asMap().entries.map((entry) {
            final index = entry.key;
            final window = entry.value;
            final frame = window.frame!;
            final color = colors[index % colors.length];

            final left = offsetX + (frame.x - minX) * scale;
            final top = offsetY + (frame.y - minY) * scale;
            final width = frame.width * scale;
            final height = frame.height * scale;

            final thumbnail = _thumbnails[window.id];

            return Positioned(
              left: left,
              top: top,
              width: width.clamp(8.0, previewWidth),
              height: height.clamp(8.0, previewHeight),
              child: Tooltip(
                message: '${window.app}\n${window.title}',
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbnail == null
                        ? (window.hasFocus
                            ? color.withOpacity(0.7)
                            : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5)))
                        : null,
                    border: Border.all(
                      color: window.hasFocus ? color : borderColor,
                      width: window.hasFocus ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: window.hasFocus
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: thumbnail != null
                        ? Image.memory(
                            thumbnail,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : (width > 30 && height > 20
                            ? Center(
                                child: Text(
                                  _getAppInitial(window.app),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: window.hasFocus
                                        ? CupertinoColors.white
                                        : (isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel),
                                  ),
                                ),
                              )
                            : null),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getAppInitial(String appName) {
    if (appName.isEmpty) return '?';
    final shortcuts = {
      'Google Chrome': 'C',
      'Safari': 'S',
      'Firefox': 'F',
      'Code': 'VS',
      'Visual Studio Code': 'VS',
      'Finder': 'F',
      'Terminal': 'T',
      'iTerm2': 'iT',
      'Slack': 'Sl',
      'Discord': 'D',
      'Spotify': 'Sp',
      'Messages': 'M',
      'Mail': 'M',
      'Notes': 'N',
      'Preview': 'P',
      'Xcode': 'X',
    };
    return shortcuts[appName] ?? appName[0].toUpperCase();
  }
}

/// Edit space dialog
class _EditSpaceDialog extends StatefulWidget {
  final YabaiSpace space;
  final Function(String? label, String? layout, int? gap) onSave;

  const _EditSpaceDialog({
    required this.space,
    required this.onSave,
  });

  @override
  State<_EditSpaceDialog> createState() => _EditSpaceDialogState();
}

class _EditSpaceDialogState extends State<_EditSpaceDialog> {
  late TextEditingController _labelController;
  late TextEditingController _gapController;
  String? _selectedLayout;

  final List<String> _layouts = ['none', 'bsp', 'float', 'stack'];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.space.label ?? '');
    _gapController = TextEditingController(
      text: widget.space.gapOverride?.toString() ?? '',
    );
    _selectedLayout = widget.space.layout;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _gapController.dispose();
    super.dispose();
  }

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
              'Edit Space ${widget.space.index}',
              style: MacosTheme.of(context).typography.title1,
            ),
            const SizedBox(height: 24),

            // Label field
            Text(
              'Label',
              style: MacosTheme.of(context).typography.headline,
            ),
            const SizedBox(height: 8),
            MacosTextField(
              controller: _labelController,
              placeholder: 'Enter space label...',
            ),
            const SizedBox(height: 16),

            // Layout override
            Text(
              'Layout Override',
              style: MacosTheme.of(context).typography.headline,
            ),
            const SizedBox(height: 8),
            MacosPopupButton<String>(
              value: _selectedLayout,
              items: [
                const MacosPopupMenuItem(
                  value: null,
                  child: Text('None (use global)'),
                ),
                ..._layouts.map((layout) => MacosPopupMenuItem(
                      value: layout,
                      child: Text(_getLayoutDisplayName(layout)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLayout = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Gap override
            Text(
              'Gap Override (optional)',
              style: MacosTheme.of(context).typography.headline,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: MacosTextField(
                controller: _gapController,
                placeholder: 'Gap in px',
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    final gap = int.tryParse(_gapController.text);
                    widget.onSave(
                      _labelController.text,
                      _selectedLayout,
                      gap,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLayoutDisplayName(String layout) {
    switch (layout) {
      case 'bsp':
        return 'BSP (Binary Space Partition)';
      case 'float':
        return 'Float';
      case 'stack':
        return 'Stack';
      case 'none':
        return 'None';
      default:
        return layout;
    }
  }
}

/// External Bar configuration section - Compact modern design
class _ExternalBarSection extends ConsumerStatefulWidget {
  final List<YabaiDisplay> displays;

  const _ExternalBarSection({required this.displays});

  @override
  ConsumerState<_ExternalBarSection> createState() => _ExternalBarSectionState();
}

class _ExternalBarSectionState extends ConsumerState<_ExternalBarSection> {
  ExternalBarMode _mode = ExternalBarMode.off;
  late TextEditingController _topPaddingController;
  late TextEditingController _bottomPaddingController;
  String? _lastConfigValue;

  @override
  void initState() {
    super.initState();
    _topPaddingController = TextEditingController();
    _bottomPaddingController = TextEditingController();
  }

  @override
  void dispose() {
    _topPaddingController.dispose();
    _bottomPaddingController.dispose();
    super.dispose();
  }

  void _syncFromConfig(String? configValue) {
    // Sync if config value is different from what we have
    // This handles initial load (_lastConfigValue == null) and external changes
    if (configValue != _lastConfigValue) {
      _lastConfigValue = configValue;
      if (configValue != null && configValue.isNotEmpty) {
        _parseConfig(configValue);
      }
    }
  }

  void _parseConfig(String? value) {
    if (value == null || value.isEmpty) {
      _mode = ExternalBarMode.off;
      _topPaddingController.text = '';
      _bottomPaddingController.text = '';
      return;
    }

    final parts = value.split(':');
    if (parts.length >= 3) {
      final modeStr = parts[0].toLowerCase();
      if (modeStr == 'main') {
        _mode = ExternalBarMode.main;
      } else if (modeStr == 'all') {
        _mode = ExternalBarMode.all;
      } else if (modeStr == 'off') {
        _mode = ExternalBarMode.off;
      } else {
        _mode = ExternalBarMode.off;
      }
      _topPaddingController.text = parts[1];
      _bottomPaddingController.text = parts[2];
    } else {
      _mode = ExternalBarMode.off;
    }
  }

  String _buildExternalBarValue() {
    if (_mode == ExternalBarMode.off) {
      return 'off:0:0';
    }
    final top = _topPaddingController.text.isEmpty ? '0' : _topPaddingController.text;
    final bottom = _bottomPaddingController.text.isEmpty ? '0' : _bottomPaddingController.text;
    return '${_mode == ExternalBarMode.main ? 'main' : 'all'}:$top:$bottom';
  }

  void _updateConfig() {
    final value = _buildExternalBarValue();
    _lastConfigValue = value; // Prevent sync from overwriting user changes
    ref.read(yabaiConfigProvider.notifier).updateExternalBar(value);
  }

  @override
  Widget build(BuildContext context) {
    // Watch config and sync when it changes
    final config = ref.watch(yabaiConfigProvider);
    _syncFromConfig(config.externalBar);

    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final borderColor = isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey5;
    final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and title
            MacosIcon(
              CupertinoIcons.rectangle_dock,
              size: 16,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(width: 8),
            Text(
              'External Bar',
              style: MacosTheme.of(context).typography.headline.copyWith(fontSize: 13),
            ),
            const SizedBox(width: 16),

            // Mode selector pills
            _buildModePill(context, ExternalBarMode.off, 'Off', isDark),
            const SizedBox(width: 6),
            _buildModePill(context, ExternalBarMode.main, 'Main', isDark),
            const SizedBox(width: 6),
            _buildModePill(context, ExternalBarMode.all, 'All', isDark),

            // Padding inputs (only when enabled)
            if (_mode != ExternalBarMode.off) ...[
              const SizedBox(width: 20),
              Container(width: 1, height: 24, color: borderColor),
              const SizedBox(width: 16),
              Text('Top', style: TextStyle(fontSize: 11, color: secondaryColor)),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                height: 24,
                child: CupertinoTextField(
                  controller: _topPaddingController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  style: const TextStyle(fontSize: 12),
                  placeholder: '0',
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D1D1D) : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => _updateConfig(),
                ),
              ),
              const SizedBox(width: 12),
              Text('Bottom', style: TextStyle(fontSize: 11, color: secondaryColor)),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                height: 24,
                child: CupertinoTextField(
                  controller: _bottomPaddingController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  style: const TextStyle(fontSize: 12),
                  placeholder: '0',
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D1D1D) : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => _updateConfig(),
                ),
              ),
              const SizedBox(width: 4),
              Text('px', style: TextStyle(fontSize: 11, color: secondaryColor)),
              const SizedBox(width: 20),
              // Mini preview inline
              _buildMiniPreview(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(BuildContext context, ExternalBarMode mode, String label, bool isDark) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _mode = mode);
        _updateConfig();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.systemBlue
              : (isDark ? const Color(0xFF1D1D1D) : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? CupertinoColors.white
                : (isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPreview(BuildContext context, bool isDark) {
    final displays = widget.displays;
    final displayCount = (displays.isEmpty ? 1 : displays.length).clamp(1, 3);
    final topPadding = int.tryParse(_topPaddingController.text) ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(displayCount, (index) {
        final isMainDisplay = index == 0;
        final hasBar = _mode == ExternalBarMode.all ||
            (_mode == ExternalBarMode.main && isMainDisplay);

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1D1D) : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: hasBar
                    ? CupertinoColors.systemGreen
                    : (isDark ? const Color(0xFF444444) : CupertinoColors.systemGrey4),
                width: hasBar ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                if (hasBar && topPadding > 0)
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(1),
                        topRight: Radius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Expanded view for a single space - shows fullscreen within window
class _ExpandedSpaceView extends ConsumerStatefulWidget {
  final YabaiSpace space;
  final List<YabaiWindow> windows;
  final VoidCallback onClose;

  const _ExpandedSpaceView({
    required this.space,
    required this.windows,
    required this.onClose,
  });

  @override
  ConsumerState<_ExpandedSpaceView> createState() => _ExpandedSpaceViewState();
}

class _ExpandedSpaceViewState extends ConsumerState<_ExpandedSpaceView> {
  Map<int, Uint8List> _thumbnails = {};

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  @override
  void didUpdateWidget(_ExpandedSpaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload thumbnails if windows changed
    if (widget.windows.length != oldWidget.windows.length) {
      _loadThumbnails();
    }
  }

  Future<void> _loadThumbnails() async {
    final windowIds = widget.windows
        .where((w) => w.frame != null && !w.isMinimized && w.isVisible)
        .map((w) => w.id)
        .toList();

    if (windowIds.isEmpty) return;

    final thumbnails = await WindowThumbnailService.instance.captureWindows(windowIds);
    if (mounted && thumbnails.isNotEmpty) {
      setState(() {
        _thumbnails = thumbnails;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;
    final borderColor = isDark ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey5;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Header bar
          _buildHeader(context, isDark, cardColor, borderColor),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large window preview (left side - 60%)
                  Expanded(
                    flex: 6,
                    child: _buildLargePreview(context, isDark, cardColor, borderColor),
                  ),
                  const SizedBox(width: 20),
                  // Window list with exclusion buttons (right side - 40%)
                  Expanded(
                    flex: 4,
                    child: _buildWindowList(context, isDark, cardColor, borderColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MacosIcon(
                CupertinoIcons.chevron_left,
                size: 16,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Space number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.space.hasFocus
                  ? CupertinoColors.systemBlue
                  : (isDark ? const Color(0xFF3A3A3A) : CupertinoColors.systemGrey6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.space.hasFocus
                    ? CupertinoColors.systemBlue
                    : borderColor,
              ),
            ),
            child: Center(
              child: Text(
                '${widget.space.index}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.space.hasFocus
                      ? CupertinoColors.white
                      : (isDark ? CupertinoColors.white : CupertinoColors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Space name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.space.label?.isNotEmpty == true
                      ? widget.space.label!
                      : 'Space ${widget.space.index}',
                  style: MacosTheme.of(context).typography.title2,
                ),
                Text(
                  '${widget.windows.length} windows · ${widget.space.layout ?? 'bsp'} layout',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),

          // Focus indicator
          if (widget.space.hasFocus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLargePreview(BuildContext context, bool isDark, Color cardColor, Color borderColor) {
    final visibleWindows = widget.windows.where((w) =>
      w.frame != null && !w.isMinimized && w.isVisible
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MacosIcon(
                  CupertinoIcons.macwindow,
                  size: 16,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Window Layout',
                  style: MacosTheme.of(context).typography.headline,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: visibleWindows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MacosIcon(
                            CupertinoIcons.square_stack_3d_up,
                            size: 48,
                            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No visible windows',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildWindowsPreview(visibleWindows, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsPreview(List<YabaiWindow> visibleWindows, bool isDark) {
    // Find the bounding box of all windows
    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final window in visibleWindows) {
      final frame = window.frame!;
      if (frame.x < minX) minX = frame.x;
      if (frame.y < minY) minY = frame.y;
      if (frame.x + frame.width > maxX) maxX = frame.x + frame.width;
      if (frame.y + frame.height > maxY) maxY = frame.y + frame.height;
    }

    final totalWidth = maxX - minX;
    final totalHeight = maxY - minY;

    if (totalWidth <= 0 || totalHeight <= 0) {
      return const SizedBox.shrink();
    }

    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemYellow,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = constraints.maxWidth;
        final previewHeight = constraints.maxHeight;

        final padding = 16.0;
        final availableWidth = previewWidth - padding * 2;
        final availableHeight = previewHeight - padding * 2;

        final scaleX = availableWidth / totalWidth;
        final scaleY = availableHeight / totalHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        final scaledWidth = totalWidth * scale;
        final scaledHeight = totalHeight * scale;
        final offsetX = padding + (availableWidth - scaledWidth) / 2;
        final offsetY = padding + (availableHeight - scaledHeight) / 2;

        return Stack(
          children: visibleWindows.asMap().entries.map((entry) {
            final index = entry.key;
            final window = entry.value;
            final frame = window.frame!;
            final color = colors[index % colors.length];

            final left = offsetX + (frame.x - minX) * scale;
            final top = offsetY + (frame.y - minY) * scale;
            final width = frame.width * scale;
            final height = frame.height * scale;

            final thumbnail = _thumbnails[window.id];

            return Positioned(
              left: left,
              top: top,
              width: width.clamp(20.0, previewWidth),
              height: height.clamp(20.0, previewHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: thumbnail == null
                      ? (window.hasFocus
                          ? color.withOpacity(0.6)
                          : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5)))
                      : null,
                  border: Border.all(
                    color: window.hasFocus ? color : (isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC)),
                    width: window.hasFocus ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail or placeholder
                      if (thumbnail != null)
                        Image.memory(
                          thumbnail,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      else if (width > 60 && height > 40)
                        Center(
                          child: Text(
                            window.app,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: window.hasFocus
                                  ? CupertinoColors.white
                                  : (isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // App label overlay at bottom
                      if (width > 80 && height > 50)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0),
                                ],
                              ),
                            ),
                            child: Text(
                              window.app,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWindowList(BuildContext context, bool isDark, Color cardColor, Color borderColor) {
    final visibleWindows = widget.windows.where((w) =>
      !w.isMinimized && w.isVisible
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MacosIcon(
                  CupertinoIcons.square_list,
                  size: 16,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Windows',
                  style: MacosTheme.of(context).typography.headline,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${visibleWindows.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleWindows.isEmpty
                ? Center(
                    child: Text(
                      'No windows in this space',
                      style: TextStyle(
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: visibleWindows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final window = visibleWindows[index];
                      return _buildWindowItem(context, window, isDark, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowItem(BuildContext context, YabaiWindow window, bool isDark, int index) {
    // Watch exclusions to get real-time updates
    final exclusions = ref.watch(exclusionsProvider);
    final existingRule = exclusions.cast<ExclusionRule?>().firstWhere(
      (r) => r?.appName == window.app,
      orElse: () => null,
    );
    final isExcluded = existingRule != null;

    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemTeal,
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: window.hasFocus
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        window.app,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (window.hasFocus)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  window.title.isNotEmpty ? window.title : 'Untitled',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Toggle Exclusion button - icon only for compact design
          GestureDetector(
            onTap: () => _toggleExclusion(window.app, isExcluded, existingRule),
            child: Tooltip(
              message: isExcluded ? 'Re-enable management' : 'Exclude from Yabai',
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isExcluded
                      ? CupertinoColors.systemGreen.withOpacity(0.15)
                      : CupertinoColors.systemRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MacosIcon(
                  isExcluded
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  size: 18,
                  color: isExcluded
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExclusion(String appName, bool isExcluded, ExclusionRule? existingRule) {
    if (isExcluded && existingRule != null) {
      // Remove from exclusions (re-enable management)
      ref.read(exclusionsProvider.notifier).deleteRule(existingRule.id);
    } else {
      // Add to exclusions
      final newRule = ExclusionRule(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        appName: appName,
        manageOff: true,
        sticky: false,
        layer: WindowLayer.normal,
      );
      ref.read(exclusionsProvider.notifier).addRule(newRule);
    }
  }
}
