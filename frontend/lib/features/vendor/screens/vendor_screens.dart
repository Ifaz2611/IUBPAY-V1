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
      (Icons.receipt_long_rounded, 'Incoming', '($incoming) live', '/vendor/orders'),
      (Icons.edit_note_rounded, 'Menu', 'Manage items', '/vendor/menu'),
      (Icons.bar_chart_rounded, 'Sales', 'Summary', '/vendor/sales'),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Vendor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
          Text(user?.name ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.successBorder)),
            child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)), const SizedBox(width: 6), Text('$incoming live', style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700))]),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.logout_rounded, size: 18), tooltip: 'Sign out', onPressed: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: wide
          ? Row(children: [
              SizedBox(
                width: 240,
                child: Container(
                  color: AppColors.surface,
                  child: ListView(children: [
                    const SizedBox(height: 12),
                    for (final t in navTiles)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: AppCard(
                          onTap: () => context.go(t.$4),
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(t.$1, color: AppColors.textSecondary, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.$2, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              Container(width: 1, color: AppColors.border),
              const Expanded(child: IncomingOrdersView()),
            ])
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final t in navTiles)
                  AppCard(
                    onTap: () => context.go(t.$4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Icon(t.$1, color: AppColors.textSecondary, size: 22)),
                      const SizedBox(height: 10),
                      Text(t.$2, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ]),
                  ),
              ],
            ),
    );
  }
}

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(title: 'Incoming orders', subtitle: 'Paid orders needing attention', onBack: () => context.go('/vendor')),
        body: const IncomingOrdersView(),
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
          return const EmptyView(icon: Icons.room_service_outlined, message: 'No live paid orders. New paid orders appear here automatically.');
        }
        return RefreshIndicator(
          color: AppColors.brand,
          backgroundColor: AppColors.surface,
          onRefresh: () async => ref.invalidate(myVendorOrdersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: live.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = live[i];
              return AppCard(
                onTap: () => context.go('/vendor/orders/${o.id}'),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderStrong)),
                    child: Text(o.pickupCode, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.8, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.orderNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${taka(o.totalAmount)} • ${o.items.length} items', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ])),
                  StatusChip(status: o.status),
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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
          title: 'Order',
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor/orders');
            }
          }),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(
            child: Column(children: [
              Center(child: StatusChip(status: o.status)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('PICKUP', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(width: 10),
                  Text(o.pickupCode, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 5, fontSize: 18)),
                ]),
              ),
              if (o.createdAt != null) ...[const SizedBox(height: 8), Text(formatDateTime(o.createdAt!), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))],
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...o.items.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                    Expanded(child: Text(it.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Text('${it.quantity} × ${taka(it.unitPrice)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text(taka(it.subtotal), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]))),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)), PriceText(o.totalAmount)]),
            ]),
          ),
          const SizedBox(height: 12),
          _action(context, ref, o, 'ACCEPTED', Icons.check_rounded, 'Accept order'),
          _action(context, ref, o, 'PREPARING', Icons.soup_kitchen_rounded, 'Start preparing'),
          _action(context, ref, o, 'READY', Icons.done_all_rounded, 'Mark ready'),
          _action(context, ref, o, 'COLLECTED', Icons.takeout_dining_rounded, 'Mark collected'),
          _action(context, ref, o, 'REJECTED', Icons.block_rounded, 'Reject & refund', isDestructive: true),
        ]),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, Order o, String target, IconData icon, String label, {bool isDestructive = false}) {
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
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: isDestructive
            ? OutlinedButton.icon(onPressed: () => _setStatus(context, ref, o.id, target), icon: Icon(icon, size: 16, color: AppColors.error), label: Text(label, style: const TextStyle(color: AppColors.error)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.errorBorder)))
            : FilledButton.icon(onPressed: () => _setStatus(context, ref, o.id, target), icon: Icon(icon, size: 16), label: Text(label)),
      ),
    );
  }
}
