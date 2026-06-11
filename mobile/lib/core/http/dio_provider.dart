import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

CookieJar _cookieJar = CookieJar();
Dio? _sharedDio;

/// Initialize Dio with cookie manager (in-memory by default).
final dioProvider = Provider<Dio>((ref) {
  if (_sharedDio != null) return _sharedDio!;

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // On Web, the browser manages cookies; do not add CookieManager there
  if (!kIsWeb) {
    dio.interceptors.add(CookieManager(_cookieJar));
  }
  _sharedDio = dio;
  return dio;
});

/// Enable persistent cookie storage using `PersistCookieJar`.
/// Call this early in app startup (before making requests).
Future<void> enablePersistCookies() async {
  // Persisted file storage is not supported on web. No-op on web.
  if (kIsWeb) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final storagePath = '${dir.path}/.cookies/';
    final persistJar = PersistCookieJar(storage: FileStorage(storagePath));

    _cookieJar = persistJar;

    // Replace cookie manager interceptor on existing Dio instance.
    if (_sharedDio != null) {
      _sharedDio!.interceptors.removeWhere((i) => i is CookieManager);
      _sharedDio!.interceptors.add(CookieManager(_cookieJar));
    }
  } catch (e) {
    // If persistent storage initialization fails (platform unsupported),
    // keep using in-memory CookieJar.
    return;
  }
}
