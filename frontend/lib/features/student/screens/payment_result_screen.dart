import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

/// Shows the authoritative backend result after the webhook has been verified.
class PaymentResultScreen extends ConsumerWidget {
  final String orderId;
  const PaymentResultScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Result')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e,
            onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) {
          final paid = o.status == 'PAID' || o.latestPayment?.status == 'SUCCEEDED';
          final failed = o.status == 'PAYMENT_FAILED' ||
              o.latestPayment?.status == 'FAILED';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(paid ? Icons.check_circle : Icons.cancel,
                    size: 96,
                    color: failed
                        ? Colors.red
                        : paid ? Colors.green : Colors.orange),
                const SizedBox(height: 16),
                Text(
                  o.status == 'PAYMENT_PROCESSING'
                      ? 'Processing…'
                      : paid ? 'Payment successful!' : 'Payment failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text('Order ${o.orderNumber}'),
                const SizedBox(height: 4),
                Text('Total: ৳${o.totalAmount}',
                    style: const TextStyle(fontSize: 17)),
                if (o.latestPayment?.failureReason != null) ...[
                  const SizedBox(height: 6),
                  Text('Reason: ${o.latestPayment!.failureReason}',
                      style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 30),
                if (paid)
                  FilledButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Track my order'),
                      onPressed: () => context.go('/student/orders/$orderId'))
                else
                  FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                      onPressed: () => context.go('/student/pay/$orderId')),
              ]),
            ),
          );
        },
      ),
    );
  }
}
