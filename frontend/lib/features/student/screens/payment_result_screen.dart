import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentResultScreen({super.key, required this.orderId});
  @override
  ConsumerState<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  Timer? _pollTimer;

  bool _isProcessing(String status) =>
      status == 'PAYMENT_PROCESSING' || status == 'PENDING_PAYMENT';

  void _startPollingIfNeeded(String status) {
    final needsPolling = _isProcessing(status);
    if (needsPolling && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) ref.invalidate(orderDetailProvider(widget.orderId));
      });
    } else if (!needsPolling) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));

    // Drive polling from current data when available
    order.whenData((o) => _startPollingIfNeeded(o.status));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Payment result', onBack: () => context.go('/student')),
      body: order.when(
        loading: () => LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
        data: (o) {
          final paid = o.status == 'PAID' || o.latestPayment?.status == 'SUCCEEDED';
          final failed = o.status == 'PAYMENT_FAILED' || o.latestPayment?.status == 'FAILED';
          final processing = _isProcessing(o.status) && !paid && !failed;
          final Color accent = failed ? AppColors.error : paid ? AppColors.success : AppColors.warning;
          final Color bg = failed ? AppColors.errorBg : paid ? AppColors.successBg : AppColors.warningBg;
          final IconData ic = failed ? Icons.close_rounded : paid ? Icons.check_rounded : Icons.hourglass_top_rounded;
          final title = failed ? 'Payment failed' : paid ? 'Payment verified' : 'Processing';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: accent.withValues(alpha: 0.2))),
                child: Icon(ic, size: 34, color: accent),
              ),
              SizedBox(height: 16),
              Text(title, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
              SizedBox(height: 6),
              Text(
                processing
                    ? 'Waiting for webhook confirmation…'
                    : paid
                        ? 'Webhook verified — funds captured.'
                        : o.latestPayment?.failureReason ?? 'Provider declined the charge.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (processing) ...[
                SizedBox(height: 12),
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(height: 8),
                Text('Auto-refreshing…', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
              SizedBox(height: 16),
              AppCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Order', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    Text(o.orderNumber, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                  SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), PriceText(o.totalAmount, fontSize: 15)]),
                  if (o.latestPayment?.failureReason != null) ...[
                    SizedBox(height: 10),
                    Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadii.md)),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
                          SizedBox(width: 6),
                          Expanded(child: Text('Reason: ${o.latestPayment!.failureReason}', style: TextStyle(color: AppColors.error, fontSize: 12))),
                        ])),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              if (processing) ...[
                PrimaryButton(label: 'Refresh now', icon: Icons.refresh_rounded, outlined: true, onPressed: () => ref.invalidate(orderDetailProvider(widget.orderId))),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: () => context.go('/student'), child: const Text('Back to home')),
              ] else if (paid)
                PrimaryButton(label: 'Track my order', icon: Icons.local_shipping_outlined, onPressed: () => context.go('/student/orders/${widget.orderId}'))
              else ...[
                PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: () => context.go('/student/pay/${widget.orderId}')),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: () => context.go('/student'), child: const Text('Back to home')),
              ],
            ]),
          );
        },
      ),
    );
  }
}