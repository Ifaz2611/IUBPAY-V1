import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../student/providers/student_providers.dart' show orderDetailProvider;

final myVendorOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/orders');
  return (r.data as List).map((e) => Order.fromJson(e)).toList();
});
final myVendorMenuProvider = FutureProvider<List<MenuItem>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/menu');
  return (r.data as List).map((e) => MenuItem.fromJson(e)).toList();
});

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final wide = MediaQuery.of(context).size.width > 800;
    final orders = ref.watch(myVendorOrdersProvider);
    final incoming = orders.valueOrNull?.where((o) => ['PAID', 'ACCEPTED', 'PREPARING'].contains(o.status)).length ?? 0;
    final navTiles = [
      (Icons.receipt_long_rounded, 'Incoming', '($incoming) LIVE', '/vendor/orders', [AppColors.neonCyan, const Color(0xFF06B6D4)]),
      (Icons.edit_note_rounded, 'Menu', 'Manage items', '/vendor/menu', [AppColors.neonPurple, const Color(0xFF8B5CF6)]),
      (Icons.bar_chart_rounded, 'Sales', 'Summary', '/vendor/sales', [AppColors.neonPink, const Color(0xFFF43F5E)]),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('VENDOR CONSOLE',
                        style: TextStyle(
                            color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Text(user?.name ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen)),
                    const SizedBox(width: 6),
                    Text('$incoming LIVE',
                        style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (wide)
              Expanded(
                child: Row(children: [
                  SizedBox(
                    width: 260,
                    child: ListView(children: [
                      for (final t in navTiles)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GlassCard(
                            onTap: () => context.go(t.$4),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration:
                                    BoxDecoration(gradient: LinearGradient(colors: t.$5), borderRadius: BorderRadius.circular(10)),
                                child: Icon(t.$1, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                  const VerticalDivider(color: AppColors.divider, width: 1),
                  const Expanded(child: IncomingOrdersView()),
                ]),
              )
            else
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(14),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    for (final t in navTiles)
                      GlassCard(
                        onTap: () => context.go(t.$4),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration:
                                BoxDecoration(gradient: LinearGradient(colors: t.$5), borderRadius: BorderRadius.circular(14)),
                            child: Icon(t.$1, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 10),
                          Text(t.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.go('/vendor'),
                  ),
                  const Text('Incoming Orders',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ]),
              ),
              const Expanded(child: IncomingOrdersView()),
            ]),
          ),
        ),
      );
}

class IncomingOrdersView extends ConsumerWidget {
  const IncomingOrdersView({super.key});
  static const _liveStatuses = ['PAID', 'ACCEPTED', 'PREPARING'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myVendorOrdersProvider);
    return orders.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorOrdersProvider)),
      data: (list) {
        final live = list.where((o) => _liveStatuses.contains(o.status)).toList()
          ..sort((a, b) => a.createdAt == null || b.createdAt == null ? 0 : a.createdAt!.compareTo(b.createdAt!));
        if (live.isEmpty) {
          return const EmptyView(icon: Icons.room_service_outlined, message: 'No live paid orders. New paid orders appear here.');
        }
        return RefreshIndicator(
          color: AppColors.neonCyan,
          backgroundColor: AppColors.bgCard,
          onRefresh: () async => ref.invalidate(myVendorOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: live.length,
            itemBuilder: (_, i) {
              final o = live[i];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => context.go('/vendor/orders/${o.id}'),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.22)),
                    ),
                    child: Text(o.pickupCode,
                        style:
                            const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('৳${o.totalAmount} • ${o.items.length} items',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ]),
                  ),
                  StatusBadge(status: o.status),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}

class VendorOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const VendorOrderDetailScreen({super.key, required this.orderId});
  Future<void> _setStatus(BuildContext context, WidgetRef ref, String orderId, String status) async {
    try {
      await ref.read(dioProvider).patch('/orders/$orderId/status', data: {'status': status});
      ref.invalidate(myVendorOrdersProvider);
      ref.invalidate(orderDetailProvider(orderId));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Text('Order Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: order.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
                data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
                  GlassCard(
                    child: Column(children: [
                      Center(child: StatusBadge(status: o.status)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('PICKUP',
                              style: TextStyle(
                                  color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(width: 10),
                          Text(o.pickupCode,
                              style: const TextStyle(
                                  color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 20)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ...o.items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text(it.name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                            Text('${it.quantity} × ${it.unitPrice}',
                                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                            const SizedBox(width: 10),
                            Text(taka(it.subtotal),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      const Divider(color: AppColors.divider, height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        Text('৳${o.totalAmount}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _action(context, ref, o, 'ACCEPTED', Icons.check_rounded, 'Accept order', AppColors.neonCyan),
                  _action(context, ref, o, 'PREPARING', Icons.soup_kitchen_rounded, 'Start preparing', AppColors.neonPurple),
                  _action(context, ref, o, 'READY', Icons.done_all_rounded, 'Mark READY', AppColors.neonGreen),
                  _action(context, ref, o, 'COLLECTED', Icons.takeout_dining_rounded, 'Mark COLLECTED', AppColors.textSecondary),
                  _action(context, ref, o, 'REJECTED', Icons.block_rounded, 'Reject & refund', AppColors.neonRed),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, Order o, String target, IconData icon, String label, Color color) {
    final allowed = switch (target) {
      'ACCEPTED' => o.status == 'PAID',
      'REJECTED' => ['PAID', 'ACCEPTED'].contains(o.status),
      'PREPARING' => ['ACCEPTED'].contains(o.status),
      'READY' => o.status == 'PREPARING',
      'COLLECTED' => o.status == 'READY',
      _ => false,
    };
    if (!allowed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _setStatus(context, ref, o.id, target),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 12)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }
}
