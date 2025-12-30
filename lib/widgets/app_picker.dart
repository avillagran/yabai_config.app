import 'dart:io';
import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/material.dart' show Divider;
import 'package:macos_ui/macos_ui.dart';

/// A widget that allows selecting installed macOS applications
class AppPicker extends StatefulWidget {
  final String? selectedApp;
  final ValueChanged<String> onAppSelected;
  final String placeholder;

  const AppPicker({
    super.key,
    this.selectedApp,
    required this.onAppSelected,
    this.placeholder = 'Select an application...',
  });

  @override
  State<AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<AppPicker> {
  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final textBgColor = isDark
        ? const Color(0xFF2D2D2D)
        : CupertinoColors.systemBackground.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final textColor = CupertinoColors.label.resolveFrom(context);
    final placeholderColor = CupertinoColors.placeholderText.resolveFrom(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: textBgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: separatorColor,
              ),
            ),
            child: Text(
              widget.selectedApp ?? widget.placeholder,
              style: TextStyle(
                color: widget.selectedApp != null
                    ? textColor
                    : placeholderColor,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PushButton(
          controlSize: ControlSize.regular,
          onPressed: () => _showAppPickerDialog(context),
          child: const Text('Browse...'),
        ),
      ],
    );
  }

  void _showAppPickerDialog(BuildContext context) {
    showMacosSheet(
      context: context,
      builder: (context) => AppPickerSheet(
        selectedApp: widget.selectedApp,
        onAppSelected: (app) {
          widget.onAppSelected(app);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Sheet that displays the list of installed applications
class AppPickerSheet extends StatefulWidget {
  final String? selectedApp;
  final ValueChanged<String> onAppSelected;

  const AppPickerSheet({
    super.key,
    this.selectedApp,
    required this.onAppSelected,
  });

  @override
  State<AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<AppPickerSheet> {
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final apps = await _getInstalledApps();
    setState(() {
      _allApps = apps;
      _filteredApps = apps;
      _isLoading = false;
    });
  }

  Future<List<AppInfo>> _getInstalledApps() async {
    final apps = <AppInfo>[];
    final directories = [
      '/Applications',
      '/System/Applications',
      '/System/Applications/Utilities',
      '${Platform.environment['HOME']}/Applications',
    ];

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory && entity.path.endsWith('.app')) {
            final appName = entity.path.split('/').last.replaceAll('.app', '');
            final iconPath = '${entity.path}/Contents/Resources/AppIcon.icns';
            apps.add(AppInfo(
              name: appName,
              path: entity.path,
              hasIcon: await File(iconPath).exists(),
            ));
          }
        }
      }
    }

    // Sort alphabetically
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return apps;
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredApps = _allApps;
      } else {
        _filteredApps = _allApps
            .where((app) =>
                app.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final systemGrayColor = CupertinoColors.systemGrey.resolveFrom(context);
    final textBgColor = isDark
        ? const Color(0xFF2D2D2D)
        : CupertinoColors.systemBackground.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);

    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const MacosIcon(
                  CupertinoIcons.app_badge,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Application',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MacosTextField(
              controller: _searchController,
              autofocus: true,
              placeholder: 'Search applications...',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: MacosIcon(
                  CupertinoIcons.search,
                  size: 16,
                  color: systemGrayColor,
                ),
              ),
              onChanged: _filterApps,
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: ProgressCircle(),
                    )
                  : _filteredApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MacosIcon(
                                CupertinoIcons.app_badge,
                                size: 48,
                                color: systemGrayColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No applications found'
                                    : 'No matching applications',
                                style: TextStyle(
                                  color: systemGrayColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: textBgColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: separatorColor,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _filteredApps.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 44,
                              color: separatorColor,
                            ),
                            itemBuilder: (context, index) {
                              final app = _filteredApps[index];
                              final isSelected =
                                  app.name == widget.selectedApp;
                              return MacosListTile(
                                leading: const MacosIcon(
                                  CupertinoIcons.app,
                                  size: 24,
                                ),
                                title: Text(
                                  app.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  app.path,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: systemGrayColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onClick: () => widget.onAppSelected(app.name),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.regular,
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

/// Model class for application information
class AppInfo {
  final String name;
  final String path;
  final bool hasIcon;

  const AppInfo({
    required this.name,
    required this.path,
    this.hasIcon = false,
  });
}

/// A button that shows the selected app and opens the picker
class AppPickerButton extends StatelessWidget {
  final String? selectedApp;
  final ValueChanged<String> onAppSelected;
  final String placeholder;

  const AppPickerButton({
    super.key,
    this.selectedApp,
    required this.onAppSelected,
    this.placeholder = 'Select app...',
  });

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.regular,
      onPressed: () {
        showMacosSheet(
          context: context,
          builder: (context) => AppPickerSheet(
            selectedApp: selectedApp,
            onAppSelected: (app) {
              onAppSelected(app);
              Navigator.of(context).pop();
            },
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MacosIcon(
            CupertinoIcons.app,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(selectedApp ?? placeholder),
        ],
      ),
    );
  }
}
