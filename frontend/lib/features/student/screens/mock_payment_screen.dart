import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';

class MockPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const MockPaymentScreen({super.key, required this.orderId});
  @override
  ConsumerState<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends ConsumerState<MockPaymentScreen> {
  String? _paymentId; int? _amount; bool _busy = false; String? _error;

  @override
  void initState() { super.initState(); _createPayment(); }

  Future<void> _createPayment() async {
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ref.read(dioProvider).post('/payments/create', data: {'order_id': widget.orderId});
      setState(() { _paymentId = r.data['payment_id']; _amount = r.data['amount_taka']; _busy = false; });
    } catch (e) { setState(() { _error = apiErrorMessage(e); _busy = false; }); }
  }

  Future<void> _complete({required bool success}) async {
    if (_paymentId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(dioProvider).post(success ? '/payments/mock/complete' : '/payments/mock/fail', data: {'payment_id': _paymentId, 'delay_seconds': 0});
      if (!mounted) return;
      context.go('/student/payment-result/${widget.orderId}');
    } catch (e) { setState(() { _error = apiErrorMessage(e); _busy = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Payment', subtitle: 'Mock — verify locally, trust the webhook', onBack: () => context.go('/student')),
      body: Column(children: [
        const MockPaymentBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('Amount to pay', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  if (_amount != null) PriceText(_amount!, fontSize: 36) else if (_busy) const LoadingView(message: 'Contacting mock provider…'),
                  const SizedBox(height: 6),
                  Text('Order ${widget.orderId.substring(0, 8)}…', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_outlined, size: 14, color: AppColors.textTertiary), SizedBox(width: 6), Text('Webhook-verified  •  Idempotent', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))]),
                ]),
              ),
              const SizedBox(height: 18),
              if (_busy && _amount != null) const LoadingView(message: 'Processing…')
              else ...[
                PrimaryButton(label: 'Simulate success', icon: Icons.check_rounded, onPressed: () => _complete(success: true)),
                const SizedBox(height: 10),
                PrimaryButton(label: 'Simulate failure', icon: Icons.close_rounded, outlined: true, onPressed: () => _complete(success: false)),
                const SizedBox(height: 10),
                AppCard(
                  onTap: _busy ? null : () async { setState(() => _busy = true); await Future.delayed(const Duration(seconds: 3)); if (mounted) await _complete(success: true); },
                  padding: const EdgeInsets.all(14),
                  child: const Row(children: [
                    Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Delayed success (~3s)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text('Simulates network latency', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                  ]),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.errorBorder)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)))])),
              ],
              const SizedBox(height: 18),
              const Center(child: Text('Result is webhook-verified — don’t trust client success alone.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
            ]),
          ),
        ),
      ]),
    );
  }
}
