import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) context.go('/'); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(_scale),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // logo orb
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.45), blurRadius: 32), BoxShadow(color: AppColors.neonPurple.withOpacity(0.35), blurRadius: 40)],
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 22),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [Colors.white, AppColors.neonCyan]).createShader(b),
                  child: Text(kAppName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
                  child: const Text('CASHLESS CAMPUS  •  PROTOTYPE', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                ),
                const SizedBox(height: 36),
                const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppColors.neonCyan))),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(kDemoNotice, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10.5, letterSpacing: 0.2)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
