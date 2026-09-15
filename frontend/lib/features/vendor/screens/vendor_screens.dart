import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../student/providers/student_providers.dart' show orderDetailProvider;
import '../providers/vendor_providers.dart';
export '../providers/vendor_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vendor Dashboard — interactive, live
// ─────────────────────────────────────────────────────────────────────────────

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  String _statusFilter = 'ALL'; // ALL, PAID, ACCEPTED, PREPARING, READY
  String _search = '';
  int? _selectedBar;

  Future<void> _refreshAll() async {
    ref.invalidate(myVendorOrdersProvider);
    ref.invalidate(myVendorMenuProvider);
    ref.invalidate(vendorSalesProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final ordersAsync = ref.watch(myVendorOrdersProvider);
    final menuAsync = ref.watch(myVendorMenuProvider);
    final salesAsync = ref.watch(vendorSalesProvider);
    final wide = MediaQuery.of(context).size.width > 900;
    final isTablet = MediaQuery.of(context).size.width > 650;

    final orders = ordersAsync.valueOrNull ?? [];
    final menu = menuAsync.valueOrNull ?? [];

    final live = orders.where((o) => ['PAID', 'ACCEPTED', 'PREPARING'].contains(o.status)).toList();
    final ready = orders.where((o) => o.status == 'READY').toList();
    final collected = orders.where((o) => o.status == 'COLLECTED').toList();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final todayOrders = orders.where((o) => o.createdAt != null && o.createdAt!.toIso8601String().substring(0, 10) == todayStr).toList();
    final todayCollected = collected.where((o) => o.createdAt != null && o.createdAt!.toIso8601String().substring(0, 10) == todayStr).toList();

    int sum(Iterable<Order> os) => os.fold(0, (s, o) => s + o.totalAmount);

    final incomingCount = live.length;
    final navTiles = [
      (Icons.receipt_long_rounded, 'Incoming', '($incomingCount) live', '/vendor/orders', AppColors.brand),
      (Icons.edit_note_rounded, 'Menu', '${menu.where((m) => m.isAvailable).length}/${menu.length} active', '/vendor/menu', AppColors.info),
      (Icons.bar_chart_rounded, 'Sales', taka(sum(collected)), '/vendor/sales', AppColors.success),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vendor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
          Text(user?.name ?? 'My stall', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          // live pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: incomingCount > 0 ? AppColors.warningBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: incomingCount > 0 ? AppColors.border : AppColors.successBorder),
            ),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: incomingCount > 0 ? AppColors.warning : AppColors.success)),
              SizedBox(width: 6),
              Text(incomingCount > 0 ? '$incomingCount live' : 'All caught up', style: TextStyle(color: incomingCount > 0 ? AppColors.warning : AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
          ThemeToggleButton(),
          SizedBox(width: 4),
          IconButton(tooltip: 'Refresh', icon: Icon(Icons.refresh_rounded, size: 20), onPressed: _refreshAll),
          SizedBox(width: 2),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.go('/student/profile'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brand), child: Center(child: Text((user?.name ?? 'V')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
                  SizedBox(width: 6),
                  Text(user?.name.split(' ').first ?? 'Vendor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.logout_rounded, size: 18), tooltip: 'Sign out', onPressed: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
          SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ListView(padding: EdgeInsets.zero, children: [
                Container(
                  padding: EdgeInsets.fromLTRB(20, 48, 20, 20),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.storefront_rounded, color: Colors.white, size: 20)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user?.name ?? 'Vendor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text('Vendor workspace', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                  ]),
                ),
                SizedBox(height: 8),
                for (final t in navTiles)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: (t.$5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(t.$1, color: t.$5, size: 18)),
                      title: Text(t.$2, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(t.$3, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                      onTap: () => context.go(t.$4),
                    ),
                  ),
                Divider(height: 16),
                ThemeToggleTile(),
                ListTile(leading: Icon(Icons.logout_rounded, color: AppColors.error, size: 20), title: Text('Sign out', style: TextStyle(color: AppColors.error, fontSize: 14)), onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }),
              ]),
            ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Greeting + date strip ──
                AppCard(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Icon(Icons.waving_hand_rounded, size: 20, color: AppColors.brand)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_greeting(user?.name.split(' ').first ?? 'there'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)), SizedBox(height: 2), Text(formatDate(DateTime.now()) + ' • Tap any card to act', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                    if (wide)
                      FilledButton.icon(onPressed: () => context.go('/vendor/orders'), icon: Icon(Icons.play_arrow_rounded, size: 18), label: Text(incomingCount > 0 ? 'Process $incomingCount' : 'View orders'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), minimumSize: const Size(0, 36))),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── KPI grid ──
                ordersAsync.when(
                  loading: () => _VendorKpiSkeleton(isTablet: isTablet),
                  error: (e, _) => _VendorErrorCard(message: apiErrorMessage(e), onRetry: () => ref.invalidate(myVendorOrdersProvider)),
                  data: (_) => _VendorKpiGrid(
                    live: live.length,
                    ready: ready.length,
                    collected: collected.length,
                    todayCollected: todayCollected.length,
                    todayRevenue: sum(todayCollected),
                    totalRevenue: sum(collected),
                    liveRevenue: sum(live),
                    menuActive: menu.where((m) => m.isAvailable).length,
                    menuTotal: menu.length,
                    isTablet: isTablet,
                    salesAsync: salesAsync,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Sales mini chart + Pipeline ──
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _VendorSalesChart(orders: orders, selectedBar: _selectedBar, onBarTap: (i) => setState(() => _selectedBar = _selectedBar == i ? null : i))),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _PipelineCard(orders: orders)),
                  ])
                else ...[
                  _VendorSalesChart(orders: orders, selectedBar: _selectedBar, onBarTap: (i) => setState(() => _selectedBar = _selectedBar == i ? null : i)),
                  const SizedBox(height: 16),
                  _PipelineCard(orders: orders),
                ],
                const SizedBox(height: 16),

                // ── Manage tiles ──
                const SectionHeader(title: 'Manage', subtitle: 'Quick navigation'),
                SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.4 : 1.25,
                  children: [
                    for (final t in navTiles) _VendorManageTile(icon: t.$1, label: t.$2, subtitle: t.$3, color: t.$5, route: t.$4, badge: t.$2 == 'Incoming' && incomingCount > 0 ? '$incomingCount new' : null),
                    _VendorManageTile(icon: Icons.people_alt_outlined, label: 'Today', subtitle: '${todayOrders.length} orders', color: AppColors.warning, route: '/vendor/orders', badge: todayOrders.isNotEmpty ? 'today' : null),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Live queue + Menu health side-by-side on wide ──
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _LiveQueueCard(ordersAsync: ordersAsync, statusFilter: _statusFilter, search: _search, onFilterChanged: (v) => setState(() => _statusFilter = v), onSearchChanged: (v) => setState(() => _search = v))),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: Column(children: [_MenuHealthCard(menuAsync: menuAsync), const SizedBox(height: 16), _TopItemsCard(orders: orders)])),
                  ])
                else ...[
                  _LiveQueueCard(ordersAsync: ordersAsync, statusFilter: _statusFilter, search: _search, onFilterChanged: (v) => setState(() => _statusFilter = v), onSearchChanged: (v) => setState(() => _search = v)),
                  SizedBox(height: 16),
                  _MenuHealthCard(menuAsync: menuAsync),
                  SizedBox(height: 16),
                  _TopItemsCard(orders: orders),
                ],
                SizedBox(height: 16),

                // ── Recent activity ──
                _RecentActivityCard(orders: orders),
                SizedBox(height: 16),
                AppCard(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.info)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pro tip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(height: 2), Text('Accept orders quickly — students are notified instantly. Use pull-to-refresh to catch new PAID orders.', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.3))])),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final p = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return '$p, $name 👋';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI grid
