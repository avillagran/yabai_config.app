import 'dart:async';
import 'dart:io';

/// Service for watching configuration files for external changes
class FileWatcherService {
  /// Active file watchers
  final Map<String, _FileWatcher> _watchers = {};

  /// Stream controller for file change events
  final _changeController = StreamController<FileChangeEvent>.broadcast();

  /// Debounce duration to prevent multiple rapid events
  final Duration debounceDuration;

  /// Whether the service is disposed
  bool _disposed = false;

  FileWatcherService({
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  /// Stream of file change events
  Stream<FileChangeEvent> get changes => _changeController.stream;

  /// Watch a file for changes
  /// Returns a stream of FileSystemEvents for that specific file
  Stream<FileSystemEvent> watchFile(String path) {
    if (_disposed) {
      throw StateError('FileWatcherService has been disposed');
    }

    // Check if already watching this file
    if (_watchers.containsKey(path)) {
      return _watchers[path]!.events;
    }

    // Create new watcher
    final watcher = _FileWatcher(
      path: path,
      debounceDuration: debounceDuration,
    );

    _watchers[path] = watcher;

    // Forward events to the main stream
    watcher.events.listen(
      (event) {
        if (!_disposed) {
          _changeController.add(FileChangeEvent(
            path: path,
            event: event,
            timestamp: DateTime.now(),
          ));
        }
      },
      onError: (error) {
        if (!_disposed) {
          _changeController.addError(error);
        }
      },
    );

    watcher.start();

    return watcher.events;
  }

  /// Stop watching a specific file
  Future<void> unwatchFile(String path) async {
    final watcher = _watchers.remove(path);
    if (watcher != null) {
      await watcher.stop();
    }
  }

  /// Check if a file is being watched
  bool isWatching(String path) => _watchers.containsKey(path);

  /// Get all watched file paths
  List<String> get watchedPaths => _watchers.keys.toList();

  /// Pause watching (e.g., when saving from the app)
  void pause(String path) {
    _watchers[path]?.pause();
  }

  /// Resume watching after pause
  void resume(String path) {
    _watchers[path]?.resume();
  }

  /// Pause all watchers
  void pauseAll() {
    for (final watcher in _watchers.values) {
      watcher.pause();
    }
  }

  /// Resume all watchers
  void resumeAll() {
    for (final watcher in _watchers.values) {
      watcher.resume();
    }
  }

  /// Dispose of all watchers and close streams
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    for (final watcher in _watchers.values) {
      await watcher.stop();
    }
    _watchers.clear();

    await _changeController.close();
  }
}

/// Internal file watcher implementation
class _FileWatcher {
  final String path;
  final Duration debounceDuration;

  StreamSubscription<FileSystemEvent>? _subscription;
  final _controller = StreamController<FileSystemEvent>.broadcast();
  Timer? _debounceTimer;
  bool _paused = false;
  DateTime? _lastModified;

  _FileWatcher({
    required this.path,
    required this.debounceDuration,
  });

  Stream<FileSystemEvent> get events => _controller.stream;

  Future<void> start() async {
    final file = File(path);

    if (!await file.exists()) {
      // Watch the parent directory for file creation
      final parent = file.parent;
      if (await parent.exists()) {
        _watchDirectory(parent, file.path);
      }
      return;
    }

    // Store initial modification time
    final stat = await file.stat();
    _lastModified = stat.modified;

    // Watch the file
    _watchFile(file);
  }

  void _watchFile(File file) {
    // Watch the parent directory since File.watch() can be unreliable
    final parent = file.parent;
    _watchDirectory(parent, file.path);
  }

  void _watchDirectory(Directory dir, String targetPath) {
    try {
      _subscription = dir.watch().listen(
        (event) {
          if (_paused) return;

          // Filter for our target file
          final eventPath = event.path;
          final targetName = targetPath.split('/').last;
          final eventName = eventPath.split('/').last;

          if (eventName != targetName) return;

          // Debounce rapid changes
          _debounceTimer?.cancel();
          _debounceTimer = Timer(debounceDuration, () async {
            // Verify the file actually changed
            final file = File(targetPath);
            if (await file.exists()) {
              final stat = await file.stat();
              if (_lastModified == null || stat.modified != _lastModified) {
                _lastModified = stat.modified;
                _controller.add(event);
              }
            } else if (event.type == FileSystemEvent.delete) {
              _controller.add(event);
            }
          });
        },
        onError: (error) {
          _controller.addError(error);
        },
      );
    } catch (e) {
      _controller.addError(FileWatcherException('Failed to start watching: $e'));
    }
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    await _controller.close();
  }
}

/// Event representing a file change
class FileChangeEvent {
  /// Path to the changed file
  final String path;

