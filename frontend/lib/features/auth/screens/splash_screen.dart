import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(Duration(milliseconds: 1100), () { if (mounted) context.go('/'); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover),
            ),
            SizedBox(height: 18),
            Text(kAppName.toUpperCase(), style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.border)),
              child: Text('Cashless campus • Prototype', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            SizedBox(height: 28),
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: Text(kDemoNotice, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 10.5)),
            ),
          ]),
        ),
      ),
    );
  }
}