import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_providers.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _showPromo = true;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final first = user?.name.split(' ').first ?? 'there';
    final vendorsAsync = ref.watch(vendorListProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final cart = ref.watch(cartProvider);

    final vendorCount = vendorsAsync.valueOrNull?.length;
    final orders = ordersAsync.valueOrNull ?? [];
    final activeOrder = orders.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status)).isNotEmpty
        ? orders.firstWhere((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status))
        : null;
    final recentOrders = orders.take(3).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('$_greeting, $first ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(_greetingEmoji, style: TextStyle(fontSize: 13)),
            ]),
            Text('What would you like to eat today?', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w400)),
          ]),
        ]),
        actions: [
          ThemeToggleButton(),
          // Cart badge
          Stack(children: [
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, size: 20),
              tooltip: 'Cart',
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/student/cart');
              },
            ),
            if (!cart.isEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                  child: Text('${cart.lines.length}', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          IconButton(
            icon: Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      drawer: _StudentDrawer(userName: user?.name, email: user?.email, cartCount: cart.lines.length, orderCount: orders.length),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          ref.invalidate(vendorListProvider);
          ref.invalidate(myOrdersProvider);
          await Future.delayed(Duration(milliseconds: 400));
        },
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Search bar ──
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/student/vendors');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.search_rounded, size: 16, color: AppColors.brand),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Search vendors or dishes', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Try “biryani”, “burger”, “F-Block”', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ]),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textTertiary),
                  ),
                ]),
              ),
            ),
            SizedBox(height: 14),

            // ── Account summary — now with live stats ──
            AppCard(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Account',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.successBorder)),
                    child: Row(children: [
                      Icon(Icons.circle, size: 6, color: AppColors.success),
                      SizedBox(width: 6),
                      Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ]),
                  ),
                ]),
                SizedBox(height: 10),
                Text(user?.email ?? '', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                if (user?.studentId != null) ...[
                  SizedBox(height: 2),
                  Row(children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Icon(Icons.badge_outlined, size: 11, color: AppColors.textTertiary),
                        SizedBox(width: 4),
                        Text('ID ${user!.studentId}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ],
                SizedBox(height: 14),
                Container(height: 1, color: AppColors.border),
                SizedBox(height: 14),
                Row(children: [
                  _MiniStat(
                    label: 'Vendors',
                    value: vendorCount == null ? '…' : '$vendorCount',
                    sub: 'open now',
                    icon: Icons.storefront_rounded,
                  ),
                  Container(width: 1, height: 42, color: AppColors.border),
                  SizedBox(width: 12),
                  _MiniStat(
                    label: 'Orders',
                    value: ordersAsync.isLoading ? '…' : '${orders.length}',
                    sub: activeOrder != null ? '1 active' : 'all time',
                    icon: Icons.receipt_long_rounded,
                    highlight: activeOrder != null,
                  ),
                  Container(width: 1, height: 42, color: AppColors.border),
                  const SizedBox(width: 12),
                  _MiniStat(
                    label: 'Cart',
                    value: '${cart.lines.length}',
                    sub: cart.isEmpty ? 'empty' : taka(cart.subtotal),
                    icon: Icons.shopping_bag_outlined,
                    highlight: !cart.isEmpty,
                  ),
                ]),
              ]),
            ),

            // ── Active order banner ──
            if (activeOrder != null) ...[
              SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/student/orders/${activeOrder.id}');
                },
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0F5B4A), Color(0xFF147A63)]),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('Active order', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            child: Text(activeOrder.status.replaceAll('_', ' '), style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                          ),
                        ]),
                        SizedBox(height: 3),
                        Text('${activeOrder.orderNumber} • ${taka(activeOrder.totalAmount)} • ${activeOrder.pickupCode}',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Tap to track live', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.brand),
                    ),
                  ]),
                ),
              ),
            ],

            // ── Quick actions ──
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Quick actions',
              action: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/student/vendors');
                },
                child: const Text('See all', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 520;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.1 : 1.0,
                children: [
                  _ActionTile(
                    icon: Icons.storefront_rounded,
                    label: 'Browse vendors',
                    hint: vendorCount == null ? 'See what’s open' : '$vendorCount open now',
                    primary: true,
                    badge: vendorCount == null ? null : '$vendorCount',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/student/vendors');
                    },
                  ),
                  _ActionTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'My orders',
                    hint: orders.isEmpty ? 'Track & receipts' : '${orders.length} orders',
                    badge: activeOrder != null ? 'LIVE' : null,
                    badgeColor: AppColors.success,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/student/orders');
                    },
                  ),
                  _ActionTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cart',
                    hint: cart.isEmpty ? 'Review items' : '${taka(cart.subtotal)} • ${cart.lines.length} items',
                    badge: cart.isEmpty ? null : '${cart.lines.length}',
                    badgeColor: AppColors.brand,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/student/cart');
                    },
                  ),
                  _ActionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    hint: 'Account details',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/student/profile');
                    },
                  ),
                ],
              );
            }),

            // ── Featured vendors carousel ──
            const SizedBox(height: 20),
            vendorsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                final featured = list.take(5).toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionHeader(
                    title: 'Popular on campus',
                    subtitle: 'Tap a vendor to see menu',
                    action: TextButton(onPressed: () => context.go('/student/vendors'), child: const Text('View all', style: TextStyle(fontSize: 12))),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final v = featured[i];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go('/student/vendor/${v.id}');
                          },
                          child: Container(
                            width: 160,
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                  child: Icon(Icons.restaurant_rounded, color: AppColors.brand, size: 18),
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.successBorder)),
                                  child: Row(children: [
                                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                                    SizedBox(width: 4),
                                    Text('Open', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ]),
                              SizedBox(height: 12),
                              Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                              SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.place_outlined, size: 11, color: AppColors.textTertiary),
                                SizedBox(width: 3),
                                Expanded(child: Text(v.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                              ]),
                              Spacer(),
                              Row(children: [
                                Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                                SizedBox(width: 3),
                                Text('${(4.2 + (i * 0.3) % 0.7).toStringAsFixed(1)}', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                                Text(' • 15–20 min', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]);
              },
            ),

            // ── Recent orders ──
            if (recentOrders.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Recent orders',
                subtitle: 'Your last ${recentOrders.length} orders',
                action: TextButton(onPressed: () => context.go('/student/orders'), child: Text('History', style: TextStyle(fontSize: 12))),
              ),
              SizedBox(height: 10),
              ...recentOrders.map((o) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go('/student/orders/${o.id}');
                      },
                      padding: EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Icon(
                            switch (o.status) {
                              'PAID' => Icons.payments_outlined,
                              'PREPARING' => Icons.soup_kitchen_rounded,
                              'READY' => Icons.takeout_dining_rounded,
                              'COLLECTED' => Icons.check_circle_outline_rounded,
                              _ => Icons.receipt_outlined,
                            },
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(o.orderNumber, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))),
                              StatusChip(status: o.status),
                            ]),
                            SizedBox(height: 3),
                            Text('${o.items.length} items • ${taka(o.totalAmount)} • ${o.createdAt != null ? formatDate(o.createdAt!) : ''}',
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          ]),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                      ]),
                    ),
                  )),
            ],

            // ── Promo / tip banner ──
            if (_showPromo) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.info)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pro tip', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Order before 12:30 PM and skip the lunch rush — pickup is usually under 10 min.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
                    onPressed: () => setState(() => _showPromo = false),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 24, height: 24),
                  ),
                ]),
              ),
            ],

            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                SizedBox(width: 10),
                Expanded(child: Text('All payments are simulated. No real money moves.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3))),
              ]),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.invalidate(vendorListProvider);
                  ref.invalidate(myOrdersProvider);
                },
                icon: Icon(Icons.refresh_rounded, size: 14),
                label: Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final bool highlight;
  _MiniStat({required this.label, required this.value, required this.sub, required this.icon, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 11, color: highlight ? AppColors.brand : AppColors.textTertiary),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: highlight ? AppColors.brand : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        Text(sub, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool primary;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  _ActionTile({required this.icon, required this.label, required this.hint, this.primary = false, this.badge, this.badgeColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
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
          Spacer(),
          if (badge != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: (badgeColor ?? AppColors.brand).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: (badgeColor ?? AppColors.brand).withOpacity(0.2))),
              child: Text(badge!, style: TextStyle(color: badgeColor ?? AppColors.brand, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            ),
        ]),
        Spacer(),
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
        SizedBox(height: 2),
        Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        SizedBox(height: 8),
        Row(children: [
          Text(primary ? 'Browse' : 'Open',
              style: TextStyle(color: primary ? AppColors.brand : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 12, color: primary ? AppColors.brand : AppColors.textTertiary),
        ]),
      ]),
    );
  }
}