// ─────────────────────────────────────────────────────────────────────────────

class _VendorKpiGrid extends StatelessWidget {
  final int live, ready, collected, todayCollected, todayRevenue, totalRevenue, liveRevenue, menuActive, menuTotal;
  final bool isTablet;
  final AsyncValue<Map<String, dynamic>> salesAsync;
  const _VendorKpiGrid({required this.live, required this.ready, required this.collected, required this.todayCollected, required this.todayRevenue, required this.totalRevenue, required this.liveRevenue, required this.menuActive, required this.menuTotal, required this.isTablet, required this.salesAsync});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isTablet ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: isTablet ? 1.65 : 1.45),
      children: [
        _VKpi(icon: Icons.local_fire_department_rounded, label: 'Live queue', value: '$live', sub: live > 0 ? '${taka(liveRevenue)} pending' : 'All clear', accent: live > 0 ? AppColors.warning : AppColors.success, highlight: live > 0, onTap: () => context.go('/vendor/orders')),
        _VKpi(icon: Icons.done_all_rounded, label: 'Ready', value: '$ready', sub: ready > 0 ? 'Awaiting pickup' : 'Nothing ready', accent: ready > 0 ? AppColors.success : AppColors.textTertiary, highlight: ready > 0, onTap: () => context.go('/vendor/orders')),
        _VKpi(icon: Icons.today_rounded, label: 'Today collected', value: '$todayCollected', sub: taka(todayRevenue), accent: AppColors.brand, onTap: () => context.go('/vendor/sales')),
        _VKpi(icon: Icons.account_balance_wallet_outlined, label: 'Total revenue', value: taka(totalRevenue), sub: '$collected collected', accent: AppColors.textPrimary, onTap: () => context.go('/vendor/sales')),
        _VKpi(icon: Icons.restaurant_menu_rounded, label: 'Menu active', value: '$menuActive/$menuTotal', sub: menuTotal - menuActive > 0 ? '${menuTotal - menuActive} hidden' : 'All visible', accent: AppColors.info, onTap: () => context.go('/vendor/menu')),
        _VKpi(icon: Icons.receipt_long_rounded, label: 'All orders', value: '${live + ready + collected}', sub: 'Live + ready + collected', accent: AppColors.textSecondary, onTap: () => context.go('/vendor/orders')),
        _VKpi(icon: Icons.analytics_outlined, label: 'Sales API', value: salesAsync.maybeWhen(data: (s) => taka(s['total_sales_taka'] as int? ?? 0), orElse: () => '—'), sub: 'Verified total', accent: AppColors.brand, onTap: () => context.go('/vendor/sales')),
        _VKpi(icon: Icons.add_rounded, label: 'Add item', value: '+', sub: 'New menu item', accent: AppColors.brand, isAction: true, onTap: () => context.go('/vendor/menu')),
      ],
    );
  }
}

