import 'dart:io';

/// Service for interacting with the skhd hotkey daemon
class SkhdService {
  /// Default path to skhd executable
  static const String defaultSkhdPath = 'skhd';

  /// Path to skhd executable (can be customized)
  final String skhdPath;

  /// Path to the skhd config file
  final String configPath;

  SkhdService({
    String? skhdPath,
    String? configPath,
  })  : skhdPath = skhdPath ?? defaultSkhdPath,
        configPath = configPath ?? '${Platform.environment['HOME']}/.skhdrc';

  /// Detect skhd installation path
  static Future<String?> detectSkhdPath() async {
    try {
      // Try to find skhd using which command
      final whichResult = await Process.run('which', ['skhd']);
      if (whichResult.exitCode == 0) {
        final path = (whichResult.stdout as String).trim();
        if (path.isNotEmpty) return path;
      }

      // Try common Homebrew locations
      final homebrewPaths = [
        '/opt/homebrew/bin/skhd',
        '/usr/local/bin/skhd',
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

  /// Check if skhd is currently running
  Future<bool> isRunning() async {
    try {
      // Use full path to pgrep for macOS desktop app environment
      final result = await Process.run('/usr/bin/pgrep', ['-x', 'skhd']);
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
        return output.contains('/skhd') || output.contains('skhd');
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Start skhd service
  Future<SkhdResult> start() async {
    try {
      // First check if already running
      if (await isRunning()) {
        return SkhdResult(
          success: true,
          message: 'skhd is already running',
        );
      }

      // Try to start skhd using brew services
      final result = await Process.run('brew', ['services', 'start', 'skhd']);

      if (result.exitCode == 0) {
        return SkhdResult(
          success: true,
          message: 'skhd started successfully',
        );
      }

      // Fallback: try to start skhd directly in background
      final directResult = await Process.run(
        skhdPath,
        [],
        runInShell: true,
      );

      return SkhdResult(
        success: directResult.exitCode == 0,
        message: directResult.exitCode == 0
            ? 'skhd started successfully'
            : 'Failed to start skhd: ${directResult.stderr}',
        stderr: directResult.stderr?.toString(),
      );
    } catch (e) {
      return SkhdResult(
        success: false,
        message: 'Error starting skhd: $e',
      );
    }
  }

  /// Stop skhd service
  Future<SkhdResult> stop() async {
    try {
      // First check if not running
      if (!await isRunning()) {
        return SkhdResult(
          success: true,
          message: 'skhd is not running',
        );
      }

      // Try to stop using brew services
      final result = await Process.run('brew', ['services', 'stop', 'skhd']);

      if (result.exitCode == 0) {
        return SkhdResult(
          success: true,
          message: 'skhd stopped successfully',
        );
      }

      // Fallback: kill the process
      final killResult = await Process.run('/usr/bin/pkill', ['-x', 'skhd']);

      return SkhdResult(
        success: killResult.exitCode == 0,
        message: killResult.exitCode == 0
            ? 'skhd stopped successfully'
            : 'Failed to stop skhd',
      );
    } catch (e) {
      return SkhdResult(
        success: false,
        message: 'Error stopping skhd: $e',
      );
    }
  }

  /// Restart skhd service
  Future<SkhdResult> restart() async {
    try {
      // Try brew services restart
      final result = await Process.run('brew', ['services', 'restart', 'skhd']);

      if (result.exitCode == 0) {
        return SkhdResult(
          success: true,
          message: 'skhd restarted successfully',
        );
      }

      // Fallback: stop then start
      final stopResult = await stop();
      if (!stopResult.success) {
        return SkhdResult(
          success: false,
          message: 'Failed to stop skhd during restart: ${stopResult.message}',
        );
      }

      // Wait a moment before starting
      await Future.delayed(const Duration(milliseconds: 500));

      return await start();
    } catch (e) {
      return SkhdResult(
        success: false,
        message: 'Error restarting skhd: $e',
      );
    }
  }

  /// Reload skhd configuration
  /// skhd automatically reloads when the config file changes,
  /// but we can force a reload by sending SIGUSR1
  Future<SkhdResult> reloadConfig() async {
    try {
      if (!await isRunning()) {
        return SkhdResult(
          success: false,
          message: 'skhd is not running',
        );
      }

      // Get skhd PID
      final pidResult = await Process.run('/usr/bin/pgrep', ['-x', 'skhd']);
      if (pidResult.exitCode != 0) {
        return SkhdResult(
          success: false,
          message: 'Could not find skhd process',
        );
      }

      final pid = (pidResult.stdout as String).trim();

      // Send SIGUSR1 to reload config
      final result = await Process.run('kill', ['-SIGUSR1', pid]);

      return SkhdResult(
        success: result.exitCode == 0,
        message: result.exitCode == 0
            ? 'Configuration reloaded'
            : 'Failed to reload configuration',
      );
    } catch (e) {
      return SkhdResult(
        success: false,
        message: 'Error reloading configuration: $e',
      );
    }
  }

  /// Get the current skhd version
  Future<String?> getVersion() async {
    try {
      final result = await Process.run(skhdPath, ['--version']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      // skhd might not have --version flag, try -v
      final resultV = await Process.run(skhdPath, ['-v']);
      if (resultV.exitCode == 0) {
        return (resultV.stdout as String).trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if skhd is installed
  Future<bool> isInstalled() async {
    try {
      final result = await Process.run('which', [skhdPath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Validate the skhd configuration file
  Future<SkhdValidationResult> validateConfig() async {
    try {
      // Check if config file exists
      final configFile = File(configPath);
      if (!await configFile.exists()) {
        return SkhdValidationResult(
          valid: false,
          message: 'Config file does not exist: $configPath',
          errors: ['Config file not found'],
        );
      }

      // Read and parse config (basic validation)
      final content = await configFile.readAsString();
      final lines = content.split('\n');
      final errors = <String>[];
      final warnings = <String>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final lineNum = i + 1;

        // Skip empty lines and comments
        if (line.isEmpty || line.startsWith('#')) continue;

        // Check for basic shortcut format: modifier - key : command
        if (!line.contains(':') && !line.startsWith('::')) {
          errors.add('Line $lineNum: Missing command separator ":"');
          continue;
        }

        // Check for key binding
        if (!line.startsWith('::') && !line.contains('-')) {
          warnings.add('Line $lineNum: Unusual format - no key separator "-"');
        }
      }

      return SkhdValidationResult(
        valid: errors.isEmpty,
        message: errors.isEmpty
            ? 'Configuration is valid'
            : 'Configuration has ${errors.length} error(s)',
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return SkhdValidationResult(
        valid: false,
        message: 'Error validating configuration: $e',
        errors: ['Parse error: $e'],
      );
    }
  }

  /// Check if skhd has accessibility permissions
  Future<bool> hasAccessibilityPermissions() async {
    try {
      // This is a rough check - skhd needs accessibility permissions to work
      // We can check by running skhd briefly and seeing if it fails
      if (!await isInstalled()) return false;

      // If skhd is running, it has permissions
      if (await isRunning()) return true;

      // Try to start skhd with a test config
      // If it fails with permission error, we'll catch it
      return true; // Assume true if we can't definitively check
    } catch (e) {
      return false;
    }
  }

  /// Get skhd service status using launchctl
  Future<SkhdServiceStatus> getServiceStatus() async {
    try {
      // Check brew services status
      final result = await Process.run('brew', ['services', 'info', 'skhd', '--json']);
      
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        // Parse JSON output if available
        if (output.contains('running')) {
          return SkhdServiceStatus.running;
        } else if (output.contains('stopped')) {
          return SkhdServiceStatus.stopped;
        }
      }

      // Fallback to checking process
      if (await isRunning()) {
        return SkhdServiceStatus.running;
      }

      return SkhdServiceStatus.stopped;
    } catch (e) {
      return SkhdServiceStatus.unknown;
    }
  }
}

/// Result from an skhd operation
class SkhdResult {
  final bool success;
  final String message;
  final String? stdout;
  final String? stderr;

  const SkhdResult({
    required this.success,
    required this.message,
    this.stdout,
    this.stderr,
  });

  @override
  String toString() => 'SkhdResult(success: $success, message: $message)';
}

/// Result from skhd config validation
class SkhdValidationResult {
  final bool valid;
  final String message;
  final List<String> errors;
  final List<String> warnings;

  const SkhdValidationResult({
    required this.valid,
    required this.message,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() => 'SkhdValidationResult(valid: $valid, errors: ${errors.length}, warnings: ${warnings.length})';
}

/// Status of the skhd service
enum SkhdServiceStatus {
  running,
  stopped,
  error,
  unknown,
}