class _StudentDrawer extends ConsumerWidget {
  final String? userName;
  final String? email;
  final int cartCount;
  final int orderCount;
  _StudentDrawer({this.userName, this.email, this.cartCount = 0, this.orderCount = 0});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.person_rounded, color: Colors.white)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName ?? '', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                Text(email ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  _DrawerPill(icon: Icons.shopping_bag_outlined, label: '$cartCount in cart'),
                  SizedBox(width: 6),
                  _DrawerPill(icon: Icons.receipt_long_rounded, label: '$orderCount orders'),
                ]),
              ])),
            ]),
          ),
          _dTile(Icons.storefront_rounded, 'Browse food', () => context.go('/student/vendors')),
          _dTile(Icons.receipt_long_rounded, 'My orders', () => context.go('/student/orders'), trailing: orderCount > 0 ? '$orderCount' : null),
          _dTile(Icons.shopping_bag_outlined, 'Cart', () => context.go('/student/cart'), trailing: cartCount > 0 ? '$cartCount' : null),
          _dTile(Icons.person_outline_rounded, 'Profile', () => context.go('/student/profile')),
          Divider(color: AppColors.border, height: 1),
          ThemeToggleTile(),
          _dTile(Icons.logout_rounded, 'Sign out', () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          }, color: AppColors.error),
          Padding(padding: EdgeInsets.all(16), child: Text('Demo • Mock payments', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
        ]),
      );
  Widget _dTile(IconData ic, String t, VoidCallback onTap, {Color? color, String? trailing}) =>
      ListTile(
        leading: Icon(ic, color: color ?? AppColors.textPrimary, size: 20),
        title: Text(t, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: trailing == null ? null : Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(20)), child: Text(trailing, style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w700))),
        onTap: onTap,
      );
}

class _DrawerPill extends StatelessWidget {
  final IconData icon;
  final String label;
  _DrawerPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Row(children: [Icon(icon, size: 10, color: AppColors.textTertiary), SizedBox(width: 4), Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600))]),
      );
}