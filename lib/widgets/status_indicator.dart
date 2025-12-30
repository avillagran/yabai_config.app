import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Status types for the indicator
enum StatusType {
  running,
  stopped,
  warning,
  unknown,
}

/// A reusable status indicator widget with optional pulsing animation
class StatusIndicator extends StatefulWidget {
  /// The current status to display
  final StatusType status;

  /// Optional label text to display next to the indicator
  final String? label;

  /// Whether to show a pulsing animation
  final bool pulsing;

  /// Size of the indicator dot
  final double size;

  /// Style for the label text
  final TextStyle? labelStyle;

  const StatusIndicator({
    super.key,
    required this.status,
    this.label,
    this.pulsing = false,
    this.size = 10.0,
    this.labelStyle,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.pulsing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (!widget.pulsing && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case StatusType.running:
        return CupertinoColors.activeGreen;
      case StatusType.stopped:
        return CupertinoColors.systemRed;
      case StatusType.warning:
        return CupertinoColors.systemOrange;
      case StatusType.unknown:
        return CupertinoColors.systemGrey;
    }
  }

  String _getDefaultLabel() {
    switch (widget.status) {
      case StatusType.running:
        return 'Running';
      case StatusType.stopped:
        return 'Stopped';
      case StatusType.warning:
        return 'Warning';
      case StatusType.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = widget.label ?? _getDefaultLabel();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(
                  widget.pulsing ? _pulseAnimation.value : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(
                      widget.pulsing ? _pulseAnimation.value * 0.5 : 0.3,
                    ),
                    blurRadius: widget.pulsing ? widget.size * 0.8 : widget.size * 0.4,
                    spreadRadius: widget.pulsing ? widget.size * 0.2 : 0,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: widget.labelStyle ??
              MacosTheme.of(context).typography.body.copyWith(
                    color: MacosTheme.of(context).typography.body.color,
                  ),
        ),
      ],
    );
  }
}

/// A compact status indicator without label
class StatusDot extends StatelessWidget {
  final StatusType status;
  final double size;
  final bool pulsing;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 8.0,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusIndicator(
      status: status,
      size: size,
      pulsing: pulsing,
      label: null,
    );
  }
}

/// A status badge with background
class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  Color _getBackgroundColor() {
    switch (status) {
      case StatusType.running:
        return CupertinoColors.activeGreen.withOpacity(0.15);
      case StatusType.stopped:
        return CupertinoColors.systemRed.withOpacity(0.15);
      case StatusType.warning:
        return CupertinoColors.systemOrange.withOpacity(0.15);
      case StatusType.unknown:
        return CupertinoColors.systemGrey.withOpacity(0.15);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case StatusType.running:
        return CupertinoColors.activeGreen;
      case StatusType.stopped:
        return CupertinoColors.systemRed;
      case StatusType.warning:
        return CupertinoColors.systemOrange;
      case StatusType.unknown:
        return CupertinoColors.systemGrey;
    }
  }

  String _getDefaultLabel() {
    switch (status) {
      case StatusType.running:
        return 'Running';
      case StatusType.stopped:
        return 'Stopped';
      case StatusType.warning:
        return 'Warning';
      case StatusType.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label ?? _getDefaultLabel(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
