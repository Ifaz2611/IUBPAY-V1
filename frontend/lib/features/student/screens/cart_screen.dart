import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Your cart',
        subtitle: cart.isEmpty ? null : '${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'}',
        onBack: () => context.canPop() ? context.pop() : context.go('/student'),
      ),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: cart.isEmpty
              ? const EmptyView(icon: Icons.shopping_bag_outlined, message: 'Your cart is empty. Add items from a vendor menu.', actionLabel: 'Browse vendors',)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final line = cart.lines.values.elementAt(idx);
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.fastfood_rounded, color: AppColors.textSecondary, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(line.item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          PriceText(line.item.priceTaka, fontSize: 13, color: AppColors.textSecondary, bold: false),
                        ])),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            IconButton(icon: const Icon(Icons.remove_rounded, size: 16), onPressed: () => ref.read(cartProvider.notifier).decrement(line.item.id), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32, height: 32)),
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                                child: Text('${line.qty}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))),
                            IconButton(icon: const Icon(Icons.add_rounded, size: 16), onPressed: () => ref.read(cartProvider.notifier).add(line.item), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32, height: 32)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        PriceText(line.qty * line.item.priceTaka, fontSize: 13),
                      ]),
                    );
                  },
                ),
        ),
        if (!cart.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: SafeArea(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), PriceText(cart.subtotal, fontSize: 15)]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(taka(5), style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))]),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)), PriceText(cart.subtotal + 5, fontSize: 16)]),
                const SizedBox(height: 14),
                PrimaryButton(label: 'Proceed to checkout', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/student/checkout/${cart.vendorId}')),
              ]),
            ),
          ),
      ]),
    );
  }
}

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
    if (cart.isEmpty || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.post('/orders', data: {
        'vendor_id': widget.vendorId,
        'items': cart.lines.values.map((l) => {'menu_item_id': l.item.id, 'quantity': l.qty}).toList(),
        'idempotency_key': DateTime.now().microsecondsSinceEpoch.toRadixString(36),
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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Checkout', subtitle: 'Confirm your order', onBack: () => context.pop()),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Order summary', subtitle: 'Prices verified by the server'),
                const SizedBox(height: 14),
                ...cart.lines.values.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${l.qty} × ${taka(l.item.priceTaka)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ])),
                        Text(taka(l.qty * l.item.priceTaka), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    )),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), PriceText(cart.subtotal, fontSize: 14)]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(taka(5), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))]),
                const Divider(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)), PriceText(cart.subtotal + 5, fontSize: 18)]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.successBorder)),
              child: const Row(children: [
                Icon(Icons.verified_outlined, size: 16, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Server-computed totals', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('Client prices are never trusted', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ])),
              ]),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.errorBorder)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ])),
            PrimaryButton(label: 'Pay now', icon: Icons.lock_outline_rounded, busy: _busy, onPressed: _busy || cart.isEmpty ? null : _placeOrder),
            const SizedBox(height: 8),
            const Center(child: Text('You’ll confirm payment on the next screen', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
          ]),
        ),
      ]),
    );
  }
}
