import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'app_router.dart' show signalerProvider;

final studentRouterProvider = Provider<GoRouter>((ref) {
  final signaler = ref.watch(signalerProvider);
  ref.listen(authProvider, (_, __) => signaler.ping());
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: signaler,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final user = auth.valueOrNull;
      final loading = auth.isLoading && !auth.hasValue;
      final loc = state.matchedLocation;
      if (loading) return loc == '/splash' ? '/splash' : null;
      final loggingIn = loc == '/login' || loc == '/splash';
      if (user == null) return loggingIn ? null : '/login';
      if (user.role != 'student') return '/login';
      if (loggingIn) return '/student';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/student', builder: (_, __) => const StudentHomeScreen()),
      GoRoute(path: '/student/vendors', builder: (_, __) => const VendorListScreen()),
      GoRoute(path: '/student/vendor/:id', builder: (_, s) => VendorMenuScreen(vendorId: s.pathParameters['id']!)),
      GoRoute(path: '/student/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/student/checkout/:vendorId', builder: (_, s) => CheckoutScreen(vendorId: s.pathParameters['vendorId']!)),
      GoRoute(path: '/student/pay/:orderId', builder: (_, s) => MockPaymentScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/student/payment-result/:orderId', builder: (_, s) => PaymentResultScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/student/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/student/orders/:id', builder: (_, s) => OrderTrackingScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/student/receipt/:id', builder: (_, s) => ReceiptScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/student/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
