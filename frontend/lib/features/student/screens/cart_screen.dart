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
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.canPop() ? context.pop() : context.go('/student')),
                const Text('Your Cart', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (!cart.isEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: Text('${cart.lines.length} items', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700))),
              ]),
            ),
            const MockPaymentBanner(),
            Expanded(
              child: cart.isEmpty
                  ? const EmptyView(icon: Icons.shopping_bag_outlined, message: 'Your cart is empty. Add items from a vendor menu.')
                  : ListView(
                      padding: const EdgeInsets.all(14),
                      children: cart.lines.values.map((line) => GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(children: [
                              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fastfood_rounded, color: AppColors.neonCyan, size: 22)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(line.item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(taka(line.item.priceTaka), style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 13)),
                              ])),
                              Container(
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
                                child: Row(children: [
                                  IconButton(icon: const Icon(Icons.remove_rounded, size: 18, color: Colors.white), onPressed: () => ref.read(cartProvider.notifier).decrement(line.item.id), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 36, height: 36)),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: Text('${line.qty}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 15))),
                                  IconButton(icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white), onPressed: () => ref.read(cartProvider.notifier).add(line.item), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 36, height: 36)),
                                ]),
                              ),
                            ]),
                          )).toList(),
                    ),
            ),
            if (!cart.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.bgMid.withOpacity(0.9), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
                child: SafeArea(
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary)), PriceText(cart.subtotal, fontSize: 16)]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text('৳5', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))]),
                    const SizedBox(height: 12),
                    NeonButton(label: 'PROCEED TO CHECKOUT  →', onPressed: () => context.go('/student/checkout/${cart.vendorId}')),
                  ]),
                ),
              ),
          ]),
        ),
      ),
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
    if (cart.isEmpty) return;
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
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
                const Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),
            const MockPaymentBanner(),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionHeader(title: 'Order Summary', subtitle: 'Server-verified prices'),
                    const SizedBox(height: 12),
                    ...cart.lines.values.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${l.qty} × ${taka(l.item.priceTaka)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                            ])),
                            Text(taka(l.qty * l.item.priceTaka), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                          ]),
                        )),
                    const Divider(color: AppColors.divider, height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary)), PriceText(cart.subtotal, fontSize: 14)]),
                    const SizedBox(height: 6),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text('৳5', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))]),
                    const Divider(color: AppColors.divider, height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)), ShaderMask(shaderCallback: (b) => AppColors.primaryGradient.createShader(b), child: Text(taka(cart.subtotal + 5), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)))]),
                  ]),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.neonGreen)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Secure • Server-computed totals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      Text('Client prices are never trusted', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonRed.withOpacity(0.2))), child: Text(_error!, style: const TextStyle(color: AppColors.neonRed, fontSize: 13))),
                NeonButton(label: 'PAY NOW  •  MOCK', icon: Icons.lock_rounded, busy: _busy, onPressed: _busy || cart.isEmpty ? null : _placeOrder),
                const SizedBox(height: 10),
                Center(child: Text('You will verify on the next screen', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
