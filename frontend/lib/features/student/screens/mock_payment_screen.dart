import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => context.go('/student')), const Text('Secure Pay  •  MOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: Row(children: [Container(width: 6,height: 6,decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen)), const SizedBox(width: 6), const Text('ENCRYPTED', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w800))]))])),
            const MockPaymentBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Text('AMOUNT TO PAY', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                      const SizedBox(height: 8),
                      if (_amount != null) ShaderMask(shaderCallback: (b) => AppColors.primaryGradient.createShader(b), child: Text('৳$_amount', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1))),
                      if (_amount == null && _busy) const Padding(padding: EdgeInsets.all(12), child: LoadingView(message: 'Contacting MOCK provider…')),
                      const SizedBox(height: 6),
                      Text('Order #${widget.orderId.substring(0, 8)}…', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      const SizedBox(height: 14),
                      Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.08), Colors.transparent]))),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.shield_rounded, size: 14, color: Colors.white.withOpacity(0.35)), const SizedBox(width: 6),
                        Text('Webhook-verified  •  Idempotent', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (_busy && _amount != null) const LoadingView(message: 'Processing…')
                  else ...[
                    _payBtn('SIMULATE SUCCESS', 'Webhook → PAID', Icons.check_circle_rounded, AppColors.neonGreen, () => _complete(success: true)),
                    const SizedBox(height: 10),
                    _payBtn('SIMULATE FAILURE', 'Provider declined', Icons.cancel_rounded, AppColors.neonRed, () => _complete(success: false), outline: true),
                    const SizedBox(height: 10),
                    GlassCard(
                      onTap: _busy ? null : () async { setState(() => _busy = true); await Future.delayed(const Duration(seconds: 3)); if (mounted) await _complete(success: true); },
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonAmber.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.neonAmber)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Delayed success (~3s)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)), Text('Simulates network latency', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                      ]),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonRed.withOpacity(0.2))), child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.neonRed, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.neonRed, fontSize: 13)))])),
                  ],
                  const SizedBox(height: 18),
                  Center(child: Text('Never trust client success alone — result is webhook-verified', style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 10.5))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _payBtn(String title, String sub, IconData ic, Color c, VoidCallback onTap, {bool outline = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: outline ? null : LinearGradient(colors: [c, c.withOpacity(0.75)]),
            color: outline ? Colors.white.withOpacity(0.04) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outline ? c.withOpacity(0.35) : Colors.transparent),
            boxShadow: outline ? [] : [BoxShadow(color: c.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: outline ? c.withOpacity(0.14) : Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)), child: Icon(ic, color: outline ? c : Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: outline ? c : Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.4)), Text(sub, style: TextStyle(color: outline ? AppColors.textTertiary : Colors.white.withOpacity(0.78), fontSize: 11))])),
            Icon(Icons.arrow_forward_rounded, color: outline ? c : Colors.white, size: 18),
          ]),
        ),
      );
}
