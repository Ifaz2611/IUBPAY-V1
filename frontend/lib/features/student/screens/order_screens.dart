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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'My orders',
        subtitle: 'History and live tracking',
        onBack: () => context.go('/student'),
        action: IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), tooltip: 'Refresh', onPressed: () => ref.invalidate(myOrdersProvider)),
      ),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(icon: Icons.receipt_long_rounded, message: 'No orders yet. Browse vendors to place your first order.');
          }
          return RefreshIndicator(
            color: AppColors.brand,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = list[i];
                return AppCard(
                  onTap: () => context.go('/student/orders/${o.id}'),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                        child: const Icon(Icons.receipt_outlined, size: 18, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.orderNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('${o.items.length} items  •  ${taka(o.totalAmount)}  •  ${o.createdAt != null ? formatDate(o.createdAt!) : ''}',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ])),
                    StatusChip(status: o.status),
                  ]),
                );
              },
            ),
          );
        },
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
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) { if (mounted) ref.invalidate(orderDetailProvider(widget.orderId)); });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final active = order.valueOrNull;
    final stepIndex = active == null ? -1 : _steps.indexOf(active.status);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/student/orders')),
        title: Text(active?.orderNumber ?? 'Order'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.successBorder)),
            child: const Row(children: [Icon(Icons.circle, size: 6, color: AppColors.success), SizedBox(width: 6), Text('LIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5))]),
          )
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(
            child: Column(children: [
              Center(child: StatusChip(status: o.status)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _metric('Pickup code', o.pickupCode, AppColors.brand, isCode: true)),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(child: _metric('Total', taka(o.totalAmount), AppColors.textPrimary)),
              ]),
              if (o.createdAt != null) ...[
                const SizedBox(height: 10),
                Text(formatDateTime(o.createdAt!), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ]
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Journey', subtitle: 'Auto-refreshes every 5 seconds'),
              const SizedBox(height: 14),
              if (stepIndex >= 0)
                ...List.generate(_steps.length, (i) {
                  final done = i < stepIndex;
                  final cur = i == stepIndex;
                  final label = switch (_steps[i]) { 'PAID' => 'Payment verified', 'ACCEPTED' => 'Vendor accepted', 'PREPARING' => 'Being prepared', 'READY' => 'Ready for pickup', _ => 'Collected' };
                  final Color c = done ? AppColors.success : cur ? AppColors.brand : AppColors.textTertiary;
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done || cur ? c.withOpacity(0.12) : AppColors.surfaceMuted,
                              border: Border.all(color: done || cur ? c.withOpacity(0.35) : AppColors.border)),
                          child: Icon(done ? Icons.check_rounded : cur ? Icons.radio_button_checked_rounded : Icons.circle_outlined, size: 14, color: c)),
                      if (i != _steps.length - 1) Container(width: 1, height: 16, color: done ? AppColors.success.withOpacity(0.3) : AppColors.border),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(label, style: TextStyle(color: cur ? AppColors.textPrimary : done ? AppColors.textSecondary : AppColors.textTertiary, fontWeight: cur ? FontWeight.w600 : FontWeight.w400, fontSize: 13)))),
                    if (cur)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(6)), child: const Text('Now', style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w700))),
                  ]);
                })
              else
                Text('Order status: ${o.status}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Items', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...o.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(it.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Text('${it.quantity} × ${taka(it.unitPrice)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(taka(it.subtotal), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ]))),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)), PriceText(o.totalAmount)]),
            ]),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'View receipt', icon: Icons.receipt_outlined, outlined: true, onPressed: () => context.go('/student/receipt/${o.id}')),
          const SizedBox(height: 8),
          if (['PENDING_PAYMENT', 'PAID'].contains(o.status))
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Cancel order?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Cancel'))]));
                if (confirmed != true) return;
                try { await ref.read(dioProvider).post('/orders/${o.id}/cancel'); ref.invalidate(orderDetailProvider(o.id)); ref.invalidate(myOrdersProvider); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)))); }
              },
              icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
              label: const Text('Cancel order', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.errorBorder), foregroundColor: AppColors.error, minimumSize: const Size.fromHeight(44)),
            ),
        ]),
      ),
    );
  }

  Widget _metric(String k, String v, Color c, {bool isCode = false}) => Column(children: [
        Text(k.toUpperCase(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text(v, style: TextStyle(color: c, fontSize: isCode ? 22 : 18, fontWeight: FontWeight.w700, letterSpacing: isCode ? 3 : -0.2)),
      ]);
}

class ReceiptScreen extends ConsumerWidget {
  final String orderId;
  const ReceiptScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
          title: 'Receipt',
          subtitle: 'Digital copy',
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/orders');
            }
          }),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(6)), child: const Text('IUB PAY', style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)))),
              const SizedBox(height: 8),
              Center(child: Text(o.orderNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
              if (o.createdAt != null) Center(child: Text(formatDateTime(o.createdAt!), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              ...o.items.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(it.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)), Text('${it.quantity} × ${taka(it.unitPrice)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])), Text(taka(it.subtotal), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))]))),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _row('Subtotal', o.subtotal), const SizedBox(height: 4), _row('Service fee', o.serviceFee),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _row('Total', o.totalAmount, bold: true),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Payment: ${o.latestPayment?.status ?? "NOT PAID"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (o.latestPayment != null) Text('Txn: ${o.latestPayment!.id}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderStrong)), child: Text('Pickup  ${o.pickupCode}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 2.5, fontSize: 13)))),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _row(String l, int a, {bool bold = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 14 : 13)),
        Text(taka(a), style: TextStyle(color: AppColors.textPrimary, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, fontSize: bold ? 16 : 13))
      ]);
}
