import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _email.text = 'student@iub.test';
      _password.text = 'Passw0rd!Dev';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final err = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 8, right: 8, child: const ThemeToggleButton()),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(height: 8),
                    Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Image.asset('assets/images/logo.png', width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 14),
                      Text('IUB PAY',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('Campus payments, simply.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                    SizedBox(height: 28),
                    AppCard(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('Welcome back',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                          SizedBox(height: 4),
                          Text('Sign in with your university email',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter your email';
                              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@iub.edu.bd',
                              prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _login(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your password';
                              if (v.length < 6) return 'Password is too short';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                onPressed: () => setState(() => _obscure = !_obscure),
                                tooltip: _obscure ? 'Show password' : 'Hide password',
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          if (_error != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  border: Border.all(color: AppColors.errorBorder)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13, height: 1.35))),
                              ]),
                            ),
                          PrimaryButton(label: 'Sign in', busy: _busy, onPressed: _busy ? null : _login),
                          SizedBox(height: 10),
                          Center(
                            child: Text('Secure • Encrypted',
                                style: TextStyle(color: AppColors.textTertiary.withOpacity(0.9), fontSize: 11, letterSpacing: 0.2)),
                          ),
                        ]),
                      ),
                    ),
                    SizedBox(height: 12),
                    if (kDebugMode) _DebugAccounts(onFill: (email) {
                      _email.text = email;
                      _password.text = 'Passw0rd!Dev';
                      HapticFeedback.selectionClick();
                    }),
                    SizedBox(height: 10),
                    Center(
                      child: Text('Demo • Mock payments — not connected to bKash / Nagad',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugAccounts extends StatelessWidget {
  final ValueChanged<String> onFill;
  _DebugAccounts({required this.onFill});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bug_report_outlined, size: 12, color: AppColors.textTertiary),
          SizedBox(width: 6),
          Text('DEBUG — TAP TO FILL', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        ]),
        SizedBox(height: 10),
        _chip('student@iub.test', 'Student', onFill),
        SizedBox(height: 6),
        _chip('vendor@iub.test', 'Vendor', onFill),
        SizedBox(height: 6),
        _chip('admin@iub.test', 'Admin', onFill),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.sm)),
          child: Text('Password: Passw0rd!Dev',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
        ),
      ]),
    );
  }

  Widget _chip(String email, String role, ValueChanged<String> onFill) => InkWell(
        onTap: () => onFill(email),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textTertiary),
            SizedBox(width: 8),
            Expanded(child: Text(email, style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500))),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(6)),
                child: Text(role, style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        ),
      );
}
