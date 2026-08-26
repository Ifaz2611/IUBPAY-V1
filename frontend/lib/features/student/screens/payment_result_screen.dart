import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

class PaymentResultScreen extends ConsumerWidget {
  final String orderId;
  const PaymentResultScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: order.when(
            loading: () => const LoadingView(),
            error: (e, _) => Column(children: [Padding(padding: const EdgeInsets.all(8), child: Row(children: [IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => context.go('/student')), const Text('Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))])), Expanded(child: ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))))]),
            data: (o) {
              final paid = o.status == 'PAID' || o.latestPayment?.status == 'SUCCEEDED';
              final failed = o.status == 'PAYMENT_FAILED' || o.latestPayment?.status == 'FAILED';
              final Color accent = failed ? AppColors.neonRed : paid ? AppColors.neonGreen : AppColors.neonAmber;
              final IconData ic = failed ? Icons.cancel_rounded : paid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;
              return Column(children: [
                Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => context.go('/student')), const Text('Payment Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))])),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.12), border: Border.all(color: accent.withOpacity(0.25), width: 1.5), boxShadow: [BoxShadow(color: accent.withOpacity(0.28), blurRadius: 24)]),
                        child: Icon(ic, size: 56, color: accent),
                      ),
                      const SizedBox(height: 18),
                      Text(failed ? 'PAYMENT FAILED' : paid ? 'PAYMENT VERIFIED ✓' : 'PROCESSING…', style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(o.status == 'PAYMENT_PROCESSING' ? 'Waiting for webhook confirmation…' : paid ? 'Webhook verified — funds captured' : 'Provider declined the charge', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Order', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text(o.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), Text('৳${o.totalAmount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))]),
                          if (o.latestPayment?.failureReason != null) ...[
                            const SizedBox(height: 8),
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.neonRed), const SizedBox(width: 6), Expanded(child: Text('Reason: ${o.latestPayment!.failureReason}', style: const TextStyle(color: AppColors.neonRed, fontSize: 12)))])),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 22),
                      if (paid) NeonButton(label: 'TRACK MY ORDER  →', icon: Icons.local_shipping_rounded, onPressed: () => context.go('/student/orders/$orderId'), gradient: const [AppColors.neonGreen, Color(0xFF00BFA5)])
                      else NeonButton(label: 'TRY AGAIN', icon: Icons.refresh_rounded, onPressed: () => context.go('/student/pay/$orderId'), gradient: const [AppColors.neonRed, Color(0xFFFF6E40)]),
                      const SizedBox(height: 10),
                      TextButton(onPressed: () => context.go('/student'), child: const Text('Back to home', style: TextStyle(color: AppColors.textTertiary))),
                    ]),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}
