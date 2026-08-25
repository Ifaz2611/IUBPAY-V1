import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
        data: (list) => list.isEmpty
            ? const EmptyView(icon: Icons.receipt_long,
                message: 'No orders yet. Time to grab some biryani!')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myOrdersProvider),
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final o = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(o.orderNumber,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${o.items.length} items · Total ৳${o.totalAmount}'),
                        trailing: StatusBadge(status: o.status),
                        onTap: () => context.go('/student/orders/${o.id}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// Active order tracking with auto-refresh while the food is being prepared.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _timer;

  static const _steps = ['PAID', 'ACCEPTED', 'PREPARING', 'READY', 'COLLECTED'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final active = order.valueOrNull;
    final stepIndex = active == null ? -1 : _steps.indexOf(active.status);

    return Scaffold(
      appBar: AppBar(title: Text(active?.orderNumber ?? 'Order')),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e,
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: StatusBadge(status: o.status)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              const Text('Pickup code',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(o.pickupCode,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6)),
            ]),
            Column(children: [
              const Text('Total',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              PriceText(o.totalAmount, fontSize: 24),
            ]),
          ]),
          if (stepIndex >= 0) ...[
            const SizedBox(height: 26),
            ...List.generate(_steps.length, (i) => ListTile(
                  leading: Icon(
                    i < stepIndex ? Icons.check_circle
                        : i == stepIndex ? Icons.radio_button_checked
                        : Icons.circle_outlined,
                    color: i <= stepIndex ? Colors.green : Colors.grey,
                  ),
                  title: Text(switch (_steps[i]) {
                    'PAID' => 'Payment verified',
                    'ACCEPTED' => 'Vendor accepted',
                    'PREPARING' => 'Being prepared',
                    'READY' => 'Ready for pickup',
                    _ => 'Collected',
                  }),
                )),
          ] else ...[
            const SizedBox(height: 26),
            Text('Order status: ${o.status}',
                style: const TextStyle(fontSize: 16)),
          ],
          const Divider(height: 32),
          ...o.items.map((it) => ListTile(
                dense: true,
                title: Text(it.name),
                subtitle: Text('${it.quantity} × ${it.unitPrice}'),
                trailing: PriceText(it.subtotal, bold: false),
              )),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt),
            label: const Text('View digital receipt'),
            onPressed: () => context.go('/student/receipt/${o.id}'),
          ),
          const SizedBox(height: 8),
          if (['PENDING_PAYMENT', 'PAID'].contains(o.status))
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
              onPressed: () async {
                try {
                  await ref.read(dioProvider)
                      .post('/orders/${o.id}/cancel');
                  ref.invalidate(orderDetailProvider(o.id));
                  ref.invalidate(myOrdersProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(apiErrorMessage(e))));
                  }
                }
              },
            ),
        ]),
      ),
    );
  }
}

/// Digital receipt with item snapshots and payment record.
class ReceiptScreen extends ConsumerWidget {
  final String orderId;
  const ReceiptScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Receipt')),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e,
            onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                Center(child: Text('IUB CAFETERIA — PROTOTYPE',
                    style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 4),
                Center(child: Text(o.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                const Divider(height: 28),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text(
                            '${it.name}\n  ${it.quantity} × ${it.unitPrice}')),
                        PriceText(it.subtotal, fontSize: 15),
                      ]),
                    )),
                const Divider(height: 28),
                _row('Subtotal', o.subtotal),
                _row('Service fee', o.serviceFee),
                const Divider(),
                _row('TOTAL', o.totalAmount, bold: true),
                const Divider(height: 28),
                Text(
                    'Payment: ${o.latestPayment?.status ?? "NOT_PAID"}'
                    '${o.latestPayment != null ? "\nTxn: ${o.latestPayment!.id}" : ""}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Center(child: Text('Pickup code: ${o.pickupCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, int amount, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), PriceText(amount, fontSize: 15, bold: bold)],
      );
}
