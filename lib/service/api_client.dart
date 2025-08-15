import 'dart:async';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../auth/token_storage.dart';

class ApiClient {
  // Singleton instance
  static final ApiClient instance = ApiClient._();

  late Dio dio;
  late Dio _refreshDio; // Dùng riêng cho refresh token
  bool _isRefreshing = false;
  final List<Completer<String>> _refreshWaiters = [];

  ApiClient._();

  /// Khởi tạo Dio + Interceptors
  Future<void> init() async {
    dio = Dio(BaseOptions(
      baseUrl: "https://chat-app-be-be11.onrender.com/api",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    _refreshDio = Dio(BaseOptions(
      baseUrl: "https://chat-app-be-be11.onrender.com/api",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        String? access = TokenStorage.instance.accessToken;
        if (access != null) {
          if (_willExpireSoon(access, const Duration(seconds: 20))) {
            try {
              access = await _refreshTokenIfNeeded();
            } catch (_) {
              // Ignore lỗi, để request fail
            }
          }
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (DioException err, handler) async {
        final isUnauthorized = err.response?.statusCode == 401;
        final isRefreshCall =
            err.requestOptions.path.endsWith('/auth/refreshtoken');

        if (isUnauthorized && !isRefreshCall) {
          try {
            final newAccess = await _refreshTokenIfNeeded(force: true);
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final clone = await dio.fetch(opts);
            return handler.resolve(clone);
          } catch (e) {
            await TokenStorage.instance.clear();
            return handler.next(err);
          }
        }
        handler.next(err);
      },
    ));
  }

  bool _willExpireSoon(String token, Duration threshold) {
    try {
      final expDate = JwtDecoder.getExpirationDate(token);
      return expDate.isBefore(DateTime.now().add(threshold));
    } catch (_) {
      return false;
    }
  }

  Future<String> _refreshTokenIfNeeded({bool force = false}) async {
    final access = TokenStorage.instance.accessToken;
    final refresh = TokenStorage.instance.refreshToken;

    if (refresh == null) throw Exception('No refresh token');

    if (!force &&
        access != null &&
        !_willExpireSoon(access, const Duration(seconds: 0))) {
      return access;
    }

    if (_isRefreshing) {
      final waiter = Completer<String>();
      _refreshWaiters.add(waiter);
      return waiter.future;
    }

    _isRefreshing = true;
    try {
      // Gọi API refresh token bằng Dio riêng để tránh interceptor
      final res = await _refreshDio.post('/auth/refreshtoken', data: {
        'refreshToken': refresh,
      });

      final newAccess = res.data['accessToken'] as String;
      await TokenStorage.instance.setAccessToken(newAccess);

      // Đánh thức các request đang chờ
      for (final w in _refreshWaiters) {
        if (!w.isCompleted) w.complete(newAccess);
      }
      _refreshWaiters.clear();

      return newAccess;
    } catch (e) {
      for (final w in _refreshWaiters) {
        if (!w.isCompleted) w.completeError(e);
      }
      _refreshWaiters.clear();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}
