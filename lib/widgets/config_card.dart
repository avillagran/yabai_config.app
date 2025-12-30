import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:macos_ui/macos_ui.dart';

/// A reusable card widget for configuration sections.
///
/// Provides a consistent look and feel for all configuration panels
/// using macOS styling conventions.
class ConfigCard extends StatelessWidget {
  /// The title displayed in the card header
  final String title;

  /// Optional subtitle displayed below the title
  final String? subtitle;

  /// The main content of the card
  final Widget child;

  /// Optional action buttons displayed in the header
  final List<Widget>? actions;

  /// Optional icon displayed before the title
  final IconData? icon;

  /// Whether to add padding around the child content
  final bool padding;

  /// Custom padding value (defaults to 16.0)
  final double paddingValue;

  /// Whether the card is collapsible
  final bool collapsible;

  /// Initial collapsed state (only used when collapsible is true)
  final bool initiallyCollapsed;

  /// Callback when collapsed state changes
  final ValueChanged<bool>? onCollapsedChanged;

  /// Whether to show a divider between header and content
  final bool showDivider;

  /// Background color override
  final Color? backgroundColor;

  const ConfigCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.icon,
    this.padding = true,
    this.paddingValue = 16.0,
    this.collapsible = false,
    this.initiallyCollapsed = false,
    this.onCollapsedChanged,
    this.showDivider = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    final brightness = macosTheme.brightness;
    final isDark = brightness == Brightness.dark;

    // Card colors - use theme-aware colors
    final cardBg = backgroundColor ??
        (isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.systemBackground.resolveFrom(context));

    final borderColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.separator.resolveFrom(context);

    final headerBg = isDark
        ? const Color(0xFF323232)
        : CupertinoColors.secondarySystemBackground.resolveFrom(context);

    if (collapsible) {
      return _CollapsibleConfigCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        actions: actions,
        padding: padding,
        paddingValue: paddingValue,
        initiallyCollapsed: initiallyCollapsed,
        onCollapsedChanged: onCollapsedChanged,
        showDivider: showDivider,
        cardBg: cardBg,
        borderColor: borderColor,
        headerBg: headerBg,
        macosTheme: macosTheme,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, headerBg, macosTheme),
          if (showDivider)
            Divider(height: 1, thickness: 0.5, color: borderColor),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color headerBg,
    MacosThemeData macosTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            MacosIcon(
              icon!,
              size: 18,
              color: macosTheme.primaryColor,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: macosTheme.typography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: macosTheme.typography.subheadline.copyWith(
                      color: MacosColors.secondaryLabelColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions!.map((action) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: action,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: padding
          ? Padding(
              padding: EdgeInsets.all(paddingValue),
              child: child,
            )
          : child,
    );
  }
}

/// Internal widget for collapsible card functionality
class _CollapsibleConfigCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final bool padding;
  final double paddingValue;
  final bool initiallyCollapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  final bool showDivider;
  final Color cardBg;
  final Color borderColor;
  final Color headerBg;
  final MacosThemeData macosTheme;

  const _CollapsibleConfigCard({
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.actions,
    required this.padding,
    required this.paddingValue,
    required this.initiallyCollapsed,
    this.onCollapsedChanged,
    required this.showDivider,
    required this.cardBg,
    required this.borderColor,
    required this.headerBg,
    required this.macosTheme,
  });

  @override
  State<_CollapsibleConfigCard> createState() => _CollapsibleConfigCardState();
}

class _CollapsibleConfigCardState extends State<_CollapsibleConfigCard>
    with SingleTickerProviderStateMixin {
  late bool _isCollapsed;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (!_isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
      widget.onCollapsedChanged?.call(_isCollapsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(
              widget.macosTheme.brightness == Brightness.dark ? 0.3 : 0.08,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCollapsibleHeader(),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showDivider)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: widget.borderColor,
                  ),
                widget.padding
                    ? Padding(
                        padding: EdgeInsets.all(widget.paddingValue),
                        child: widget.child,
                      )
                    : widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleHeader() {
    return GestureDetector(
      onTap: _toggleCollapsed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.headerBg,
          borderRadius: _isCollapsed
              ? BorderRadius.circular(8)
              : const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            RotationTransition(
              turns: _rotationAnimation,
              child: MacosIcon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: MacosColors.secondaryLabelColor,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.icon != null) ...[
              MacosIcon(
                widget.icon!,
                size: 18,
                color: widget.macosTheme.primaryColor,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: widget.macosTheme.typography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: widget.macosTheme.typography.subheadline.copyWith(
                        color: MacosColors.secondaryLabelColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.actions != null && widget.actions!.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...widget.actions!.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: action,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple card without a header, useful for grouped content
class SimpleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const SimpleCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    final isDark = macosTheme.brightness == Brightness.dark;

    final cardBg = backgroundColor ??
        (isDark
            ? const Color(0xFF2D2D2D)
            : CupertinoColors.systemBackground.resolveFrom(context));

    final borderColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.separator.resolveFrom(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A row of settings with label and control
class SettingsRow extends StatelessWidget {
  final String label;
  final String? description;
  final Widget control;
  final bool dense;

  const SettingsRow({
    super.key,
    required this.label,
    this.description,
    required this.control,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 6 : 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: macosTheme.typography.body,
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: macosTheme.typography.caption1.copyWith(
                      color: MacosColors.secondaryLabelColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

/// A section divider with optional title
class SectionDivider extends StatelessWidget {
  final String? title;
  final EdgeInsets? padding;

  const SectionDivider({
    super.key,
    this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    final isDark = macosTheme.brightness == Brightness.dark;

    final dividerColor = isDark
        ? const Color(0xFF3D3D3D)
        : CupertinoColors.separator.resolveFrom(context);

    if (title == null) {
      return Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, thickness: 0.5, color: dividerColor),
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(height: 1, thickness: 0.5, color: dividerColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title!,
              style: macosTheme.typography.caption1.copyWith(
                color: MacosColors.tertiaryLabelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(height: 1, thickness: 0.5, color: dividerColor),
          ),
        ],
      ),
    );
  }
}
