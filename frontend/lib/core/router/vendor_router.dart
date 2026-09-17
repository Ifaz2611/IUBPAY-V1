import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/vendor/screens/vendor_menu_sales_screens.dart';
import '../../features/vendor/screens/vendor_screens.dart';
import 'app_router.dart' show signalerProvider;

final vendorRouterProvider = Provider<GoRouter>((ref) {
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
      if (user.role != 'vendor') return '/login';
      if (loggingIn) return '/vendor';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/vendor', builder: (_, __) => const VendorDashboardScreen()),
      GoRoute(path: '/vendor/orders', builder: (_, __) => const IncomingOrdersScreen()),
      GoRoute(path: '/vendor/orders/:id', builder: (_, s) => VendorOrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/vendor/menu', builder: (_, __) => const MenuManagementScreen()),
      GoRoute(path: '/vendor/sales', builder: (_, __) => const SalesSummaryScreen()),
    ],
  );
});
