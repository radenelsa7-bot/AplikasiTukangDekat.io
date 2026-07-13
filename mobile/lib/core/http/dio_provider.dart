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
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
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

  // Add retry interceptor for rate limiting (429/409 errors)
  dio.interceptors.add(RetryOnConnectionChangeInterceptor(dio: dio));

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

/// Retry interceptor for handling rate limiting (429, 409) with exponential backoff
class RetryOnConnectionChangeInterceptor extends Interceptor {
  RetryOnConnectionChangeInterceptor({required this.dio});

  final Dio dio;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Retry on 429 (Too Many Requests) or 409 (Conflict) up to 3 times
    if ((statusCode == 429 || statusCode == 409) && _retryCount < _maxRetries) {
      _retryCount++;

      // Exponential backoff: 500ms, 1s, 2s
      final delayMs = _baseDelay.inMilliseconds * (_retryCount);
      await Future.delayed(Duration(milliseconds: delayMs));

      try {
        final options = err.requestOptions;
        final response = await dio.request<dynamic>(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: Options(method: options.method, headers: options.headers),
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _retryCount = 0; // Reset retry counter
    return handler.next(err);
  }
}
