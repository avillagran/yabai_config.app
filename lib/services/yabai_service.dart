import 'dart:convert';
import 'dart:io';

/// Service for interacting with the yabai window manager CLI
class YabaiService {
  /// Default path to yabai executable
  static const String defaultYabaiPath = 'yabai';

  /// Path to yabai executable (can be customized)
  final String yabaiPath;

  /// Path to the yabai config file
  final String configPath;

  YabaiService({
    String? yabaiPath,
    String? configPath,
  })  : yabaiPath = yabaiPath ?? defaultYabaiPath,
        configPath = configPath ?? '${Platform.environment['HOME']}/.yabairc';

  /// Detect yabai installation path from Homebrew
  static Future<String?> detectYabaiPath() async {
    try {
      // Try to find yabai using which command
      final whichResult = await Process.run('which', ['yabai']);
      if (whichResult.exitCode == 0) {
        final path = (whichResult.stdout as String).trim();
        if (path.isNotEmpty) return path;
      }

      // Try common Homebrew locations
      final homebrewPaths = [
        '/opt/homebrew/bin/yabai',
        '/usr/local/bin/yabai',
      ];

      for (final path in homebrewPaths) {
        if (await File(path).exists()) {
          return path;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if yabai is currently running
  Future<bool> isRunning() async {
    try {
      // Use full path to pgrep for macOS desktop app environment
      final result = await Process.run('/usr/bin/pgrep', ['-x', 'yabai']);
      if (result.exitCode == 0) {
        return true;
      }

      // Fallback: check using ps command
      final psResult = await Process.run(
        '/bin/ps',
        ['aux'],
        environment: {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin'},
      );
      if (psResult.exitCode == 0) {
        final output = psResult.stdout as String;
        return output.contains('/yabai') || output.contains('yabai');
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Start yabai service
  Future<YabaiResult> start() async {
    try {
      // First check if already running
      if (await isRunning()) {
        return YabaiResult(
          success: true,
          message: 'yabai is already running',
        );
      }

      // Try to start yabai using brew services
      final result = await Process.run('brew', ['services', 'start', 'yabai']);
      
      if (result.exitCode == 0) {
        return YabaiResult(
          success: true,
          message: 'yabai started successfully',
        );
      }

      // Fallback: try to start yabai directly
      final directResult = await Process.run(yabaiPath, []);
      
      return YabaiResult(
        success: directResult.exitCode == 0,
        message: directResult.exitCode == 0
            ? 'yabai started successfully'
            : 'Failed to start yabai: ${directResult.stderr}',
        stderr: directResult.stderr?.toString(),
      );
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error starting yabai: $e',
      );
    }
  }

  /// Stop yabai service
  Future<YabaiResult> stop() async {
    try {
      // First check if not running
      if (!await isRunning()) {
        return YabaiResult(
          success: true,
          message: 'yabai is not running',
        );
      }

      // Try to stop using brew services
      final result = await Process.run('brew', ['services', 'stop', 'yabai']);
      
      if (result.exitCode == 0) {
        return YabaiResult(
          success: true,
          message: 'yabai stopped successfully',
        );
      }

      // Fallback: use yabai --stop-service
      final stopResult = await Process.run(yabaiPath, ['--stop-service']);
      
      if (stopResult.exitCode == 0) {
        return YabaiResult(
          success: true,
          message: 'yabai stopped successfully',
        );
      }

      // Last resort: kill the process
      final killResult = await Process.run('/usr/bin/pkill', ['-x', 'yabai']);
      
      return YabaiResult(
        success: killResult.exitCode == 0,
        message: killResult.exitCode == 0
            ? 'yabai stopped successfully'
            : 'Failed to stop yabai',
      );
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error stopping yabai: $e',
      );
    }
  }

  /// Restart yabai service
  Future<YabaiResult> restart() async {
    try {
      // Try brew services restart
      final result = await Process.run('brew', ['services', 'restart', 'yabai']);
      
      if (result.exitCode == 0) {
        return YabaiResult(
          success: true,
          message: 'yabai restarted successfully',
        );
      }

      // Fallback: stop then start
      final stopResult = await stop();
      if (!stopResult.success) {
        return YabaiResult(
          success: false,
          message: 'Failed to stop yabai during restart: ${stopResult.message}',
        );
      }

      // Wait a moment before starting
      await Future.delayed(const Duration(milliseconds: 500));

      return await start();
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error restarting yabai: $e',
      );
    }
  }

  /// Reload yabai configuration without restarting
  Future<YabaiResult> reloadConfig() async {
    try {
      // Source the config file
      final result = await Process.run(
        'sh',
        ['-c', 'source "$configPath"'],
        environment: {'configPath': configPath},
      );

      return YabaiResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0
            ? 'Configuration reloaded'
            : 'Failed to reload configuration',
        stderr: result.stderr?.toString(),
      );
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error reloading configuration: $e',
      );
    }
  }

  /// Query yabai for information about a specific domain
  /// Domain can be: windows, spaces, displays
  Future<YabaiQueryResult> query(String domain) async {
    try {
      final result = await Process.run(yabaiPath, ['-m', 'query', '--$domain']);

      if (result.exitCode != 0) {
        return YabaiQueryResult(
          success: false,
          message: 'Query failed: ${result.stderr}',
          data: null,
        );
      }

      final output = result.stdout as String;
      final jsonData = json.decode(output);

      return YabaiQueryResult(
        success: true,
        message: 'Query successful',
        data: jsonData,
        rawOutput: output,
      );
    } catch (e) {
      return YabaiQueryResult(
        success: false,
        message: 'Error querying yabai: $e',
        data: null,
      );
    }
  }

  /// Query windows information
  Future<YabaiQueryResult> queryWindows() => query('windows');

  /// Query spaces information
  Future<YabaiQueryResult> querySpaces() => query('spaces');

  /// Query displays information
  Future<YabaiQueryResult> queryDisplays() => query('displays');

  /// Execute a raw yabai command
  Future<YabaiResult> executeCommand(String command) async {
    try {
      // Parse the command string
      final parts = command.split(' ').where((s) => s.isNotEmpty).toList();
      
      if (parts.isEmpty) {
        return YabaiResult(
          success: false,
          message: 'Empty command',
        );
      }

      // Remove 'yabai' prefix if present
      final args = parts.first.toLowerCase() == 'yabai' ? parts.sublist(1) : parts;

      final result = await Process.run(yabaiPath, args);

      return YabaiResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0
            ? 'Command executed successfully'
            : 'Command failed',
        stdout: result.stdout?.toString(),
        stderr: result.stderr?.toString(),
      );
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error executing command: $e',
      );
    }
  }

  /// Execute a yabai message command (yabai -m ...)
  Future<YabaiResult> sendMessage(List<String> args) async {
    try {
      final fullArgs = ['-m', ...args];
      final result = await Process.run(yabaiPath, fullArgs);

      return YabaiResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0
            ? 'Message sent successfully'
            : 'Message failed: ${result.stderr}',
        stdout: result.stdout?.toString(),
        stderr: result.stderr?.toString(),
      );
    } catch (e) {
      return YabaiResult(
        success: false,
        message: 'Error sending message: $e',
      );
    }
  }

