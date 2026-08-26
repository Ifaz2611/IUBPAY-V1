import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'student@iub.test');
  final _password = TextEditingController(text: 'Passw0rd!Dev');
  String? _error;
  bool _busy = false;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    final err = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 18),
              // branding
              Center(
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.35), blurRadius: 24)],
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text('IUB PAY', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Future of Campus Payments', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Container(height: 1, width: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.neonCyan.withOpacity(0.6), Colors.transparent]))),
                ]),
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Welcome back', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Sign in to your campus wallet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded), hintText: 'you@iub.test'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password, obscureText: true, style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonRed.withOpacity(0.25))),
                      child: Row(children: [const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.neonRed), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.neonRed, fontSize: 13)))]),
                    ),
                  NeonButton(label: 'SIGN IN', icon: Icons.arrow_forward_rounded, busy: _busy, onPressed: _busy ? null : _login),
                  const SizedBox(height: 14),
                  Center(child: Text('Biometric • Face ID ready', style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 11, letterSpacing: 0.8))),
                ]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen, boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 6)])),
                    const SizedBox(width: 8),
                    const Text('DEMO ACCOUNTS — TAP TO COPY', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 10),
                  _demoChip('student@iub.test', 'Student', AppColors.neonCyan),
                  const SizedBox(height: 6),
                  _demoChip('vendor@iub.test', 'Vendor', AppColors.neonPurple),
                  const SizedBox(height: 6),
                  _demoChip('admin@iub.test', 'Admin', AppColors.neonPink),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Password:  Passw0rd!Dev', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Center(child: Text('MOCK PAYMENTS • NOT CONNECTED TO bKash / NAGAD', style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 10, letterSpacing: 0.8))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String email, String role, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.18))),
        child: Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: 8),
          Expanded(child: Text(email, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(6)), child: Text(role, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800))),
        ]),
      );
}
