import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';

/// DEMO payment screen. Simulates the mock provider's checkout page.
class MockPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const MockPaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends ConsumerState<MockPaymentScreen> {
  String? _paymentId;
  int? _amount;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  Future<void> _createPayment() async {
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ref.read(dioProvider)
          .post('/payments/create', data: {'order_id': widget.orderId});
      setState(() {
        _paymentId = r.data['payment_id'];
        _amount = r.data['amount_taka'];
        _busy = false;
      });
    } catch (e) {
      setState(() { _error = apiErrorMessage(e); _busy = false; });
    }
  }

  Future<void> _complete({required bool success}) async {
    if (_paymentId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(dioProvider).post(
          success ? '/payments/mock/complete' : '/payments/mock/fail',
          data: {'payment_id': _paymentId, 'delay_seconds': 0});
      if (!mounted) return;
      context.go('/student/payment-result/${widget.orderId}');
    } catch (e) {
      setState(() { _error = apiErrorMessage(e); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Payment')),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Order #${widget.orderId.substring(0, 8)}…',
                    textAlign: TextAlign.center),
                if (_amount != null) ...[
                  const SizedBox(height: 8),
                  PriceText(_amount!, fontSize: 34),
                ],
                const SizedBox(height: 32),
                if (_busy)
                  const LoadingView(message: 'Contacting MOCK provider…')
                else ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700),
                    icon: const Icon(Icons.check_circle, size: 28),
                    label: const Text('Simulate SUCCESSFUL payment'),
                    onPressed: () => _complete(success: true),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600),
                    icon: const Icon(Icons.cancel, size: 28),
                    label: const Text('Simulate FAILED payment'),
                    onPressed: () => _complete(success: false),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.hourglass_top),
                    label: const Text('Delayed success (~3s)'),
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await Future.delayed(const Duration(seconds: 3));
                            if (mounted) await _complete(success: true);
                          },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
