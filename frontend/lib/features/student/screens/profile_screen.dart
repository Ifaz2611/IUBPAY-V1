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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Profile', onBack: () => context.go('/student')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 2),
              Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(6)), child: Text((user?.role ?? '').toUpperCase(), style: const TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
        AppCard(child: _row(Icons.badge_outlined, 'Student ID', user?.studentId ?? '—')),
        AppCard(margin: const EdgeInsets.only(top: 8), child: _row(Icons.shield_outlined, 'Role', (user?.role ?? '').toUpperCase())),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Demo mode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)), Text('Mock payments — not connected to any real system', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Sign out', icon: Icons.logout_rounded, outlined: true, onPressed: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
      ]),
    );
  }

  Widget _row(IconData ic, String label, String value) => Row(children: [
        Icon(ic, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]);
}