class _VKpi extends StatefulWidget {
  final IconData icon;
  final String label, value, sub;
  final Color accent;
  final bool highlight, isAction;
  final VoidCallback onTap;
  _VKpi({required this.icon, required this.label, required this.value, required this.sub, required this.accent, this.highlight = false, this.isAction = false, required this.onTap});
  @override
  State<_VKpi> createState() => _VKpiState();
}

class _VKpiState extends State<_VKpi> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        decoration: BoxDecoration(color: widget.highlight ? AppColors.warningBg : AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: widget.highlight ? AppColors.border : (_hover ? AppColors.borderStrong : AppColors.border)), boxShadow: _hover ? AppShadows.cardHover : AppShadows.card),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: widget.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.accent.withOpacity(0.15))), child: Icon(widget.icon, size: 16, color: widget.accent)),
                  Spacer(),
                  Icon(widget.isAction ? Icons.open_in_new_rounded : Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                ]),
                Spacer(),
                Text(widget.label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                SizedBox(height: 4),
                Text(widget.value, style: TextStyle(color: widget.highlight ? AppColors.warning : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                SizedBox(height: 2),
                Text(widget.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.highlight ? AppColors.warning : AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorKpiSkeleton extends StatelessWidget {
  final bool isTablet;
  _VendorKpiSkeleton({required this.isTablet});
  @override
  Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), crossAxisCount: isTablet ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: isTablet ? 1.65 : 1.45, children: List.generate(8, (_) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 32, width: 32, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8))), Spacer(), Container(height: 10, width: 60, color: AppColors.surfaceMuted), SizedBox(height: 8), Container(height: 18, width: 70, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)))]))));
}

