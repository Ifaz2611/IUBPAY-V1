import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _promoApplied;
  int _tip = 0; // 0,5,10

  int get _discount {
    if (_promoApplied == null) return 0;
    final cart = ref.read(cartProvider);
    if (_promoApplied!.toUpperCase() == 'CAMPUS10') return (cart.subtotal * 0.10).round();
    if (_promoApplied!.toUpperCase() == 'IUB5') return 5;
    return 0;
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    if (code == 'CAMPUS10' || code == 'IUB5') {
      HapticFeedback.selectionClick();
      setState(() => _promoApplied = code);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo $code applied!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid code: $code — try CAMPUS10 or IUB5'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartTotal = cart.subtotal + 5 + _tip - _discount;
    final suggestionsAsync = cart.vendorId == null ? null : ref.watch(vendorMenuProvider(cart.vendorId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Your cart',
        subtitle: cart.isEmpty ? 'Add something tasty' : '${cart.lines.values.fold(0, (s, l) => s + l.qty)} items • ${cart.lines.length} dishes',
        onBack: () => context.canPop() ? context.pop() : context.go('/student'),
        action: cart.isEmpty
            ? null
            : TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear cart?'),
                      content: const Text('Remove all items?'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Clear'))],
                    ),
                  );
                  if (ok == true) {
                    HapticFeedback.mediumImpact();
                    ref.read(cartProvider.notifier).reset();
                  }
                },
                child: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 13)),
              ),
      ),
      body: Column(children: [
        const MockPaymentBanner(),
        if (!cart.isEmpty)
          Container(
            color: AppColors.brandSubtle,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(child: Text('Swipe an item left to remove • Tap −/+ to adjust', style: TextStyle(color: AppColors.brand.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w500))),
              Text('${cart.lines.values.fold(0, (s, l) => s + l.qty)} pcs', style: const TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        Expanded(
          child: cart.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: [
                  const SizedBox(height: 20),
                  const EmptyView(icon: Icons.shopping_bag_outlined, message: 'Your cart is empty. Add items from a vendor menu.'),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Browse vendors', icon: Icons.storefront_rounded, onPressed: () => context.go('/student/vendors')),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.textTertiary), SizedBox(width: 8), Text('Tips', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
                      const SizedBox(height: 8),
                      _TipRow(icon: Icons.search_rounded, text: 'Search vendors from the home screen'),
                      _TipRow(icon: Icons.favorite_border_rounded, text: 'Save favorite vendors & dishes'),
                      _TipRow(icon: Icons.bolt_rounded, text: 'Order before 12:30 to skip rush'),
                    ]),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cart.lines.values.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(line.item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadii.md)),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.delete_outline_rounded, color: Colors.white), SizedBox(width: 6), Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
                            ),
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              // remove by decrementing to zero
                              final qty = line.qty;
                              for (var i = 0; i < qty; i++) {
                                ref.read(cartProvider.notifier).decrement(line.item.id);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${line.item.name} removed'), behavior: SnackBarBehavior.floating));
                            },
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withOpacity(0.15))),
                                    child: const Icon(Icons.fastfood_rounded, color: AppColors.brand, size: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(line.item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    PriceText(line.item.priceTaka, fontSize: 12, color: AppColors.textSecondary, bold: false),
                                    const SizedBox(width: 6),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.border)), child: Text(line.item.category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600))),
                                  ]),
                                  Text('${line.qty} × ${taka(line.item.priceTaka)} = ${taka(line.qty * line.item.priceTaka)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                ])),
                                Container(
                                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                  child: Row(children: [
                                    IconButton(icon: const Icon(Icons.remove_rounded, size: 16), onPressed: () { HapticFeedback.selectionClick(); ref.read(cartProvider.notifier).decrement(line.item.id); }, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32, height: 32)),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                                        child: Text('${line.qty}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13))),
                                    IconButton(icon: const Icon(Icons.add_rounded, size: 16), onPressed: () { HapticFeedback.selectionClick(); final ok = ref.read(cartProvider.notifier).add(line.item); if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 20 per item'))); }, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32, height: 32)),
                                  ]),
                                ),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [PriceText(line.qty * line.item.priceTaka, fontSize: 13), const Text('total', style: TextStyle(color: AppColors.textTertiary, fontSize: 10))]),
                              ]),
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    // Promo code
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.local_offer_outlined, size: 14, color: AppColors.brand), SizedBox(width: 8), Text('Promo code', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
                        const SizedBox(height: 2),
                        const Text('Try CAMPUS10 (10% off) or IUB5 (5৳ off) — demo only', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _promoCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter code',
                                isDense: true,
                                prefixIcon: const Icon(Icons.confirmation_num_outlined, size: 16),
                                suffixIcon: _promoApplied != null ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() { _promoApplied = null; _promoCtrl.clear(); })) : null,
                              ),
                              onSubmitted: (_) => _applyPromo(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(height: 40, child: FilledButton(onPressed: _applyPromo, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)), child: Text(_promoApplied == null ? 'Apply' : 'Applied'))),
                        ]),
                        if (_promoApplied != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.successBorder)),
                            child: Row(children: [const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success), const SizedBox(width: 8), Text('$_promoApplied • -${taka(_discount)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)), const Spacer(), TextButton(onPressed: () => setState(() { _promoApplied = null; _promoCtrl.clear(); }), child: const Text('Remove', style: TextStyle(fontSize: 11)))]),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Tip selector
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.volunteer_activism_outlined, size: 14, color: AppColors.textSecondary), SizedBox(width: 8), Text('Add a tip (optional)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
                        const SizedBox(height: 8),
                        Row(children: [
                          for (final v in [0, 5, 10, 20])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(v == 0 ? 'No tip' : '+${taka(v)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _tip == v ? Colors.white : AppColors.textSecondary)),
                                selected: _tip == v,
                                selectedColor: AppColors.brand,
                                backgroundColor: AppColors.surfaceMuted,
                                side: BorderSide(color: _tip == v ? AppColors.brand : AppColors.border),
                                showCheckmark: false,
                                onSelected: (_) { HapticFeedback.selectionClick(); setState(() => _tip = v); },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                              ),
                            ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Note
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary), SizedBox(width: 8), Text('Note for vendor', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'e.g. less spicy, no onion…', isDense: true),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Suggestions
                    if (suggestionsAsync != null)
                      suggestionsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (menu) {
                          final others = menu.where((m) => !cart.lines.containsKey(m.id) && m.isAvailable).take(3).toList();
                          if (others.isEmpty) return const SizedBox.shrink();
                          return AppCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Row(children: [Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.brand), SizedBox(width: 8), Text('Add more?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
                              const SizedBox(height: 10),
                              ...others.map((it) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.lunch_dining_rounded, size: 16, color: AppColors.brand)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(it.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text(taka(it.priceTaka), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                                      OutlinedButton(onPressed: () { HapticFeedback.selectionClick(); ref.read(cartProvider.notifier).add(it); }, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32)), child: const Text('Add', style: TextStyle(fontSize: 11))),
                                    ]),
                                  )),
                            ]),
                          );
                        },
                      ),
                  ],
                ),
        ),
        if (!cart.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: SafeArea(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), PriceText(cart.subtotal, fontSize: 14)]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(taka(5), style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))]),
                if (_tip > 0) ...[const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tip', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(taka(_tip), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])],
                if (_discount > 0) ...[const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Discount ($_promoApplied)', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)), Text('-${taka(_discount)}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700))])],
                const Divider(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)), PriceText(cartTotal, fontSize: 18)]),
                const SizedBox(height: 4),
                Text('${cart.lines.values.fold(0, (s, l) => s + l.qty)} items • Pickup at counter', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Proceed to checkout • ${taka(cartTotal)}', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/student/checkout/${cart.vendorId}')),
                const SizedBox(height: 6),
                TextButton.icon(onPressed: () => context.go('/student/vendors'), icon: const Icon(Icons.add_rounded, size: 14), label: const Text('Continue shopping', style: TextStyle(fontSize: 12))),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(icon, size: 12, color: AppColors.textTertiary), const SizedBox(width: 8), Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))]));
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
      appBar: AppTopBar(
          title: 'Checkout',
          subtitle: 'Confirm your order',
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/cart');
            }
          }),
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
