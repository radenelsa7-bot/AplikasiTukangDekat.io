import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String baseUrlWeb = 'http://127.0.0.1:8000';
  static const String baseUrlAndroidEmulator = 'http://10.0.2.2:8000';

  /// Compile-time override via --dart-define=API_BASE_URL=http://IP:8000
  static const String _dartDefineUrl = String.fromEnvironment('API_BASE_URL');

  /// Load API base URL with priority:
  /// 1. --dart-define=API_BASE_URL (compile-time, most reliable)
  /// 2. .env file API_BASE_URL (bundled asset)
  /// 3. Platform default (web=127.0.0.1, android=10.0.2.2)
  static String get baseUrl {
    // Priority 1: --dart-define (paling reliable untuk physical device)
    if (_dartDefineUrl.isNotEmpty) {
      debugPrint('[ApiConfig] Using --dart-define URL: $_dartDefineUrl');
      return _dartDefineUrl;
    }

    // Priority 2: .env file
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        debugPrint('[ApiConfig] Using .env URL: $envUrl');
        return envUrl;
      }
    } catch (e) {
      debugPrint('[ApiConfig] dotenv not loaded: $e');
    }

    // Priority 3: Platform default
    if (kIsWeb) {
      debugPrint('[ApiConfig] Using web default: $baseUrlWeb');
      return baseUrlWeb;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
        '[ApiConfig] Using Android emulator default: $baseUrlAndroidEmulator',
      );
      return baseUrlAndroidEmulator;
    }

    debugPrint('[ApiConfig] Using fallback: $baseUrlWeb');
    return baseUrlWeb;
  }

  /// Get app environment (development, staging, production)
  static String get appEnv {
    try {
      return dotenv.env['APP_ENV'] ?? 'development';
    } catch (_) {
      return 'development';
    }
  }
}
