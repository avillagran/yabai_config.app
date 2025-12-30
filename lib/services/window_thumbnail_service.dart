import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Service for capturing window thumbnails using native macOS APIs
class WindowThumbnailService {
  static const _channel = MethodChannel('com.yabaiconfig/window_thumbnails');

  /// Singleton instance
  static final WindowThumbnailService instance = WindowThumbnailService._();

  WindowThumbnailService._();

  /// Cache for thumbnails to avoid excessive captures
  final Map<int, _CachedThumbnail> _cache = {};

  /// Cache duration - thumbnails older than this will be refreshed
  static const _cacheDuration = Duration(seconds: 2);

  /// Capture a single window thumbnail
  Future<Uint8List?> captureWindow(int windowId) async {
    // Check cache first
    final cached = _cache[windowId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'captureWindow',
        {'windowId': windowId},
      );

      if (result != null) {
        _cache[windowId] = _CachedThumbnail(result);
      }

      return result;
    } catch (e) {
      // Silently fail - thumbnails are optional
      return null;
    }
  }

  /// Capture multiple window thumbnails at once (more efficient)
  Future<Map<int, Uint8List>> captureWindows(List<int> windowIds) async {
    if (windowIds.isEmpty) return {};

    // Check which ones need refresh
    final needsCapture = <int>[];
    final results = <int, Uint8List>{};

    for (final id in windowIds) {
      final cached = _cache[id];
      if (cached != null && !cached.isExpired) {
        results[id] = cached.data;
      } else {
        needsCapture.add(id);
      }
    }

    if (needsCapture.isEmpty) return results;

    try {
      final captured = await _channel.invokeMethod<Map>(
        'captureWindows',
        {'windowIds': needsCapture},
      );

      if (captured != null) {
        for (final entry in captured.entries) {
          final windowId = int.tryParse(entry.key.toString());
          final data = entry.value as Uint8List?;
          if (windowId != null && data != null) {
            _cache[windowId] = _CachedThumbnail(data);
            results[windowId] = data;
          }
        }
      }
    } catch (e) {
      // Silently fail
    }

    return results;
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Remove expired entries from cache
  void cleanupCache() {
    _cache.removeWhere((_, cached) => cached.isExpired);
  }
}

class _CachedThumbnail {
  final Uint8List data;
  final DateTime timestamp;

  _CachedThumbnail(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > WindowThumbnailService._cacheDuration;
}
