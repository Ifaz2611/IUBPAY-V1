import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';

/// Persists the JWT in platform secure storage.
class TokenStore {
  static const _key = 'jwt_token';
  static const _refreshKey = 'refresh_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> save(String token) async =>
      _storage.write(key: _key, value: token);
  Future<void> saveRefresh(String token) async =>
      _storage.write(key: _refreshKey, value: token);
  Future<String?> read() async => _storage.read(key: _key);
  Future<String?> readRefresh() async => _storage.read(key: _refreshKey);
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _refreshKey);
  }
}

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await ref.read(tokenStoreProvider).read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401 &&
          !e.requestOptions.path.contains('/auth/refresh') &&
          !e.requestOptions.path.contains('/auth/login')) {
        final refresh = await ref.read(tokenStoreProvider).readRefresh();
        if (refresh != null) {
          try {
            final r = await Dio(BaseOptions(baseUrl: kApiBaseUrl))
                .post('/auth/refresh', data: {'refresh_token': refresh});
            final newAccess = r.data['access_token'] as String?;
            final newRefresh = r.data['refresh_token'] as String?;
            if (newAccess != null) {
              await ref.read(tokenStoreProvider).save(newAccess);
              if (newRefresh != null)
                await ref.read(tokenStoreProvider).saveRefresh(newRefresh);
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retry = await dio.fetch(e.requestOptions);
              return handler.resolve(retry);
            }
          } catch (_) {}
        }
      }
      handler.next(e);
    },
  ));
  return dio;
});

/// Turns Dio/HTTP errors into human-friendly messages.
String apiErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Cannot reach the server. Check your connection.';
      default:
        return 'Request failed (${e.response?.statusCode ?? "network"})';
    }
  }
  // Unwrap Exception(apiErrorMessage) thrown by orderDetailProvider etc.
  final msg = e.toString();
  if (msg.startsWith('Exception: ')) return msg.substring('Exception: '.length);
  return 'Unexpected error';
}