class _VendorErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  _VendorErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => AppCard(child: Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle, border: Border.all(color: AppColors.errorBorder)), child: Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Couldn’t load orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(height: 2), Text(message, style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])), TextButton(onPressed: onRetry, child: Text('Retry'))]));
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales chart (7 days from orders)
// ─────────────────────────────────────────────────────────────────────────────

class _VendorSalesChart extends StatelessWidget {
  final List<Order> orders;
  final int? selectedBar;
  final ValueChanged<int> onBarTap;
  const _VendorSalesChart({required this.orders, required this.selectedBar, required this.onBarTap});

  @override
  Widget build(BuildContext context) {
    // group last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final byDay = <String, List<Order>>{};
    for (final d in days) {
      final key = d.toIso8601String().substring(0, 10);
      byDay[key] = [];
    }
    for (final o in orders) {
      if (o.createdAt == null) continue;
      final k = o.createdAt!.toIso8601String().substring(0, 10);
      if (byDay.containsKey(k)) byDay[k]!.add(o);
    }
    final salesPerDay = days.map((d) {
      final k = d.toIso8601String().substring(0, 10);
      final list = byDay[k]!;
      final collected = list.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY', 'COLLECTED'].contains(o.status));
      return collected.fold<int>(0, (s, o) => s + o.totalAmount);
    }).toList();
    final maxSales = salesPerDay.fold<int>(1, (m, v) => math.max(m, v));
    final totalWeek = salesPerDay.fold<int>(0, (a, b) => a + b);

    return AppCard(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weekly sales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)), SizedBox(height: 2), Text('Tap a bar • last 7 days', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
          Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)), child: Text(taka(totalWeek) + ' this week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand))),
        ]),
        SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(takaCompact(maxSales), style: TextStyle(fontSize: 9, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
              Text(takaCompact((maxSales / 2).round()), style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
              Text('৳0', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
            ]),
            SizedBox(width: 8),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (int i = 0; i < 7; i++) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onBarTap(i),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          height: math.max(4, 110 * (salesPerDay[i] / maxSales)),
                          decoration: BoxDecoration(
                            color: selectedBar == i ? AppColors.brand : (i == 6 ? AppColors.brand : AppColors.brand.withOpacity(0.72)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: selectedBar == i ? AppColors.brandPressed : Colors.transparent, width: 1.4),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(_weekday(days[i]), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selectedBar == i ? AppColors.textPrimary : AppColors.textTertiary)),
                        Text('${days[i].month}/${days[i].day}', style: TextStyle(fontSize: 8, color: AppColors.textTertiary)),
                      ]),
                    ),
                  ),
                  if (i != 6) SizedBox(width: 6),
                ],
              ]),
            ),
          ]),
        ),
        SizedBox(height: 12),
        if (selectedBar != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(formatDate(days[selectedBar!]), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), SizedBox(height: 2), Text('${byDay[days[selectedBar!].toIso8601String().substring(0, 10)]!.length} orders • ${taka(salesPerDay[selectedBar!])}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
              IconButton(onPressed: () => onBarTap(selectedBar!), icon: Icon(Icons.close_rounded, size: 16), style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, side: BorderSide(color: AppColors.border))),
            ]),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.insights_outlined, size: 14, color: AppColors.textSecondary)),
              SizedBox(width: 10),
              Expanded(child: Text('${orders.length} total orders • avg ${orders.isEmpty ? taka(0) : taka((orders.fold<int>(0, (s, o) => s + o.totalAmount) / orders.length).round())} / order', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))),
              InkWell(onTap: () => context.go('/vendor/sales'), child: Text('Details →', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w700))),
            ]),
          ),
      ]),
    );
  }

  String _weekday(DateTime d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
}

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline
// ─────────────────────────────────────────────────────────────────────────────

