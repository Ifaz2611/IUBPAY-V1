import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/student')), const Text('My Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)), const Spacer(), IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary), onPressed: () => ref.invalidate(myOrdersProvider))])),
            Expanded(
              child: orders.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
                data: (list) => list.isEmpty
                    ? const EmptyView(icon: Icons.receipt_long_rounded, message: 'No orders yet. Time to grab some biryani!')
                    : RefreshIndicator(
                        color: AppColors.neonCyan, backgroundColor: AppColors.bgCard,
                        onRefresh: () async => ref.invalidate(myOrdersProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final o = list[i];
                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              onTap: () => context.go('/student/orders/${o.id}'),
                              child: Row(children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.neonCyan)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(o.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${o.items.length} items  •  ৳${o.totalAmount}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ])),
                                StatusBadge(status: o.status),
                              ]),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _timer;
  static const _steps = ['PAID', 'ACCEPTED', 'PREPARING', 'READY', 'COLLECTED'];
  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 5), (_) { if (mounted) ref.invalidate(orderDetailProvider(widget.orderId)); }); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final active = order.valueOrNull;
    final stepIndex = active == null ? -1 : _steps.indexOf(active.status);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/student/orders')), Text(active?.orderNumber ?? 'Order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const Spacer(), Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen, boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 8)])), const SizedBox(width: 6), const Text('LIVE', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))])),
            Expanded(
              child: order.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
                data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
                  GlassCard(
                    child: Column(children: [
                      Center(child: StatusBadge(status: o.status)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: _metric('PICKUP CODE', o.pickupCode, AppColors.neonCyan, isCode: true)),
                        Container(width: 1, height: 56, color: Colors.white.withOpacity(0.06)),
                        Expanded(child: _metric('TOTAL', '৳${o.totalAmount}', AppColors.neonPurple)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionHeader(title: 'Journey', subtitle: 'Auto-refresh every 5s'),
                      const SizedBox(height: 14),
                      if (stepIndex >= 0)
                        ...List.generate(_steps.length, (i) {
                          final done = i < stepIndex; final cur = i == stepIndex;
                          final label = switch (_steps[i]) { 'PAID' => 'Payment verified', 'ACCEPTED' => 'Vendor accepted', 'PREPARING' => 'Being prepared', 'READY' => 'Ready for pickup', _ => 'Collected' };
                          final Color c = done ? AppColors.neonGreen : cur ? AppColors.neonCyan : AppColors.textTertiary;
                          return Row(children: [
                            Column(children: [
                              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(cur ? 0.18 : done ? 0.14 : 0.06), border: Border.all(color: c.withOpacity(0.5))), child: Icon(done ? Icons.check_rounded : cur ? Icons.radio_button_checked_rounded : Icons.circle_outlined, size: 16, color: c)),
                              if (i != _steps.length - 1) Container(width: 1.5, height: 18, color: i < stepIndex ? AppColors.neonGreen.withOpacity(0.35) : Colors.white.withOpacity(0.06)),
                            ]),
                            const SizedBox(width: 12),
                            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 18), child: Text(label, style: TextStyle(color: cur ? Colors.white : done ? AppColors.textPrimary : AppColors.textTertiary, fontWeight: cur ? FontWeight.w800 : FontWeight.w600, fontSize: 13)))),
                            if (cur) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Text('NOW', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900))),
                          ]);
                        })
                      else
                        Text('Order status: ${o.status}', style: const TextStyle(color: AppColors.textSecondary)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...o.items.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(it.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))), Text('${it.quantity} × ${it.unitPrice}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)), const SizedBox(width: 12), Text(taka(it.subtotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))])),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  NeonButton(label: 'VIEW DIGITAL RECEIPT', icon: Icons.receipt_rounded, onPressed: () => context.go('/student/receipt/${o.id}'), gradient: const [Color(0xFF1E3A8A), AppColors.neonPurple]),
                  const SizedBox(height: 8),
                  if (['PENDING_PAYMENT', 'PAID'].contains(o.status))
                    GestureDetector(
                      onTap: () async {
                        try { await ref.read(dioProvider).post('/orders/${o.id}/cancel'); ref.invalidate(orderDetailProvider(o.id)); ref.invalidate(myOrdersProvider); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)))); }
                      },
                      child: Container(height: 52, decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neonRed.withOpacity(0.22))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cancel_outlined, color: AppColors.neonRed, size: 18), SizedBox(width: 8), Text('Cancel order', style: TextStyle(color: AppColors.neonRed, fontWeight: FontWeight.w800))])),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _metric(String k, String v, Color c, {bool isCode = false}) => Column(children: [
        Text(k, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(color: c, fontSize: isCode ? 26 : 22, fontWeight: FontWeight.w900, letterSpacing: isCode ? 5 : -0.5)),
      ]);
}

class ReceiptScreen extends ConsumerWidget {
  final String orderId;
  const ReceiptScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()), const Text('Digital Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))])),
            Expanded(
              child: order.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
                data: (o) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)), child: const Text('IUB PAY  •  PROTOTYPE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)))),
                      const SizedBox(height: 10),
                      Center(child: Text(o.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                      Center(child: Text(o.createdAt?.toString().substring(0, 16) ?? '', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))),
                      const SizedBox(height: 14),
                      Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.10), Colors.transparent]))),
                      const SizedBox(height: 14),
                      ...o.items.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(it.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), Text('  ${it.quantity} × ${it.unitPrice}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])), Text(taka(it.subtotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]))),
                      const SizedBox(height: 10),
                      Container(height: 1, color: Colors.white.withOpacity(0.06)),
                      const SizedBox(height: 10),
                      _row('Subtotal', o.subtotal), const SizedBox(height: 4), _row('Service fee', o.serviceFee),
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 8),
                      _row('TOTAL', o.totalAmount, bold: true, accent: true),
                      const SizedBox(height: 16),
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Payment: ${o.latestPayment?.status ?? "NOT_PAID"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        if (o.latestPayment != null) Text('Txn: ${o.latestPayment!.id}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        const SizedBox(height: 6),
                        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.neonCyan.withOpacity(0.18), AppColors.neonPurple.withOpacity(0.14)]), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.neonCyan.withOpacity(0.2))), child: Text('PICKUP CODE  •  ${o.pickupCode}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 13)))),
                      ])),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String l, int a, {bool bold = false, bool accent = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: TextStyle(color: bold ? Colors.white : AppColors.textSecondary, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 14 : 13)), accent ? ShaderMask(shaderCallback: (b) => AppColors.primaryGradient.createShader(b), child: Text(taka(a), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))) : Text(taka(a), style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.w800 : FontWeight.w600))]);
}
