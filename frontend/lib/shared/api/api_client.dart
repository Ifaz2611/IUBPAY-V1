import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// Persists the JWT between app launches (prototype-grade storage; use
/// flutter_secure_storage in a production build).
class TokenStore {
  static const _key = 'jwt_token';

  Future<void> save(String token) async =>
      (await SharedPreferences.getInstance()).setString(_key, token);

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
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
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
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
  return 'Unexpected error';
}
