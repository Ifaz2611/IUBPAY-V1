import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iub_pay/features/auth/providers/auth_provider.dart';
import 'package:iub_pay/shared/api/api_client.dart';

class FakeTokenStore implements TokenStore {
  String? token;
  String? refreshToken;

  FakeTokenStore({this.token, this.refreshToken});

  @override
  Future<String?> read() async => token;

  @override
  Future<String?> readRefresh() async => refreshToken;

  @override
  Future<void> save(String val) async {
    token = val;
  }

  @override
  Future<void> saveRefresh(String val) async {
    refreshToken = val;
  }

  @override
  Future<void> clear() async {
    token = null;
    refreshToken = null;
  }
}

class FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController', () {
    test('build returns null when no token is present in store', () async {
      final fakeStore = FakeTokenStore();
      final dio = Dio();
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authProvider.future);
      expect(user, isNull);
    });

    test('build fetches and returns user when valid token is stored', () async {
      final fakeStore = FakeTokenStore(token: 'valid-jwt');
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((options) async {
        if (options.path.contains('/auth/me')) {
          return jsonResponse({
            'id': 'usr-1',
            'name': 'Student One',
            'email': 'student@iub.edu.bd',
            'role': 'student',
            'status': 'ACTIVE',
          });
        }
        return jsonResponse({'detail': 'Not found'}, statusCode: 404);
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authProvider.future);
      expect(user, isNotNull);
      expect(user!.id, 'usr-1');
      expect(user.role, 'student');
      expect(user.email, 'student@iub.edu.bd');
    });

    test('build clears store and returns null when token is invalid/401', () async {
      final fakeStore = FakeTokenStore(token: 'expired-jwt');
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((options) async {
        if (options.path.contains('/auth/me')) {
          return jsonResponse({'detail': 'Token expired'}, statusCode: 401);
        }
        return jsonResponse({'detail': 'Not found'}, statusCode: 404);
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authProvider.future);
      expect(user, isNull);
      expect(fakeStore.token, isNull);
    });

    test('login success stores tokens and sets user state', () async {
      final fakeStore = FakeTokenStore();
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((options) async {
        if (options.path.contains('/auth/login')) {
          return jsonResponse({
            'access_token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
            'token_type': 'bearer',
            'user': {
              'id': 'usr-login',
              'name': 'Logged In User',
              'email': 'user@iub.edu.bd',
              'role': 'student',
              'status': 'ACTIVE',
            },
          });
        }
        return jsonResponse({'detail': 'Not found'}, statusCode: 404);
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      final error = await notifier.login('user@iub.edu.bd', 'Passw0rd!Dev');

      expect(error, isNull);
      expect(fakeStore.token, 'new-access-token');
      expect(fakeStore.refreshToken, 'new-refresh-token');

      final user = container.read(authProvider).value;
      expect(user, isNotNull);
      expect(user!.id, 'usr-login');
      expect(user.name, 'Logged In User');
    });

    test('login failure resets user state and returns error message', () async {
      final fakeStore = FakeTokenStore();
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((options) async {
        if (options.path.contains('/auth/login')) {
          return jsonResponse({'detail': 'Invalid email or password'}, statusCode: 401);
        }
        return jsonResponse({'detail': 'Not found'}, statusCode: 404);
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      final error = await notifier.login('bad@iub.edu.bd', 'wrong');

      expect(error, isNotNull);
      expect(fakeStore.token, isNull);
      expect(container.read(authProvider).value, isNull);
    });

    test('logout calls endpoint, clears store and resets state', () async {
      final fakeStore = FakeTokenStore(token: 'active-token');
      bool logoutCalled = false;
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((options) async {
        if (options.path.contains('/auth/logout')) {
          logoutCalled = true;
          return jsonResponse({'status': 'logged out'});
        }
        return jsonResponse({'detail': 'Not found'}, statusCode: 404);
      });

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
          dioProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      expect(logoutCalled, isTrue);
      expect(fakeStore.token, isNull);
      expect(container.read(authProvider).value, isNull);
    });
  });
}
