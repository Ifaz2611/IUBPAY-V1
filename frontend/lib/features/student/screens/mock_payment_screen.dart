import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../providers/student_providers.dart';

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

  String get _shortOrderId {
    final id = widget.orderId;
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  Future<void> _createPayment() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(dioProvider)
          .post('/payments/create', data: {'order_id': widget.orderId});
      if (!mounted) return;
      final data = r.data as Map<String, dynamic>;
      setState(() {
        _paymentId = data['payment_id']?.toString();
        final amt = data['amount_taka'];
        _amount = amt is int ? amt : int.tryParse('$amt');
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _busy = false;
      });
    }
  }

  Future<void> _complete({required bool success}) async {
    if (_paymentId == null) {
      setState(() => _error = 'Payment not ready yet. Please wait or retry.');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(dioProvider).post(
        success ? '/payments/mock/complete' : '/payments/mock/fail',
        data: {'payment_id': _paymentId, 'delay_seconds': 0},
      );
      if (!mounted) return;
      // Ensure payment-result fetches fresh order state after webhook.
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      context.go('/student/payment-result/${widget.orderId}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAct = !_busy && _paymentId != null && _error == null;
    final creating = _busy && _paymentId == null && _amount == null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
          title: 'Payment',
          subtitle: 'Mock — verify locally, trust the webhook',
          onBack: () => context.go('/student')),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Text('Amount to pay',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 8),
                      if (_amount != null)
                        PriceText(_amount!, fontSize: 36)
                      else if (creating || _busy)
                        const LoadingView(message: 'Contacting mock provider…')
                      else if (_error != null)
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 28),
                      const SizedBox(height: 6),
                      Text('Order $_shortOrderId…',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined,
                                size: 14, color: AppColors.textTertiary),
                            SizedBox(width: 6),
                            Text('Webhook-verified  •  Idempotent',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11))
                          ]),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (_busy && _amount != null)
                    const LoadingView(message: 'Processing…')
                  else ...[
                    PrimaryButton(
                      label: 'Simulate success',
                      icon: Icons.check_rounded,
                      busy: _busy,
                      onPressed: canAct ? () => _complete(success: true) : null,
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Simulate failure',
                      icon: Icons.close_rounded,
                      outlined: true,
                      busy: _busy,
                      onPressed:
                          canAct ? () => _complete(success: false) : null,
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      onTap: canAct
                          ? () async {
                              setState(() => _busy = true);
                              await Future.delayed(const Duration(seconds: 3));
                              if (mounted) await _complete(success: true);
                            }
                          : null,
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(Icons.hourglass_top_rounded,
                            size: 18,
                            color: canAct
                                ? AppColors.textSecondary
                                : AppColors.textTertiary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Delayed success (~3s)',
                                  style: TextStyle(
                                      color: canAct
                                          ? AppColors.textPrimary
                                          : AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const Text('Simulates network latency',
                                  style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11)),
                            ])),
                        Icon(Icons.chevron_right_rounded,
                            color: canAct
                                ? AppColors.textTertiary
                                : AppColors.borderStrong,
                            size: 18),
                      ]),
                    ),
                    if (_paymentId == null && !_busy && _error != null) ...[
                      const SizedBox(height: 10),
                      PrimaryButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          outlined: true,
                          onPressed: _createPayment),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: AppColors.errorBorder)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13))),
                            ])),
                  ],
                  const SizedBox(height: 18),
                  const Center(
                      child: Text(
                          'Result is webhook-verified — don’t trust client success alone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 11))),
                ]),
          ),
        ),
      ]),
    );
  }
}
