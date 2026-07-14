import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';
import '../../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._onSessionExpired);

  final SecureStorageService _storage;
  final Future<void> Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    appLogger.api(options.method, options.path);
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      appLogger.w('Backend returned 401. Session may have expired.');
      await _onSessionExpired();
    }

    return handler.next(err);
  }
}