class _PipelineCard extends StatelessWidget {
  final List<Order> orders;
  const _PipelineCard({required this.orders});
  @override
  Widget build(BuildContext context) {
    final counts = {
      'PAID': orders.where((o) => o.status == 'PAID').length,
      'ACCEPTED': orders.where((o) => o.status == 'ACCEPTED').length,
      'PREPARING': orders.where((o) => o.status == 'PREPARING').length,
      'READY': orders.where((o) => o.status == 'READY').length,
      'COLLECTED': orders.where((o) => o.status == 'COLLECTED').length,
    };
    final steps = ['PAID', 'ACCEPTED', 'PREPARING', 'READY', 'COLLECTED'];
    final icons = [Icons.payments_outlined, Icons.check_circle_outline_rounded, Icons.soup_kitchen_rounded, Icons.done_all_rounded, Icons.takeout_dining_rounded];
    return AppCard(
      padding: EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order pipeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
        SizedBox(height: 2),
        Text('Where every order sits', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        SizedBox(height: 14),
        Row(children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: counts[steps[i]]! > 0 ? AppColors.brand : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: counts[steps[i]]! > 0 ? AppColors.brand : AppColors.border),
                  ),
                  child: Icon(icons[i], size: 16, color: counts[steps[i]]! > 0 ? Colors.white : AppColors.textTertiary),
                ),
                SizedBox(height: 6),
                Text(steps[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: counts[steps[i]]! > 0 ? AppColors.textPrimary : AppColors.textTertiary)),
                SizedBox(height: 2),
                Container(padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: counts[steps[i]]! > 0 ? AppColors.brandSubtle : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)), child: Text('${counts[steps[i]]}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: counts[steps[i]]! > 0 ? AppColors.brand : AppColors.textTertiary))),
              ]),
            ),
            if (i != steps.length - 1) Container(width: 12, height: 2, color: AppColors.border, margin: EdgeInsets.only(bottom: 22)),
          ],
        ]),
        SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: [
            for (final s in steps)
              Expanded(
                flex: math.max(1, counts[s]!),
                child: Container(height: 6, color: s == 'PAID' ? AppColors.warning : s == 'READY' ? AppColors.success : s == 'COLLECTED' ? AppColors.textSecondary : AppColors.brand),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(onPressed: () => context.go('/vendor/orders'), icon: Icon(Icons.visibility_outlined, size: 14), label: const Text('Open queue', style: TextStyle(fontSize: 12))),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manage tiles
// ─────────────────────────────────────────────────────────────────────────────

class _VendorManageTile extends StatefulWidget {
  final IconData icon;
  final String label, subtitle, route;
  final Color color;
  final String? badge;
  _VendorManageTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.route, this.badge});
  @override
  State<_VendorManageTile> createState() => _VendorManageTileState();
}

class _VendorManageTileState extends State<_VendorManageTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: _hover ? widget.color.withOpacity(0.25) : AppColors.border), boxShadow: _hover ? AppShadows.cardHover : AppShadows.card),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => context.go(widget.route),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: widget.color.withOpacity(0.18))), child: Icon(widget.icon, color: widget.color, size: 20)),
                    Spacer(),
                    if (widget.badge != null) Container(padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)), child: Text(widget.badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning))),
                  ]),
                  Spacer(),
                  Text(widget.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
                  SizedBox(height: 2),
                  Text(widget.subtitle, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(children: [Text('Open', style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 12, color: widget.color)]),
                ]),
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Live queue card — filter + search + inline actions
// ─────────────────────────────────────────────────────────────────────────────

