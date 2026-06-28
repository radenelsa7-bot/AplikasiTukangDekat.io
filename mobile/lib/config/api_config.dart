import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String baseUrlWeb = 'http://127.0.0.1:8000';
  static const String baseUrlAndroidEmulator = 'http://10.0.2.2:8000';
  static const String baseUrlPhysicalDevice = 'http://192.168.1.10:8000';

  /// Load API base URL from environment or use platform defaults
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback to platform-specific defaults if .env not available
    if (kIsWeb) {
      return baseUrlWeb;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return baseUrlAndroidEmulator;
    }

    return baseUrlWeb;
  }

  /// Get app environment (development, staging, production)
  static String get appEnv {
    return dotenv.env['APP_ENV'] ?? 'development';
  }
}