  /// The underlying file system event
  final FileSystemEvent event;

  /// Timestamp when the change was detected
  final DateTime timestamp;

  const FileChangeEvent({
    required this.path,
    required this.event,
    required this.timestamp,
  });

  /// Get the type of change
  FileChangeType get changeType {
    switch (event.type) {
      case FileSystemEvent.create:
        return FileChangeType.created;
      case FileSystemEvent.modify:
        return FileChangeType.modified;
      case FileSystemEvent.delete:
        return FileChangeType.deleted;
      case FileSystemEvent.move:
        return FileChangeType.moved;
      default:
        return FileChangeType.unknown;
    }
  }

  /// Get human-readable description
  String get description {
    switch (changeType) {
      case FileChangeType.created:
        return 'File created: $path';
      case FileChangeType.modified:
        return 'File modified: $path';
      case FileChangeType.deleted:
        return 'File deleted: $path';
      case FileChangeType.moved:
        return 'File moved: $path';
      case FileChangeType.unknown:
        return 'File changed: $path';
    }
  }

  @override
  String toString() => 'FileChangeEvent($changeType, $path)';
}

/// Type of file change
enum FileChangeType {
  created,
  modified,
  deleted,
  moved,
  unknown,
}

/// Exception for file watcher errors
class FileWatcherException implements Exception {
  final String message;

  FileWatcherException(this.message);

  @override
  String toString() => 'FileWatcherException: $message';
}

/// Mixin for classes that need to watch config files
mixin ConfigFileWatcher {
  FileWatcherService? _watcherService;
  StreamSubscription<FileChangeEvent>? _changeSubscription;

  /// Initialize file watching
  void initFileWatcher() {
    _watcherService = FileWatcherService();
  }

  /// Start watching config files
  void startWatching(List<String> paths, void Function(FileChangeEvent) onChanged) {
    if (_watcherService == null) {
      initFileWatcher();
    }

    for (final path in paths) {
      _watcherService!.watchFile(path);
    }

    _changeSubscription = _watcherService!.changes.listen(onChanged);
  }

  /// Stop watching and dispose
  Future<void> stopWatching() async {
    await _changeSubscription?.cancel();
    await _watcherService?.dispose();
    _watcherService = null;
  }

  /// Pause watching (e.g., during save)
  void pauseWatching() {
    _watcherService?.pauseAll();
  }

  /// Resume watching after pause
  void resumeWatching() {
    _watcherService?.resumeAll();
  }
}

/// Helper class for watching multiple config files with callbacks
class MultiFileWatcher {
  final FileWatcherService _service;
  final Map<String, List<void Function(FileChangeEvent)>> _callbacks = {};
  StreamSubscription<FileChangeEvent>? _subscription;

  MultiFileWatcher() : _service = FileWatcherService();

  /// Add a file to watch with a callback
  void watch(String path, void Function(FileChangeEvent) callback) {
    _callbacks.putIfAbsent(path, () => []).add(callback);

    if (!_service.isWatching(path)) {
      _service.watchFile(path);
    }

    // Setup subscription if not already
    _subscription ??= _service.changes.listen(_handleEvent);
  }

  void _handleEvent(FileChangeEvent event) {
    final callbacks = _callbacks[event.path];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback(event);
      }
    }
  }

  /// Remove a callback for a file
  void unwatch(String path, void Function(FileChangeEvent) callback) {
    _callbacks[path]?.remove(callback);
    if (_callbacks[path]?.isEmpty ?? true) {
      _callbacks.remove(path);
      _service.unwatchFile(path);
    }
  }

  /// Stop watching all files
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _service.dispose();
    _callbacks.clear();
  }
}
