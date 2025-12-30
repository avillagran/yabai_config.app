import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/space.dart';
import '../services/yabai_service.dart';

/// Provider for YabaiService
final yabaiServiceProvider = Provider<YabaiService>((ref) {
  return YabaiService();
});

/// State class for spaces
class SpacesState {
  final List<YabaiSpace> spaces;
  final List<YabaiWindow> windows;
  final List<YabaiDisplay> displays;
  final bool isLoading;
  final String? error;

  const SpacesState({
    this.spaces = const [],
    this.windows = const [],
    this.displays = const [],
    this.isLoading = false,
    this.error,
  });

  SpacesState copyWith({
    List<YabaiSpace>? spaces,
    List<YabaiWindow>? windows,
    List<YabaiDisplay>? displays,
    bool? isLoading,
    String? error,
  }) {
    return SpacesState(
      spaces: spaces ?? this.spaces,
      windows: windows ?? this.windows,
      displays: displays ?? this.displays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get spaces grouped by display
  Map<int, List<YabaiSpace>> get spacesByDisplay {
    final result = <int, List<YabaiSpace>>{};
    for (final space in spaces) {
      result.putIfAbsent(space.displayIndex, () => []).add(space);
    }
    return result;
  }

  /// Get windows for a specific space
  List<YabaiWindow> windowsForSpace(int spaceIndex) {
    return windows.where((w) => w.spaceIndex == spaceIndex).toList();
  }
}

/// Notifier for managing spaces state
class SpacesNotifier extends StateNotifier<SpacesState> {
  final YabaiService _yabaiService;

  SpacesNotifier(this._yabaiService) : super(const SpacesState()) {
    refresh();
  }

  /// Refresh all spaces, windows, and displays data
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _yabaiService.querySpaces(),
        _yabaiService.queryWindows(),
        _yabaiService.queryDisplays(),
      ]);

      final spacesResult = results[0] as YabaiQueryResult;
      final windowsResult = results[1] as YabaiQueryResult;
      final displaysResult = results[2] as YabaiQueryResult;

      if (!spacesResult.success) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to query spaces: ${spacesResult.message}',
        );
        return;
      }

      // Parse spaces
      final spacesList = spacesResult.asList ?? [];
      final spaces = spacesList.map((e) => YabaiSpace.fromJson(e)).toList();

      // Parse windows
      final windowsList = windowsResult.asList ?? [];
      final windows = windowsList.map((e) => YabaiWindow.fromJson(e)).toList();

      // Parse displays
      final displaysList = displaysResult.asList ?? [];
      final displays = displaysList.map((e) => YabaiDisplay.fromJson(e)).toList();

      // Associate windows with their spaces
      final spacesWithWindows = spaces.map((space) {
        final spaceWindows = windows.where((w) => w.spaceIndex == space.index).toList();
        return space.copyWith(windows: spaceWindows);
      }).toList();

      state = state.copyWith(
        spaces: spacesWithWindows,
        windows: windows,
        displays: displays,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load spaces: $e',
      );
    }
  }

  /// Update space layout
  Future<bool> updateSpaceLayout(int spaceIndex, String layout) async {
    final result = await _yabaiService.sendMessage(
      ['space', spaceIndex.toString(), '--layout', layout],
    );
    if (result.success) {
      await refresh();
    }
    return result.success;
  }

  /// Update space label
  Future<bool> updateSpaceLabel(int spaceIndex, String label) async {
    final result = await _yabaiService.sendMessage(
      ['space', spaceIndex.toString(), '--label', label],
    );
    if (result.success) {
      await refresh();
    }
    return result.success;
  }

  /// Focus a specific space
  Future<bool> focusSpace(int spaceIndex) async {
    final result = await _yabaiService.sendMessage(
      ['space', '--focus', spaceIndex.toString()],
    );
    if (result.success) {
      await refresh();
    }
    return result.success;
  }
}

/// Provider for spaces state
final spacesProvider = StateNotifierProvider<SpacesNotifier, SpacesState>((ref) {
  final yabaiService = ref.watch(yabaiServiceProvider);
  return SpacesNotifier(yabaiService);
});
