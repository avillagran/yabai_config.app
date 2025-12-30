import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/signal.dart';
import '../providers/signals_provider.dart';
import '../widgets/status_indicator.dart';

/// Screen for managing Yabai signals
class SignalsScreen extends ConsumerStatefulWidget {
  const SignalsScreen({super.key});

  @override
  ConsumerState<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends ConsumerState<SignalsScreen> {
  @override
  Widget build(BuildContext context) {
    final signalsState = ref.watch(signalsProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Signals'),
        actions: [
          ToolBarIconButton(
            label: 'Add Signal',
            icon: const MacosIcon(CupertinoIcons.plus),
            showLabel: false,
            onPressed: () => _showSignalDialog(null),
          ),
          ToolBarIconButton(
            label: 'Export',
            icon: const MacosIcon(CupertinoIcons.doc_on_clipboard),
            showLabel: false,
            onPressed: () => _exportSignals(),
          ),
          ToolBarIconButton(
            label: 'Reload from file',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            onPressed: () => ref.read(signalsProvider.notifier).refresh(),
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (signalsState.isLoading && signalsState.signals.isEmpty) {
              return const Center(
                child: ProgressCircle(),
              );
            }

            if (signalsState.error != null && signalsState.signals.isEmpty) {
              return _buildErrorView(signalsState.error!);
            }

            if (signalsState.signals.isEmpty) {
              return _buildEmptyView();
            }

            return _buildSignalsContent(signalsState, scrollController);
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
            'Error Loading Signals',
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
            onPressed: () => ref.read(signalsProvider.notifier).refresh(),
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
            CupertinoIcons.bolt,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Signals Configured',
            style: MacosTheme.of(context).typography.title2,
          ),
          const SizedBox(height: 8),
          Text(
            'Signals allow yabai to react to window manager events.',
            style: MacosTheme.of(context).typography.body,
          ),
          const SizedBox(height: 24),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: () => _showSignalDialog(null),
            child: const Text('Add Signal'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsContent(SignalsState state, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          _buildSummaryRow(state),
          const SizedBox(height: 24),

          // Signals list
          Text(
            'Configured Signals',
            style: MacosTheme.of(context).typography.title3,
          ),
          const SizedBox(height: 16),

          // Group by event type
          ...YabaiSignal.validEvents.where((eventType) {
            return state.signals.any((s) => s.event == eventType);
          }).map((eventType) {
            final signals = state.signals.where((s) => s.event == eventType).toList();
            return _buildEventSection(eventType, signals);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(SignalsState state) {
    return Row(
      children: [
        _SummaryCard(
          icon: CupertinoIcons.bolt,
          label: 'Total Signals',
          value: state.signals.length.toString(),
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: CupertinoIcons.checkmark_circle,
          label: 'Enabled',
          value: state.enabledCount.toString(),
          color: CupertinoColors.systemGreen,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: CupertinoIcons.xmark_circle,
          label: 'Disabled',
          value: (state.signals.length - state.enabledCount).toString(),
          color: CupertinoColors.systemGrey,
        ),
      ],
    );
  }

  Widget _buildEventSection(String eventType, List<YabaiSignal> signals) {
    final displayName = _getEventDisplayName(eventType);
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A3A3C) : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              MacosIcon(_getEventIcon(eventType), size: 16),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: MacosTheme.of(context).typography.headline,
              ),
              const Spacer(),
              Text(
                '${signals.length} signal${signals.length == 1 ? '' : 's'}',
                style: MacosTheme.of(context).typography.caption1.copyWith(
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...signals.map((signal) => _SignalCard(
              signal: signal,
              onEdit: () => _showSignalDialog(signal),
              onDelete: () => _confirmDeleteSignal(signal),
              onToggle: () => ref.read(signalsProvider.notifier).toggleSignal(signal.id),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getEventDisplayName(String eventType) {
    return eventType.split('_').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.startsWith('application')) {
      return CupertinoIcons.app;
    } else if (eventType.startsWith('window')) {
      return CupertinoIcons.macwindow;
    } else if (eventType.startsWith('space')) {
      return CupertinoIcons.square_stack_3d_up;
    } else if (eventType.startsWith('display')) {
      return CupertinoIcons.desktopcomputer;
    } else if (eventType.startsWith('mission_control')) {
      return CupertinoIcons.squares_below_rectangle;
    } else if (eventType.startsWith('dock')) {
      return CupertinoIcons.rectangle_dock;
    } else if (eventType.startsWith('menu_bar')) {
      return CupertinoIcons.rectangle_on_rectangle;
    } else if (eventType.startsWith('system')) {
      return CupertinoIcons.power;
    }
    return CupertinoIcons.bolt;
  }

  void _showSignalDialog(YabaiSignal? signal) {
    showMacosSheet(
      context: context,
      builder: (context) => _SignalDialog(
        signal: signal,
        onSave: (newSignal) {
          if (signal == null) {
            ref.read(signalsProvider.notifier).addSignal(newSignal);
          } else {
            ref.read(signalsProvider.notifier).updateSignal(newSignal);
          }
        },
      ),
    );
  }

  void _confirmDeleteSignal(YabaiSignal signal) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 56,
          color: CupertinoColors.systemRed,
        ),
        title: const Text('Delete Signal'),
        message: Text(
          'Are you sure you want to delete the signal "${signal.label ?? signal.eventDisplayName}"?',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () {
            ref.read(signalsProvider.notifier).deleteSignal(signal.id);
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

  void _exportSignals() {
    final config = ref.read(signalsProvider.notifier).generateConfig();
    Clipboard.setData(ClipboardData(text: config));

    // Show confirmation
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.doc_on_clipboard,
          size: 56,
          color: CupertinoColors.systemGreen,
        ),
        title: const Text('Signals Exported'),
        message: const Text(
          'The signal configuration has been copied to your clipboard. '
          'You can paste it into your .yabairc file.',
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
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Signal card widget
class _SignalCard extends StatelessWidget {
  final YabaiSignal signal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _SignalCard({
    required this.signal,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : CupertinoColors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: signal.enabled ? backgroundColor : backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: signal.enabled
              ? MacosTheme.of(context).dividerColor
              : MacosTheme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (signal.label != null && signal.label!.isNotEmpty)
                          Text(
                            signal.label!,
                            style: MacosTheme.of(context).typography.headline,
                          )
                        else
                          Text(
                            signal.eventDisplayName,
                            style: MacosTheme.of(context).typography.headline,
                          ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          status: signal.enabled ? StatusType.running : StatusType.stopped,
                          label: signal.enabled ? 'Enabled' : 'Disabled',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        signal.action,
                        style: MacosTheme.of(context).typography.body.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      signal.eventDescription,
                      style: MacosTheme.of(context).typography.caption1.copyWith(
                            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  MacosSwitch(
                    value: signal.enabled,
                    onChanged: (_) => onToggle(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MacosIconButton(
                        icon: const MacosIcon(CupertinoIcons.pencil, size: 16),
                        onPressed: onEdit,
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
            ],
          ),
        ],
      ),
    );
  }
}

/// Signal add/edit dialog
class _SignalDialog extends StatefulWidget {
  final YabaiSignal? signal;
  final Function(YabaiSignal) onSave;

  const _SignalDialog({
    this.signal,
    required this.onSave,
  });

  @override
  State<_SignalDialog> createState() => _SignalDialogState();
}

class _SignalDialogState extends State<_SignalDialog> {
  late String _selectedEvent;
  late TextEditingController _actionController;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.signal?.event ?? 'window_focused';
    _actionController = TextEditingController(text: widget.signal?.action ?? '');
    _labelController = TextEditingController(text: widget.signal?.label ?? '');
  }

  @override
  void dispose() {
    _actionController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.signal != null;
    final isDark = MacosTheme.of(context).brightness == Brightness.dark;

    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Signal' : 'Add Signal',
                style: MacosTheme.of(context).typography.title1,
              ),
              const SizedBox(height: 24),

              // Event type dropdown
              Text(
                'Event Type',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8),
              MacosPopupButton<String>(
                value: _selectedEvent,
                items: YabaiSignal.validEvents.map((event) {
                  final displayName = event.split('_').map((word) =>
                    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
                  ).join(' ');
                  return MacosPopupMenuItem(
                    value: event,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEvent = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              if (YabaiSignal.eventDescriptions.containsKey(_selectedEvent))
                Text(
                  YabaiSignal.eventDescriptions[_selectedEvent]!,
                  style: MacosTheme.of(context).typography.caption1.copyWith(
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                      ),
                ),
              const SizedBox(height: 16),

              // Label field
              Text(
                'Label (optional)',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8),
              MacosTextField(
                controller: _labelController,
                placeholder: 'Enter a descriptive label...',
              ),
              const SizedBox(height: 16),

              // Action command field
              Text(
                'Action Command',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8),
              MacosTextField(
                controller: _actionController,
                placeholder: 'Enter the command to execute...',
                maxLines: 3,
              ),
              const SizedBox(height: 4),
              Text(
                'Use environment variables like \$YABAI_WINDOW_ID, \$YABAI_PROCESS_ID, etc.',
                style: MacosTheme.of(context).typography.caption2.copyWith(
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
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
                    onPressed: _actionController.text.trim().isEmpty
                        ? null
                        : () {
                            final signal = YabaiSignal(
                              id: widget.signal?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              event: _selectedEvent,
                              action: _actionController.text.trim(),
                              label: _labelController.text.trim().isEmpty
                                  ? null
                                  : _labelController.text.trim(),
                              enabled: widget.signal?.enabled ?? true,
                            );
                            widget.onSave(signal);
                            Navigator.of(context).pop();
                          },
                    child: Text(isEditing ? 'Save' : 'Add'),
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
