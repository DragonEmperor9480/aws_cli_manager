import 'dart:io';
import 'package:http/http.dart' as http;

class BackendService {
  static Process? _process;
  static const String baseUrl = 'http://localhost:8080';

  static Future<void> start() async {
    try {
      // Check if backend is already running
      if (await isRunning()) {
        print('Backend already running');
        return;
      }

      // Get backend executable path
      final backend = _getBackendPath();

      print('Starting backend: $backend');

      // Start backend process
      _process = await Process.start(
        backend,
        [],
        workingDirectory: _getBackendDir(),
      );

      // Listen to output
      _process!.stdout.listen((data) {
        print('Backend: ${String.fromCharCodes(data)}');
      });

      _process!.stderr.listen((data) {
        print('Backend Error: ${String.fromCharCodes(data)}');
      });

      // Wait for backend to be ready
      await _waitForBackend();

      print('Backend started successfully');
    } catch (e) {
      print('Failed to start backend: $e');
      rethrow;
    }
  }

  static String _getBackendPath() {
    if (Platform.isWindows) {
      return '../backend/main.exe';
    } else {
      return '../backend/main';
    }
  }

  static String _getBackendDir() {
    return '../backend';
  }

  static Future<bool> isRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _waitForBackend() async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await isRunning()) {
        return;
      }
    }
    throw Exception('Backend failed to start within 15 seconds');
  }

  static void stop() {
    _process?.kill();
    _process = null;
    print('Backend stopped');
  }
}
