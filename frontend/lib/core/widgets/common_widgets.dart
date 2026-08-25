import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';
import '../constants/app_constants.dart';
import 'money_formatter.dart';

/// Big status badge used on order tracking / result screens.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static const _map = {
    'PENDING_PAYMENT': (Colors.orange, 'Awaiting payment'),
    'PAYMENT_PROCESSING': (Colors.orange, 'Processing payment'),
    'PAYMENT_FAILED': (Colors.red, 'Payment failed'),
    'PAID': (Colors.blue, 'Paid — waiting for vendor'),
    'ACCEPTED': (Colors.teal, 'Accepted by vendor'),
    'PREPARING': (Colors.indigo, 'Preparing your food'),
    'READY': (Colors.green, 'Ready for pickup!'),
    'COLLECTED': (Colors.green, 'Collected'),
    'CANCELLED': (Colors.grey, 'Cancelled'),
    'REJECTED': (Colors.red, 'Rejected by vendor'),
    'REFUND_PENDING': (Colors.deepOrange, 'Refund pending'),
    'REFUNDED': (Colors.purple, 'Refunded'),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _map[status] ?? (Colors.grey, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color)),
      child: Text(label,
          style: TextStyle(
              color: color.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

/// Price text with the Bangla Taka symbol.
class PriceText extends StatelessWidget {
  final int amount;
  final double fontSize;
  final bool bold;
  const PriceText(this.amount,
      {super.key, this.fontSize = 16, this.bold = true});

  @override
  Widget build(BuildContext context) => Text(taka(amount),
      style: TextStyle(fontSize: fontSize, fontWeight:
          bold ? FontWeight.bold : FontWeight.normal));
}

const demoBanner = SnackBar(content: Text(kDemoNotice));

/// Standard loading / empty / error views.
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(),
    if (message != null) ...[
      const SizedBox(height: 12),
      Text(message!, textAlign: TextAlign.center),
    ]
  ]));
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, this.icon = Icons.inbox_outlined,
      required this.message});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ])));
}

class ErrorView extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(apiErrorMessage(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );
}

/// Prominent DEMO/MOCK banner shown on all payment-related screens.
class MockPaymentBanner extends StatelessWidget {
  const MockPaymentBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.amber.shade200,
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text('DEMO MODE — $kDemoNotice',
                  style: const TextStyle(fontSize: 12.5))),
        ]),
      );
}
