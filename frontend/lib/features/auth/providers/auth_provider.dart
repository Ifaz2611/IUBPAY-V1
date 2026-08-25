import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final dio = ref.read(dioProvider);
    final store = ref.read(tokenStoreProvider);
    final token = await store.read();
    if (token == null) return null;
    try {
      final r = await dio.get('/auth/me');
      return User.fromJson(r.data);
    } catch (_) {
      await store.clear();
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.post('/auth/login',
          data: {'email': email, 'password': password});
      final user = User.fromJson(r.data['user']);
      await ref.read(tokenStoreProvider).save(r.data['access_token']);
      state = AsyncData(user);
      return null; // success
    } catch (e) {
      state = const AsyncData(null);
      return apiErrorMessage(e);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController::new);

/// True while the initial token check is still running.
final authLoadingProvider = Provider<bool>(
    (ref) => ref.watch(authProvider).isLoading && !ref.watch(authProvider).hasValue);
