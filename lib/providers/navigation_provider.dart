import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation items for the sidebar
enum NavigationItem {
  dashboard(0, 'Dashboard'),
  generalConfig(1, 'General Config'),
  shortcuts(2, 'Shortcuts'),
  exclusions(3, 'Exclusions'),
  spaces(4, 'Spaces'),
  signals(5, 'Signals'),
  backups(6, 'Backups');

  final int pageIndex;
  final String label;

  const NavigationItem(this.pageIndex, this.label);
}

/// Provider for tracking the current navigation page index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for the current navigation item
final currentNavigationItemProvider = Provider<NavigationItem>((ref) {
  final index = ref.watch(navigationIndexProvider);
  return NavigationItem.values.firstWhere(
    (item) => item.pageIndex == index,
    orElse: () => NavigationItem.dashboard,
  );
});
