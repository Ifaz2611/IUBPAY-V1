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
    final first = user?.name.split(' ').first ?? 'Explorer';
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient, boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 14)]),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('HI, ${first.toUpperCase()}  •', style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      Text('Mission Control', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ])),
                    _iconBtn(Icons.notifications_none_rounded, () {}),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.logout_rounded, () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
                  ]),
                  const SizedBox(height: 16),
                  // hero wallet card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF7C3AED), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('IUB PAY  •  MOCK WALLET', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.science_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('DEMO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))])),
                      ]),
                      const SizedBox(height: 14),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(user?.studentId ?? '—', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _walletStat('BALANCE', '∞ UNLIMITED', Icons.all_inclusive_rounded)),
                        Container(width: 1, height: 36, color: Colors.white24),
                        Expanded(child: _walletStat('STATUS', 'ONLINE', Icons.circle, dot: true)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Launch Pad', subtitle: 'Order • Track • Collect'),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
                children: [
                  _Tile(Icons.storefront_rounded, 'Cafeterias', 'Browse vendors', () => context.go('/student/vendors'), [AppColors.neonCyan, const Color(0xFF06B6D4)]),
                  _Tile(Icons.receipt_long_rounded, 'My Orders', 'Live tracking', () => context.go('/student/orders'), [AppColors.neonPurple, const Color(0xFF8B5CF6)]),
                  _Tile(Icons.shopping_cart_rounded, 'Cart', 'Checkout', () => context.go('/student/cart'), [AppColors.neonPink, const Color(0xFFF43F5E)]),
                  _Tile(Icons.person_rounded, 'Profile', 'Settings', () => context.go('/student/profile'), [const Color(0xFF10B981), const Color(0xFF06B6D4)]),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.neonAmber.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.neonAmber)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('All payments are simulated. No real money moves.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
      drawer: _FuturisticDrawer(userName: user?.name, email: user?.email),
    );
  }

  static Widget _iconBtn(IconData ic, VoidCallback onTap) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: IconButton(icon: Icon(ic, size: 18, color: AppColors.textSecondary), onPressed: onTap, padding: EdgeInsets.zero),
      );

  static Widget _walletStat(String k, String v, IconData ic, {bool dot = false}) => Row(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9)), child: dot ? Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen, boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 8)])) : Icon(ic, size: 14, color: Colors.white)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ]);
}

class _Tile extends StatelessWidget {
  final IconData icon; final String label; final String hint; final VoidCallback onTap; final List<Color> grad;
  const _Tile(this.icon, this.label, this.hint, this.onTap, this.grad);
  @override
  Widget build(BuildContext context) => GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: grad.first.withOpacity(0.35), blurRadius: 14)]), child: Icon(icon, color: Colors.white, size: 24)),
          const Spacer(),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          const SizedBox(height: 8),
          Row(children: [Text('OPEN', style: TextStyle(color: grad.first, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 12, color: grad.first)]),
        ]),
      );
}

class _FuturisticDrawer extends ConsumerWidget {
  final String? userName; final String? email;
  const _FuturisticDrawer({this.userName, this.email});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
        backgroundColor: AppColors.bgMid,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: ListView(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.neonCyan.withOpacity(0.12), Colors.transparent])),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient), child: const Icon(Icons.person_rounded, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userName ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
              ]),
            ),
            _dTile(Icons.storefront_rounded, 'Browse food', () => context.go('/student/vendors')),
            _dTile(Icons.receipt_long_rounded, 'My orders', () => context.go('/student/orders')),
            _dTile(Icons.shopping_cart_rounded, 'Cart', () => context.go('/student/cart')),
            _dTile(Icons.person_rounded, 'Profile', () => context.go('/student/profile')),
            const Divider(color: AppColors.divider),
            _dTile(Icons.logout_rounded, 'Logout', () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }, color: AppColors.neonRed),
            const Padding(padding: EdgeInsets.all(16), child: Text('DEMO • MOCK PAYMENTS — not connected to any real provider', style: TextStyle(fontSize: 10, color: AppColors.textTertiary))),
          ]),
        ),
      );
  Widget _dTile(IconData ic, String t, VoidCallback onTap, {Color color = AppColors.textPrimary}) => ListTile(leading: Icon(ic, color: color, size: 20), title: Text(t, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)), onTap: onTap);
}
