import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'providers/navigation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/general_config_screen.dart';
import 'screens/shortcuts_screen.dart';
import 'screens/exclusions_screen.dart';
import 'screens/spaces_screen.dart';
import 'screens/signals_screen.dart';
import 'screens/backups_screen.dart';
import 'screens/raw_config_screen.dart';

/// Main application widget for Yabai Config
class YabaiConfigApp extends ConsumerWidget {
  const YabaiConfigApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacosApp(
      title: 'Yabai Config',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainWindow(),
    );
  }
}

/// Main window with sidebar navigation
class MainWindow extends ConsumerStatefulWidget {
  const MainWindow({super.key});

  @override
  ConsumerState<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends ConsumerState<MainWindow> {
  @override
  Widget build(BuildContext context) {
    final pageIndex = ref.watch(navigationIndexProvider);

    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: pageIndex,
            onChanged: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
            },
            scrollController: scrollController,
            items: const [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.house_fill),
                label: Text('Dashboard'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.gear_alt_fill),
                label: Text('General Config'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.keyboard),
                label: Text('Shortcuts'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.eye_slash_fill),
                label: Text('Exclusions'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.square_grid_2x2_fill),
                label: Text('Spaces'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.bolt_fill),
                label: Text('Signals'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.archivebox_fill),
                label: Text('Backups'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.doc_text_fill),
                label: Text('Raw Config'),
              ),
            ],
          );
        },
        bottom: MacosListTile(
          leading: const MacosIcon(CupertinoIcons.info_circle_fill),
          title: const Text(
            'Yabai Config',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: const Text(
            'v0.1.0',
            style: TextStyle(
              fontSize: 11,
            ),
          ),
          onClick: () {
            _showAboutDialog(context);
          },
        ),
      ),
      child: IndexedStack(
        index: pageIndex,
        children: const [
          HomeScreen(),
          GeneralConfigScreen(),
          ShortcutsScreen(),
          ExclusionsScreen(),
          SpacesScreen(),
          SignalsScreen(),
          BackupsScreen(),
          RawConfigScreen(),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.gear_alt_fill, size: 56),
        title: const Text('Yabai Config'),
        message: const Text(
          'A visual configuration tool for the Yabai window manager.\n\n'
          'Configure Yabai settings, keyboard shortcuts, window rules, '
          'and more through an intuitive graphical interface.',
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
