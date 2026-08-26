import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/student')), const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))]),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient), child: const Icon(Icons.person_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: Text((user?.role ?? '').toUpperCase(), style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonPurple.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.badge_rounded, size: 18, color: AppColors.neonPurple)), const SizedBox(width: 12), const Text('Student ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), const Spacer(), Text(user?.studentId ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])),
            GlassCard(child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonPink.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.neonPink)), const SizedBox(width: 12), const Text('Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), const Spacer(), Text((user?.role ?? '').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))])),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonAmber.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.science_rounded, size: 18, color: AppColors.neonAmber)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Prototype Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), Text('MOCK payments — no real IUB connection', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
              ]),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); },
              child: Container(height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.neonRed, Color(0xFFEF5350)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.neonRed.withOpacity(0.25), blurRadius: 14)]), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1))])),
            ),
          ]),
        ),
      ),
    );
  }
}
