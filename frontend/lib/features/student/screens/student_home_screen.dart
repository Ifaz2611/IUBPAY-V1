import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final first = user?.name.split(' ').first ?? 'there';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi, $first', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Text('What would you like to eat today?', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w400)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Account summary — calm, not neon
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Account',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.successBorder)),
                    child: const Row(children: [
                      Icon(Icons.circle, size: 6, color: AppColors.success),
                      SizedBox(width: 6),
                      Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(user?.email ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                if (user?.studentId != null) ...[
                  const SizedBox(height: 2),
                  Text('ID ${user!.studentId}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
                const SizedBox(height: 14),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Balance', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      const Text('Unlimited', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Mock wallet', style: TextStyle(color: AppColors.textTertiary.withOpacity(0.9), fontSize: 11)),
                    ]),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Status', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                        const SizedBox(width: 6),
                        const Text('Ready to order', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                      Text('All systems normal', style: TextStyle(color: AppColors.textTertiary.withOpacity(0.9), fontSize: 11)),
                    ]),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 520;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.15 : 1.05,
                children: [
                  _ActionTile(
                    icon: Icons.storefront_rounded,
                    label: 'Browse vendors',
                    hint: 'See what’s open',
                    primary: true,
                    onTap: () => context.go('/student/vendors'),
                  ),
                  _ActionTile(icon: Icons.receipt_long_rounded, label: 'My orders', hint: 'Track & receipts', onTap: () => context.go('/student/orders')),
                  _ActionTile(icon: Icons.shopping_bag_outlined, label: 'Cart', hint: 'Review items', onTap: () => context.go('/student/cart')),
                  _ActionTile(icon: Icons.person_outline_rounded, label: 'Profile', hint: 'Account details', onTap: () => context.go('/student/profile')),
                ],
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                SizedBox(width: 10),
                Expanded(child: Text('All payments are simulated. No real money moves.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3))),
              ]),
            ),
          ],
        ),
      ),
      drawer: _StudentDrawer(userName: user?.name, email: user?.email),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool primary;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.hint, this.primary = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary ? AppColors.brand : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary ? AppColors.brand : AppColors.border),
          ),
          child: Icon(icon, color: primary ? Colors.white : AppColors.textSecondary, size: 20),
        ),
        const Spacer(),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
        const SizedBox(height: 2),
        Text(hint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        const SizedBox(height: 8),
        Row(children: [
          Text(primary ? 'Browse' : 'Open',
              style: TextStyle(color: primary ? AppColors.brand : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 12, color: primary ? AppColors.brand : AppColors.textTertiary),
        ]),
      ]),
    );
  }
}

class _StudentDrawer extends ConsumerWidget {
  final String? userName;
  final String? email;
  const _StudentDrawer({this.userName, this.email});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(color: AppColors.surfaceMuted, border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                Text(email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
          _dTile(Icons.storefront_rounded, 'Browse food', () => context.go('/student/vendors')),
          _dTile(Icons.receipt_long_rounded, 'My orders', () => context.go('/student/orders')),
          _dTile(Icons.shopping_bag_outlined, 'Cart', () => context.go('/student/cart')),
          _dTile(Icons.person_outline_rounded, 'Profile', () => context.go('/student/profile')),
          const Divider(color: AppColors.border, height: 1),
          _dTile(Icons.logout_rounded, 'Sign out', () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          }, color: AppColors.error),
          const Padding(padding: EdgeInsets.all(16), child: Text('Demo • Mock payments', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
        ]),
      );
  Widget _dTile(IconData ic, String t, VoidCallback onTap, {Color color = AppColors.textPrimary}) =>
      ListTile(leading: Icon(ic, color: color, size: 20), title: Text(t, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)), onTap: onTap);
}
