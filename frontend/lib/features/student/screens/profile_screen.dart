import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final ordersAsync = ref.watch(myOrdersProvider);
    final cart = ref.watch(cartProvider);
    final orders = ordersAsync.valueOrNull ?? [];
    final totalSpent = orders.where((o) => o.status == 'COLLECTED' || o.status == 'PAID' || o.status == 'READY').fold(0, (s, o) => s + o.totalAmount);
    final activeCount = orders.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Profile', subtitle: 'Your campus wallet', onBack: () => context.go('/student')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F5B4A), Color(0xFF1A7A64)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text((user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'S', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: Text((user?.role ?? '').toUpperCase(), style: const TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Row(children: [Icon(Icons.verified_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))])),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 14),
            Row(children: [
              _HeroStat(label: 'Orders', value: '${orders.length}', sub: activeCount > 0 ? '$activeCount active' : 'all time'),
              Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15)),
              _HeroStat(label: 'Spent', value: taka(totalSpent), sub: 'total paid'),
              Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15)),
              _HeroStat(label: 'Cart', value: '${cart.lines.length}', sub: cart.isEmpty ? 'empty' : '${taka(cart.subtotal)}'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Quick action row
        Row(children: [
          Expanded(
            child: _QuickPill(
              icon: Icons.receipt_long_rounded,
              label: 'Orders',
              value: '${orders.length}',
              onTap: () => context.go('/student/orders'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickPill(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              value: '${cart.lines.length} items',
              onTap: () => context.go('/student/cart'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickPill(
              icon: Icons.storefront_rounded,
              label: 'Vendors',
              value: 'Browse',
              onTap: () => context.go('/student/vendors'),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // Details
        AppCard(child: _row(Icons.badge_outlined, 'Student ID', user?.studentId ?? '—', copyable: user?.studentId != null)),
        AppCard(margin: const EdgeInsets.only(top: 8), child: _row(Icons.email_outlined, 'Email', user?.email ?? '—')),
        AppCard(margin: const EdgeInsets.only(top: 8), child: _row(Icons.shield_outlined, 'Role', (user?.role ?? '').toUpperCase())),
        AppCard(margin: const EdgeInsets.only(top: 8), child: _row(Icons.circle, 'Status', 'ACTIVE', valueColor: AppColors.success)),
        const SizedBox(height: 12),

        // Achievements
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFF59E0B)), SizedBox(width: 8), Text('Achievements', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))]),
            const SizedBox(height: 12),
            Row(children: [
              _Badge(icon: Icons.local_fire_department_rounded, label: 'First order', unlocked: orders.isNotEmpty, color: AppColors.warning),
              const SizedBox(width: 10),
              _Badge(icon: Icons.bolt_rounded, label: 'Regular', unlocked: orders.length >= 5, color: AppColors.brand),
              const SizedBox(width: 10),
              _Badge(icon: Icons.star_rounded, label: 'Foodie', unlocked: orders.length >= 10, color: Color(0xFFF59E0B)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (orders.length.clamp(0, 10)) / 10,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation(AppColors.brand),
              ),
            ),
            const SizedBox(height: 6),
            Text('${orders.length}/10 orders to unlock Foodie', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 12),

        // Preferences (interactive toggles - local only)
        const SectionHeader(title: 'Preferences', subtitle: 'Local settings'),
        const SizedBox(height: 8),
        _PrefTile(icon: Icons.notifications_outlined, title: 'Order updates', subtitle: 'Push when order is ready', value: true),
        _PrefTile(icon: Icons.dark_mode_outlined, title: 'Dark mode', subtitle: 'Coming soon', value: false),
        const SizedBox(height: 12),

        // Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Demo mode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)), Text('Mock payments — not connected to any real system. Data resets on server restart.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Sign out', icon: Icons.logout_rounded, outlined: true, onPressed: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
        const SizedBox(height: 8),
        Center(child: Text('IUB PAY • v0.1.0 • Campus prototype', style: TextStyle(color: AppColors.textTertiary.withOpacity(0.8), fontSize: 11))),
      ]),
    );
  }

  Widget _row(IconData ic, String label, String value, {bool copyable = false, Color? valueColor}) => Row(children: [
        Icon(ic, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        if (copyable) ...[
          const SizedBox(width: 8),
          Builder(builder: (ctx) => GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Copied'))); }, child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textTertiary))),
        ],
      ]);
}

class _HeroStat extends StatelessWidget {
  final String label, value, sub;
  const _HeroStat({required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(label.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11))]));
}

class _QuickPill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _QuickPill({required this.icon, required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: AppColors.brand)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)), Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700))])),
          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
        ]),
      );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.unlocked, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: unlocked ? color.withOpacity(0.10) : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: unlocked ? color.withOpacity(0.25) : AppColors.border)),
          child: Column(children: [
            Icon(icon, size: 20, color: unlocked ? color : AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: unlocked ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(unlocked ? 'Unlocked' : 'Locked', style: TextStyle(color: unlocked ? color : AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _PrefTile extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  const _PrefTile({required this.icon, required this.title, required this.subtitle, required this.value});
  @override
  State<_PrefTile> createState() => _PrefTileState();
}

class _PrefTileState extends State<_PrefTile> {
  late bool _val = widget.value;
  @override
  Widget build(BuildContext context) => AppCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(widget.icon, size: 16, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text(widget.subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
          Switch(value: _val, activeThumbColor: AppColors.brand, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _val = v); }),
        ]),
      );
}
