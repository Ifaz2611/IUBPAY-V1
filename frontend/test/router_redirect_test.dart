import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iub_pay/core/router/admin_router.dart';
import 'package:iub_pay/core/router/app_router.dart';
import 'package:iub_pay/core/router/student_router.dart';
import 'package:iub_pay/core/router/vendor_router.dart';
import 'package:iub_pay/core/theme/app_theme.dart';
import 'package:iub_pay/features/auth/providers/auth_provider.dart';
import 'package:iub_pay/shared/models/models.dart';

class FakeAuthController extends AuthController {
  final User? fakeUser;
  FakeAuthController(this.fakeUser);

  @override
  Future<User?> build() async => fakeUser;
}

final studentUser = User(
  id: 's-1',
  name: 'Student User',
  email: 'student@iub.test',
  role: 'student',
  status: 'ACTIVE',
);

final vendorUser = User(
  id: 'v-1',
  name: 'Vendor User',
  email: 'vendor@iub.test',
  role: 'vendor',
  status: 'ACTIVE',
);

final adminUser = User(
  id: 'a-1',
  name: 'Admin User',
  email: 'admin@iub.test',
  role: 'admin',
  status: 'ACTIVE',
);

Future<void> pumpRouter(WidgetTester tester, ProviderContainer container, dynamic router) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student router redirects', () {
    testWidgets('unauthenticated user navigating to protected path is redirected to /login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(null)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(studentRouterProvider);
      await pumpRouter(tester, container, router);
      router.go('/student');
      await tester.pump();

      expect(router.state.matchedLocation, '/login');
    });

    testWidgets('student user is redirected to /student from splash/login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(studentUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(studentRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/student');
    });

    testWidgets('non-student user is redirected to /login with wrong_role', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(vendorUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(studentRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/login');
      expect(router.state.uri.queryParameters['reason'], 'wrong_role');
    });
  });

  group('Vendor router redirects', () {
    testWidgets('unauthenticated user navigating to protected path is redirected to /login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(null)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(vendorRouterProvider);
      await pumpRouter(tester, container, router);
      router.go('/vendor');
      await tester.pump();

      expect(router.state.matchedLocation, '/login');
    });

    testWidgets('vendor user is redirected to /vendor from login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(vendorUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(vendorRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/vendor');
    });

    testWidgets('non-vendor user is redirected to /login with wrong_role', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(studentUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(vendorRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/login');
      expect(router.state.uri.queryParameters['reason'], 'wrong_role');
    });
  });

  group('Admin router redirects', () {
    testWidgets('unauthenticated user navigating to protected path is redirected to /login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(null)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(adminRouterProvider);
      await pumpRouter(tester, container, router);
      router.go('/admin');
      await tester.pump();

      expect(router.state.matchedLocation, '/login');
    });

    testWidgets('admin user is redirected to /admin from login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(adminUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(adminRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/admin');
    });

    testWidgets('non-admin user is redirected to /login with wrong_role', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(studentUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(adminRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/login');
      expect(router.state.uri.queryParameters['reason'], 'wrong_role');
    });
  });

  group('Unified App router role home redirects', () {
    testWidgets('student lands on /student', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(studentUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/student');
    });

    testWidgets('vendor lands on /vendor', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(vendorUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/vendor');
    });

    testWidgets('admin lands on /admin', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthController(adminUser)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await pumpRouter(tester, container, router);

      expect(router.state.matchedLocation, '/admin');
    });
  });
}
