import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: cart.isEmpty
              ? const EmptyView(
                  icon: Icons.shopping_cart_outlined,
                  message: 'Your cart is empty. Add items from a vendor menu.')
              : ListView(
                  children: cart.lines.values.map((line) => Card(
                        child: ListTile(
                          title: Text(line.item.name),
                          subtitle: PriceText(line.item.priceTaka, bold: false),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .decrement(line.item.id)),
                            Text('${line.qty}',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .add(line.item)),
                          ]),
                        ),
                      )).toList(),
                ),
        ),
      ]),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Subtotal'),
                    PriceText(cart.subtotal),
                  ]),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.go('/student/checkout/${cart.vendorId}'),
                    child: const Text('Proceed to Checkout'),
                  ),
                ]),
              ),
            ),
    );
  }
}

/// Creates the order on the backend (totals are computed server-side).
class CheckoutScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const CheckoutScreen({super.key, required this.vendorId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.post('/orders', data: {
        'vendor_id': widget.vendorId,
        'items': cart.lines.values
            .map((l) => {'menu_item_id': l.item.id, 'quantity': l.qty})
            .toList(),
        'idempotency_key':
            DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      });
      if (!mounted) return;
      ref.read(cartProvider.notifier).reset();
      context.go('/student/pay/${r.data['id']}');
    } catch (e) {
      setState(() { _busy = false; _error = apiErrorMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const MockPaymentBanner(),
        const SizedBox(height: 12),
        ...cart.lines.values.map((l) => ListTile(
              dense: true,
              title: Text(l.item.name),
              subtitle: Text('${l.qty} × ${l.item.priceTaka}'),
              trailing:
                  PriceText(l.qty * l.item.priceTaka, fontSize: 15),
            )),
        const Divider(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Subtotal'), PriceText(cart.subtotal)]),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Service fee'), Text('৳5')]),
        const Divider(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          PriceText(cart.subtotal + 5, fontSize: 19),
        ]),
        const SizedBox(height: 24),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        FilledButton.icon(
          icon: _busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.lock_outline),
          label: const Text('Pay Now (MOCK)'),
          onPressed: _busy || cart.isEmpty ? null : _placeOrder,
        ),
      ]),
    );
  }
}