class _LiveQueueCard extends ConsumerWidget {
  final AsyncValue<List<Order>> ordersAsync;
  final String statusFilter;
  final String search;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  _LiveQueueCard({required this.ordersAsync, required this.statusFilter, required this.search, required this.onFilterChanged, required this.onSearchChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.warning)),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Live queue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Filter, search & take action', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
              TextButton(onPressed: () => context.go('/vendor/orders'), child: Text('View all', style: TextStyle(fontSize: 12))),
            ]),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(hintText: 'Search pickup code or order #', prefixIcon: Icon(Icons.search_rounded, size: 16), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border))),
              onChanged: onSearchChanged,
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final s in ['ALL', 'PAID', 'ACCEPTED', 'PREPARING', 'READY'])
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      selected: statusFilter == s,
                      selectedColor: AppColors.brandSubtle,
                      side: BorderSide(color: statusFilter == s ? AppColors.brand : AppColors.border),
                      labelStyle: TextStyle(color: statusFilter == s ? AppColors.brand : AppColors.textSecondary),
                      onSelected: (_) => onFilterChanged(s),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        Divider(height: 1),
        ordersAsync.when(
          loading: () => Padding(padding: EdgeInsets.all(24), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)))),
          error: (e, _) => Padding(padding: EdgeInsets.all(16), child: Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          data: (list) {
            var filtered = list.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status)).toList();
            if (statusFilter != 'ALL') filtered = filtered.where((o) => o.status == statusFilter).toList();
            if (search.trim().isNotEmpty) {
              final q = search.trim().toLowerCase();
              filtered = filtered.where((o) => o.pickupCode.toLowerCase().contains(q) || o.orderNumber.toLowerCase().contains(q)).toList();
            }
            filtered.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
            if (filtered.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceMuted, border: Border.all(color: AppColors.border)), child: Icon(Icons.inbox_outlined, size: 20, color: AppColors.textTertiary)),
                  SizedBox(height: 10),
                  Text(statusFilter == 'ALL' ? 'No live orders. New PAID orders appear here.' : 'No $statusFilter orders', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => ref.invalidate(myVendorOrdersProvider), icon: Icon(Icons.refresh_rounded, size: 14), label: Text('Refresh', style: TextStyle(fontSize: 12))),
                ]),
              );
            }
            final show = filtered.take(6).toList();
            return Column(children: [
              for (final o in show)
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: AppCard(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderStrong)), child: Text(o.pickupCode, style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.6, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.orderNumber, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('${taka(o.totalAmount)} • ${o.items.length} items • ${o.createdAt != null ? formatTime(o.createdAt!) : ''}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                        StatusChip(status: o.status),
                      ]),
                      SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (o.status == 'PAID') _MiniAction(label: 'Accept', icon: Icons.check_rounded, color: AppColors.brand, onTap: () => _setStatus(context, ref, o.id, 'ACCEPTED')),
                        if (o.status == 'ACCEPTED') _MiniAction(label: 'Start cooking', icon: Icons.soup_kitchen_rounded, color: AppColors.brand, onTap: () => _setStatus(context, ref, o.id, 'PREPARING')),
                        if (o.status == 'PREPARING') _MiniAction(label: 'Mark ready', icon: Icons.done_all_rounded, color: AppColors.success, onTap: () => _setStatus(context, ref, o.id, 'READY')),
                        if (o.status == 'READY') _MiniAction(label: 'Collected', icon: Icons.takeout_dining_rounded, color: AppColors.success, onTap: () => _setStatus(context, ref, o.id, 'COLLECTED')),
                        _MiniAction(label: 'Open', icon: Icons.open_in_new_rounded, color: AppColors.textSecondary, outlined: true, onTap: () => context.go('/vendor/orders/${o.id}')),
                      ]),
                    ]),
                  ),
                ),
              if (filtered.length > 6)
                Padding(padding: EdgeInsets.fromLTRB(14, 0, 14, 12), child: Text('+ ${filtered.length - 6} more • View all to see everything', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
            ]);
          },
        ),
      ]),
    );
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, String orderId, String status) async {
    try {
      await ref.read(dioProvider).patch('/orders/$orderId/status', data: {'status': status});
      ref.invalidate(myVendorOrdersProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order → $status')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _MiniAction({required this.label, required this.icon, required this.color, this.outlined = false, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: outlined
            ? OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 12, color: color), label: Text(label, style: TextStyle(fontSize: 11, color: color)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), side: BorderSide(color: color.withOpacity(0.3))))
            : FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 12), label: Text(label, style: TextStyle(fontSize: 11)), style: FilledButton.styleFrom(backgroundColor: color, padding: EdgeInsets.symmetric(horizontal: 10))),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu health
// ─────────────────────────────────────────────────────────────────────────────

