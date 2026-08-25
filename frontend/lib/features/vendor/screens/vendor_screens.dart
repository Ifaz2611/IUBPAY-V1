import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------- providers ----------------

final myVendorOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/orders');
  return (r.data as List).map((e) => Order.fromJson(e)).toList();
});

final myVendorMenuProvider = FutureProvider<List<MenuItem>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/menu');
  return (r.data as List).map((e) => MenuItem.fromJson(e)).toList();
});

// ---------------- dashboard (responsive two-pane on wide screens) ----------

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final wide = MediaQuery.of(context).size.width > 800;
    final orders = ref.watch(myVendorOrdersProvider);
    final incoming = orders.valueOrNull
            ?.where((o) =>
                ['PAID', 'ACCEPTED', 'PREPARING'].contains(o.status))
            .length ??
        0;

    final navTiles = [
      (Icons.receipt_long, 'Incoming Orders ($incoming)', '/vendor/orders'),
      (Icons.edit_menu, 'Manage Menu', '/vendor/menu'),
      (Icons.bar_chart, 'Sales Summary', '/vendor/sales'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Vendor Dashboard — ${user?.name ?? ""}'),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }),
          ]),
      body: wide
          ? Row(children: [
              SizedBox(
                  width: 280,
                  child: Column(
                      children: [for (final t in navTiles)
                        ListTile(leading: Icon(t.$1), title: Text(t.$2),
                            onTap: () => context.go(t.$3))])),
              const VerticalDivider(width: 1),
              const Expanded(child: IncomingOrdersView()),
            ])
          : GridView.count(padding: const EdgeInsets.all(16),
              crossAxisCount: 2, children: [
              for (final t in navTiles)
                Card(
                  child: InkWell(borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(t.$3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.$1, size: 44, color: const Color(0xFF0E7C7B)),
                          const SizedBox(height: 8),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(t.$2, textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight:
                                      FontWeight.w600))),
                        ])),
                ),
            ]),
    );
  }
}

// ---------------- incoming orders ----------------

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Incoming Orders')),
          body: const IncomingOrdersView());
}

class IncomingOrdersView extends ConsumerWidget {
  const IncomingOrdersView({super.key});

  static const _liveStatuses = ['PAID', 'ACCEPTED', 'PREPARING'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myVendorOrdersProvider);
    return orders.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e,
          onRetry: () => ref.invalidate(myVendorOrdersProvider)),
      data: (list) {
        final live = list.where((o) => _liveStatuses.contains(o.status)).toList()
          ..sort((a, b) => a.createdAt == null || b.createdAt == null
              ? 0 : a.createdAt!.compareTo(b.createdAt!));
        if (live.isEmpty) {
          return const EmptyView(icon: Icons.room_service_outlined,
              message: 'No live paid orders. New paid orders appear here.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myVendorOrdersProvider),
          child: ListView.builder(itemCount: live.length, itemBuilder: (_, i) {
            final o = live[i];
            return Card(
              child: ListTile(
                leading: Text(o.pickupCode,
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold)),
                title: Text('${o.orderNumber} · ৳${o.totalAmount}'),
                subtitle: StatusBadge(status: o.status),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/vendor/orders/${o.id}'),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------- order detail with lifecycle actions ----------------

class VendorOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const VendorOrderDetailScreen({super.key, required this.orderId});

  Future<void> _setStatus(BuildContext context, WidgetRef ref,
      String orderId, String status) async {
    try {
      await ref.read(dioProvider)
          .patch('/orders/$orderId/status', data: {'status': status});
      ref.invalidate(myVendorOrdersProvider);
      ref.invalidate(orderDetailProvider(orderId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e,
            onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: StatusBadge(status: o.status)),
          const SizedBox(height: 12),
          Center(child: Text('Pickup code: ${o.pickupCode}',
              style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: 4))),
          const Divider(height: 30),
          ...o.items.map((it) => ListTile(dense: true,
              title: Text(it.name),
              subtitle: Text('${it.quantity} × ${it.unitPrice}'),
              trailing: PriceText(it.subtotal))),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            PriceText(o.totalAmount, fontSize: 18),
          ]),
          const SizedBox(height: 24),
          _action(context, ref, o, 'ACCEPTED', Icons.check,
              'Accept order', Colors.teal),
          _action(context, ref, o, 'PREPARING', Icons.soup_kitchen,
              'Start preparing', Colors.indigo),
          _action(context, ref, o, 'READY', Icons.done_all,
              'Mark READY for pickup', Colors.green),
          _action(context, ref, o, 'COLLECTED', Icons.takeout_dining,
              'Mark COLLECTED', Colors.blueGrey),
          _action(context, ref, o, 'REJECTED', Icons.block,
                  'Reject & refund', Colors.red),
        ]),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, Order o,
      String target, IconData icon, String label, Color color) {
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
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        icon: Icon(icon),
        label: Text(label),
        onPressed: () => _setStatus(context, ref, o.id, target),
      ),
    );
  }
}
