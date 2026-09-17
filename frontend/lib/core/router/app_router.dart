import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_report_screens.dart';
import '../../features/admin/screens/admin_screens.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/student/screens/cart_screen.dart' show CartScreen, CheckoutScreen;
import '../../features/student/screens/mock_payment_screen.dart';
import '../../features/student/screens/order_screens.dart';
import '../../features/student/screens/payment_result_screen.dart';
import '../../features/student/screens/profile_screen.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/vendor_browse_screens.dart';
import '../../features/vendor/screens/vendor_menu_sales_screens.dart';
import '../../features/vendor/screens/vendor_screens.dart';

class Signaler extends ChangeNotifier {
  void ping() => notifyListeners();
}

final signalerProvider = Provider<Signaler>((ref) {
  final s = Signaler();
  ref.onDispose(s.dispose);
  return s;
});

final appRouterProvider = Provider<GoRouter>((ref) {
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

      final roleHome = switch (user.role) {
        'vendor' => '/vendor',
        'admin' => '/admin',
        _ => '/student',
      };

      if (loggingIn) return roleHome;
      if (loc.startsWith('/student') && user.role != 'student') return roleHome;
      if (loc.startsWith('/vendor') && user.role != 'vendor') return roleHome;
      if (loc.startsWith('/admin') && user.role != 'admin') return roleHome;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ---------- student ----------
      GoRoute(path: '/student', builder: (_, __) => const StudentHomeScreen()),
      GoRoute(path: '/student/vendors', builder: (_, __) => const VendorListScreen()),
      GoRoute(
          path: '/student/vendor/:id',
          builder: (_, s) => VendorMenuScreen(vendorId: s.pathParameters['id']!)),
      GoRoute(path: '/student/cart', builder: (_, __) => const CartScreen()),
      GoRoute(
          path: '/student/checkout/:vendorId',
          builder: (_, s) =>
              CheckoutScreen(vendorId: s.pathParameters['vendorId']!)),
      GoRoute(
          path: '/student/pay/:orderId',
          builder: (_, s) => MockPaymentScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(
          path: '/student/payment-result/:orderId',
          builder: (_, s) =>
              PaymentResultScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/student/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(
          path: '/student/orders/:id',
          builder: (_, s) => OrderTrackingScreen(orderId: s.pathParameters['id']!)),
      GoRoute(
          path: '/student/receipt/:id',
          builder: (_, s) => ReceiptScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/student/profile', builder: (_, __) => const ProfileScreen()),

      // ---------- vendor ----------
      GoRoute(path: '/vendor', builder: (_, __) => const VendorDashboardScreen()),
      GoRoute(path: '/vendor/orders', builder: (_, __) => const IncomingOrdersScreen()),
      GoRoute(
          path: '/vendor/orders/:id',
          builder: (_, s) => VendorOrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/vendor/menu', builder: (_, __) => const MenuManagementScreen()),
      GoRoute(path: '/vendor/sales', builder: (_, __) => const SalesSummaryScreen()),

      // ---------- admin ----------
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/vendors', builder: (_, __) => const VendorManagementScreen()),
      GoRoute(path: '/admin/transactions',
          builder: (_, __) => const TransactionListScreen()),
      GoRoute(path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const UserManagementScreen()),
    ],
  );
});
