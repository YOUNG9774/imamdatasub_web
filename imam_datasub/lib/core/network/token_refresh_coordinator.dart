import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../config/app_endpoints.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';

/// Keeps the access token fresh so users aren't logged out every time it expires.
///
/// Uses a bare Dio instance with NO interceptors — reusing the main app Dio (which
/// has this same coordinator wired into its AuthInterceptor) would risk the refresh
/// call recursively trying to refresh itself.
///
/// De-duplicates concurrent refresh attempts: if several requests discover an
/// expired token at nearly the same moment, only ONE refresh call actually goes out
/// and the rest await its result. This matters because the backend ROTATES refresh
/// tokens (each one is single-use) — firing two refresh calls with the same token
/// at once would make the second one fail with an "invalid/revoked" error.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator(this._storage);

  final SecureStorageService _storage;
  Future<bool>? _inFlight;

  final Dio _bareDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      // Treat 401/409 (revoked/invalid refresh token) as a normal response here,
      // not a thrown DioException, so we can handle it as "refresh failed" cleanly.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// Call before attaching the access token to an outgoing request. Refreshes
  /// first if the cached token is within 5 minutes of expiry (see
  /// SecureStorageService.isTokenExpired). Returns false only if no valid
  /// session can be established (refresh token missing/expired/revoked).
  Future<bool> ensureFreshToken() async {
    final expired = await _storage.isTokenExpired();
    if (!expired) return true;
    return _refresh();
  }

  /// Forces a refresh regardless of the locally-cached expiry. Used when a
  /// request comes back with 401 even though the token looked fresh locally
  /// (e.g. server-side revocation, clock skew between device and server).
  Future<bool> forceRefresh() => _refresh();

  Future<bool> _refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _bareDio.post<dynamic>(
        AppEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode != 200) {
        appLogger.w('Token refresh rejected (${response.statusCode}) — session is dead');
        return false;
      }

      final body = response.data as Map<String, dynamic>?;
      final data = body?['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final newAccess = data['access_token']?.toString();
      final newRefresh = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'] is int
          ? data['expires_in'] as int
          : int.tryParse(data['expires_in']?.toString() ?? '') ?? 3600;

      if (newAccess == null || newAccess.isEmpty || newRefresh == null || newRefresh.isEmpty) {
        return false;
      }

      await _storage.saveAccessToken(newAccess);
      await _storage.saveRefreshToken(newRefresh);
      await _storage.saveTokenExpiry(DateTime.now().add(Duration(seconds: expiresIn)));
      return true;
    } catch (e) {
      appLogger.e('Token refresh failed', error: e);
      return false;
    }
  }
}
