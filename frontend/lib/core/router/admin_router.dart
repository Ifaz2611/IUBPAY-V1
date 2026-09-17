import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/admin/screens/admin_report_screens.dart';
import '../../features/admin/screens/admin_screens.dart';
import 'app_router.dart' show signalerProvider;

final adminRouterProvider = Provider<GoRouter>((ref) {
  final signaler = ref.watch(signalerProvider);
  ref.listen(authProvider, (_, __) => signaler.ping());
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: signaler,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final user = auth.value;
      final loading = auth.isLoading && !auth.hasValue;
      final loc = state.matchedLocation;
      if (loading) return loc == '/splash' ? '/splash' : null;
      final loggingIn = loc == '/login' || loc == '/splash';
      if (user == null) return loggingIn ? null : '/login';
      if (user.role != 'admin') return '/login';
      if (loggingIn) return '/admin';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/vendors', builder: (_, __) => const VendorManagementScreen()),
      GoRoute(path: '/admin/transactions', builder: (_, __) => const TransactionListScreen()),
      GoRoute(path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const UserManagementScreen()),
    ],
  );
});
