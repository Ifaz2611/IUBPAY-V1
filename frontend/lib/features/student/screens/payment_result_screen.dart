import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

class PaymentResultScreen extends ConsumerWidget {
  final String orderId;
  const PaymentResultScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Payment result', onBack: () => context.go('/student')),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) {
          final paid = o.status == 'PAID' || o.latestPayment?.status == 'SUCCEEDED';
          final failed = o.status == 'PAYMENT_FAILED' || o.latestPayment?.status == 'FAILED';
          final Color accent = failed ? AppColors.error : paid ? AppColors.success : AppColors.warning;
          final Color bg = failed ? AppColors.errorBg : paid ? AppColors.successBg : AppColors.warningBg;
          final IconData ic = failed ? Icons.close_rounded : paid ? Icons.check_rounded : Icons.hourglass_top_rounded;
          final title = failed ? 'Payment failed' : paid ? 'Payment verified' : 'Processing';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 8),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: accent.withOpacity(0.2))),
                child: Icon(ic, size: 34, color: accent),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Text(o.status == 'PAYMENT_PROCESSING' ? 'Waiting for webhook confirmation…' : paid ? 'Webhook verified — funds captured.' : o.latestPayment?.failureReason ?? 'Provider declined the charge.',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              AppCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Order', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(o.orderNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), PriceText(o.totalAmount, fontSize: 15)]),
                  if (o.latestPayment?.failureReason != null) ...[
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadii.md)), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error), const SizedBox(width: 6), Expanded(child: Text('Reason: ${o.latestPayment!.failureReason}', style: const TextStyle(color: AppColors.error, fontSize: 12)))])),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              if (paid)
                PrimaryButton(label: 'Track my order', icon: Icons.local_shipping_outlined, onPressed: () => context.go('/student/orders/$orderId'))
              else
                PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: () => context.go('/student/pay/$orderId')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => context.go('/student'), child: const Text('Back to home')),
            ]),
          );
        },
      ),
    );
  }
}