  /// Focus a window in a direction (north, south, east, west)
  Future<YabaiResult> focusWindow(String direction) {
    return sendMessage(['window', '--focus', direction]);
  }

  /// Swap window with another in a direction
  Future<YabaiResult> swapWindow(String direction) {
    return sendMessage(['window', '--swap', direction]);
  }

  /// Move window to a space
  Future<YabaiResult> moveWindowToSpace(int spaceIndex) {
    return sendMessage(['window', '--space', spaceIndex.toString()]);
  }

  /// Toggle window floating
  Future<YabaiResult> toggleFloat() {
    return sendMessage(['window', '--toggle', 'float']);
  }

  /// Toggle window fullscreen zoom
  Future<YabaiResult> toggleZoomFullscreen() {
    return sendMessage(['window', '--toggle', 'zoom-fullscreen']);
  }

  /// Get the current yabai version
  Future<String?> getVersion() async {
    try {
      final result = await Process.run(yabaiPath, ['--version']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if yabai is installed
  Future<bool> isInstalled() async {
    try {
      final result = await Process.run(yabaiPath, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if SIP is properly configured for yabai
  Future<bool> checkSipStatus() async {
    try {
      final result = await Process.run('csrutil', ['status']);
      final output = result.stdout as String;
      // yabai works best with SIP disabled or with specific protections disabled
      return output.contains('disabled') || output.contains('Filesystem Protections: disabled');
    } catch (e) {
      return false;
    }
  }
}

/// Result from a yabai operation
class YabaiResult {
  final bool success;
  final String message;
  final String? stdout;
  final String? stderr;

  const YabaiResult({
    required this.success,
    required this.message,
    this.stdout,
    this.stderr,
  });

  @override
  String toString() => 'YabaiResult(success: $success, message: $message)';
}

/// Result from a yabai query operation
class YabaiQueryResult extends YabaiResult {
  final dynamic data;
  final String? rawOutput;

  const YabaiQueryResult({
    required super.success,
    required super.message,
    required this.data,
    this.rawOutput,
  });

  /// Get data as a list (for windows, spaces, displays queries)
  List<Map<String, dynamic>>? get asList {
    if (data is List) {
      return (data as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Get data as a map
  Map<String, dynamic>? get asMap {
    if (data is Map) {
      return data as Map<String, dynamic>;
    }
    return null;
  }
}