class _MenuHealthCard extends StatelessWidget {
  final AsyncValue<List<MenuItem>> menuAsync;
  _MenuHealthCard({required this.menuAsync});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.textSecondary)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Menu health', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Availability at a glance', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            TextButton(onPressed: () => context.go('/vendor/menu'), child: Text('Manage', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Divider(height: 1),
        menuAsync.when(
          loading: () => Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)))),
          error: (e, _) => Padding(padding: EdgeInsets.all(16), child: Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  Text('No menu items yet.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.go('/vendor/menu'), icon: Icon(Icons.add_rounded, size: 16), label: Text('Add first item'))),
                ]),
              );
            }
            final avail = items.where((m) => m.isAvailable).length;
            final hidden = items.length - avail;
            return Padding(
              padding: EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.successBorder)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Available', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)), SizedBox(height: 4), Text('$avail', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.success))]))),
                  SizedBox(width: 8),
                  Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: hidden > 0 ? AppColors.warningBg : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: hidden > 0 ? AppColors.border : AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hidden', style: TextStyle(color: hidden > 0 ? AppColors.warning : AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)), SizedBox(height: 4), Text('$hidden', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: hidden > 0 ? AppColors.warning : AppColors.textTertiary))]))),
                ]),
                SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: items.isEmpty ? 0 : avail / items.length, minHeight: 6, backgroundColor: AppColors.surfaceMuted, valueColor: AlwaysStoppedAnimation(AppColors.success))),
                SizedBox(height: 12),
                ...items.take(3).map((it) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(it.isAvailable ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 14, color: it.isAvailable ? AppColors.success : AppColors.textTertiary),
                        SizedBox(width: 8),
                        Expanded(child: Text(it.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: it.isAvailable ? AppColors.textPrimary : AppColors.textTertiary, decoration: it.isAvailable ? null : TextDecoration.lineThrough))),
                        Text(taka(it.priceTaka), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ]),
                    )),
                if (items.length > 3) Text('+ ${items.length - 3} more', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top items (derived from orders)
// ─────────────────────────────────────────────────────────────────────────────

class _TopItemsCard extends StatelessWidget {
  final List<Order> orders;
  _TopItemsCard({required this.orders});
  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    final revenue = <String, int>{};
    for (final o in orders) {
      for (final it in o.items) {
        counts[it.name] = (counts[it.name] ?? 0) + it.quantity;
        revenue[it.name] = (revenue[it.name] ?? 0) + it.subtotal;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(14, 14, 14, 10), child: Row(children: [Icon(Icons.leaderboard_outlined, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Top items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))])),
        Divider(height: 1),
        if (top.isEmpty)
          Padding(padding: EdgeInsets.all(20), child: Text('No order history yet — top items appear after sales.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)))
        else
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(children: [
              for (int i = 0; i < top.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 26, height: 26, decoration: BoxDecoration(color: i == 0 ? AppColors.warningBg : AppColors.surfaceMuted, shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: i == 0 ? AppColors.warning : AppColors.textTertiary)))),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(top[i].key, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('${top[i].value} sold • ${taka(revenue[top[i].key] ?? 0)}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                    Container(width: 60, height: 6, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(3)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: top.isEmpty ? 0 : top[i].value / top.first.value, child: Container(decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(3))))),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent activity
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivityCard extends StatelessWidget {
  final List<Order> orders;
  _RecentActivityCard({required this.orders});
  @override
  Widget build(BuildContext context) {
    final recent = [...orders]..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    final show = recent.take(5).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.history_rounded, size: 14, color: AppColors.textSecondary)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Latest orders across all statuses', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            TextButton(onPressed: () => context.go('/vendor/sales'), child: Text('Sales', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Divider(height: 1),
        if (show.isEmpty)
          Padding(padding: EdgeInsets.all(20), child: Text('No orders yet.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)))
        else
          Column(children: [
            for (final o in show)
              InkWell(
                onTap: () => context.go('/vendor/orders/${o.id}'),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Center(child: Text(o.pickupCode.characters.take(2).toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${o.orderNumber} • ${taka(o.totalAmount)}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('${formatDate(o.createdAt ?? DateTime.now())} • ${o.items.length} items', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                    StatusChip(status: o.status),
                  ]),
                ),
              ),
          ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keep existing sub-screens (Incoming / Detail) — improved
// ─────────────────────────────────────────────────────────────────────────────

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppTopBar(title: 'Incoming orders', subtitle: 'Paid orders needing attention', onBack: () => context.go('/vendor')),
        body: const IncomingOrdersView(),
      );
}

class IncomingOrdersView extends ConsumerWidget {
  const IncomingOrdersView({super.key});
  static const _liveStatuses = ['PAID', 'ACCEPTED', 'PREPARING'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myVendorOrdersProvider);
    return orders.when(
      loading: () => LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorOrdersProvider)),
      data: (list) {
        final live = list.where((o) => _liveStatuses.contains(o.status)).toList()
          ..sort((a, b) => a.createdAt == null || b.createdAt == null ? 0 : a.createdAt!.compareTo(b.createdAt!));
        if (live.isEmpty) {
          return EmptyView(icon: Icons.room_service_outlined, message: 'No live paid orders. New paid orders appear here automatically.');
        }
        return RefreshIndicator(
          color: AppColors.brand,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async => ref.invalidate(myVendorOrdersProvider),
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: live.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = live[i];
              return AppCard(
                onTap: () => context.go('/vendor/orders/${o.id}'),
                padding: EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderStrong)),
                    child: Text(o.pickupCode, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.8, fontSize: 12)),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.orderNumber, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('${taka(o.totalAmount)} • ${o.items.length} items', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ])),
                  StatusChip(status: o.status),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}

class VendorOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const VendorOrderDetailScreen({super.key, required this.orderId});
  Future<void> _setStatus(BuildContext context, WidgetRef ref, String orderId, String status) async {
    try {
      await ref.read(dioProvider).patch('/orders/$orderId/status', data: {'status': status});
      ref.invalidate(myVendorOrdersProvider);
      ref.invalidate(orderDetailProvider(orderId));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
          title: 'Order',
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor/orders');
            }
          }),
      body: order.when(
        loading: () => LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: EdgeInsets.all(16), children: [
          AppCard(
            child: Column(children: [
              Center(child: StatusChip(status: o.status)),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('PICKUP', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  SizedBox(width: 10),
                  Text(o.pickupCode, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 5, fontSize: 18)),
                ]),
              ),
              if (o.createdAt != null) ...[SizedBox(height: 8), Text(formatDateTime(o.createdAt!), style: TextStyle(color: AppColors.textTertiary, fontSize: 11))],
            ]),
          ),
          SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...o.items.map((it) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                    Expanded(child: Text(it.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Text('${it.quantity} × ${taka(it.unitPrice)}', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    SizedBox(width: 10),
                    Text(taka(it.subtotal), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]))),
              Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)), PriceText(o.totalAmount)]),
            ]),
          ),
          const SizedBox(height: 12),
          _action(context, ref, o, 'ACCEPTED', Icons.check_rounded, 'Accept order'),
          _action(context, ref, o, 'PREPARING', Icons.soup_kitchen_rounded, 'Start preparing'),
          _action(context, ref, o, 'READY', Icons.done_all_rounded, 'Mark ready'),
          _action(context, ref, o, 'COLLECTED', Icons.takeout_dining_rounded, 'Mark collected'),
          _action(context, ref, o, 'REJECTED', Icons.block_rounded, 'Reject & refund', isDestructive: true),
        ]),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, Order o, String target, IconData icon, String label, {bool isDestructive = false}) {
    final allowed = switch (target) {
      'ACCEPTED' => o.status == 'PAID',
      'REJECTED' => ['PAID', 'ACCEPTED'].contains(o.status),
      'PREPARING' => ['ACCEPTED'].contains(o.status),
      'READY' => o.status == 'PREPARING',
      'COLLECTED' => o.status == 'READY',
      _ => false,
    };
    if (!allowed) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: isDestructive
            ? OutlinedButton.icon(onPressed: () => _setStatus(context, ref, o.id, target), icon: Icon(icon, size: 16, color: AppColors.error), label: Text(label, style: TextStyle(color: AppColors.error)), style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.errorBorder)))
            : FilledButton.icon(onPressed: () => _setStatus(context, ref, o.id, target), icon: Icon(icon, size: 16), label: Text(label)),
      ),
    );
  }
}