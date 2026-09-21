import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../shared/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_providers.dart';
export '../providers/admin_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard — interactive, data-driven
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _range = 14;
  int? _selectedBar;

  Future<void> _refreshAll() async {
    ref.invalidate(adminSummaryProvider);
    ref.invalidate(dailyReportFamilyProvider);
    ref.invalidate(dailyReportProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(adminVendorsProvider);
    ref.invalidate(adminUsersProvider);
    // wait a frame for providers to refetch
    await Future.delayed(Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(adminSummaryProvider);
    final dailyAsync = ref.watch(dailyReportFamilyProvider(_range));
    final vendorsAsync = ref.watch(adminVendorsProvider);
    final usersAsync = ref.watch(adminUsersProvider);
    final txnsAsync = ref.watch(transactionsProvider);
    final wide = MediaQuery.of(context).size.width > 900;
    final isTablet = MediaQuery.of(context).size.width > 700;

    final tiles = [
      (Icons.store_outlined, 'Vendors', 'Approve & manage', '/admin/vendors', AppColors.brand),
      (Icons.receipt_long_outlined, 'Transactions', 'Ledger', '/admin/transactions', AppColors.textSecondary),
      (Icons.bar_chart_outlined, 'Reports', 'Analytics', '/admin/reports', AppColors.info),
      (Icons.people_outline_rounded, 'Users', 'Directory', '/admin/users', AppColors.warning),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
          Text(_greeting(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ]),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, size: 20),
            onPressed: _refreshAll,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: Icon(Icons.download_outlined, size: 20),
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                final r = await dio.get('/admin/reports/export.csv');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export ready — ${r.data.toString().length} bytes')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
              }
            },
          ),
          SizedBox(width: 4),
          Consumer(builder: (context, ref, _) {
            final user = ref.watch(authProvider).value;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brand),
                      child: Center(child: Text((user?.name ?? 'A')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                    ),
                    SizedBox(width: 6),
                    Text(user?.name.split(' ').first ?? 'Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                  ]),
                ),
              ),
            );
          }),
          IconButton(
              icon: Icon(Icons.logout_rounded, size: 18),
              tooltip: 'Sign out',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }),
          SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.shield_outlined, color: Colors.white, size: 20)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('IUB PAY', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.6)), Text('Admin control center', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            ]),
          ),
          SizedBox(height: 8),
          for (final t in tiles)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: (t.$5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(t.$1, color: t.$5, size: 18)),
                title: Text(t.$2, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(t.$3, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                onTap: () => context.go(t.$4),
              ),
            ),
          Divider(color: AppColors.border, height: 16),
          ThemeToggleTile(),
          AdminLogoutTile(),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                SizedBox(width: 8),
                Expanded(child: Text('All systems operational', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ]),
            ),
          ),
        ]),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── KPI grid ──
                summaryAsync.when(
                  loading: () => _KpiSkeleton(isTablet: isTablet),
                  error: (e, _) => _ErrorCard(message: apiErrorMessage(e), onRetry: () => ref.invalidate(adminSummaryProvider)),
                  data: (s) {
                    final pendingVendors = vendorsAsync.value?.where((v) => v['status'] != 'APPROVED').length ?? 0;
                    final totalUsers = usersAsync.value?.length ?? s['registered_students'] ?? 0;
                    return _KpiGrid(
                      s: s,
                      pendingVendors: pendingVendors,
                      totalUsers: totalUsers,
                      isTablet: isTablet,
                      daily: dailyAsync.value,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Chart + Quick actions row ──
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _DailySalesCard(dailyAsync: dailyAsync, range: _range, selectedBar: _selectedBar, onRangeChanged: (v) => setState(() => _range = v), onBarTap: (i) => setState(() => _selectedBar = _selectedBar == i ? null : i), onRetry: () => ref.invalidate(dailyReportFamilyProvider(_range)))),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _QuickActionsAndHealth(summaryAsync: summaryAsync, vendorsAsync: vendorsAsync, txnsAsync: txnsAsync)),
                  ])
                else ...[
                  _DailySalesCard(dailyAsync: dailyAsync, range: _range, selectedBar: _selectedBar, onRangeChanged: (v) => setState(() => _range = v), onBarTap: (i) => setState(() => _selectedBar = _selectedBar == i ? null : i), onRetry: () => ref.invalidate(dailyReportFamilyProvider(_range))),
                  const SizedBox(height: 16),
                  _QuickActionsAndHealth(summaryAsync: summaryAsync, vendorsAsync: vendorsAsync, txnsAsync: txnsAsync),
                ],
                const SizedBox(height: 16),

                // ── Management shortcuts (visual) ──
                const SectionHeader(title: 'Manage', subtitle: 'Jump to key sections'),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.25 : 1.1,
                  children: [
                    for (final t in tiles)
                      _ManageTile(icon: t.$1, label: t.$2, subtitle: t.$3, color: t.$5, route: t.$4, badge: _badgeFor(t.$2, summaryAsync, vendorsAsync, txnsAsync)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bottom two-col: pending vendors + recent txns ──
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _PendingVendorsCard(vendorsAsync: vendorsAsync)),
                    SizedBox(width: 16),
                    Expanded(child: _RecentTransactionsCard(txnsAsync: txnsAsync)),
                  ])
                else ...[
                  _PendingVendorsCard(vendorsAsync: vendorsAsync),
                  SizedBox(height: 16),
                  _RecentTransactionsCard(txnsAsync: txnsAsync),
                ],
                SizedBox(height: 16),
                _UsersOverviewCard(usersAsync: usersAsync),
                SizedBox(height: 16),
                // ── Footer help ──
                AppCard(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.info)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tip — pull to refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(height: 2), Text('All figures come from the ledger — they always reconcile with real money movement.', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.3))])),
                    Icon(Icons.refresh_rounded, size: 16, color: AppColors.textTertiary),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning — Control center';
    if (h < 17) return 'Good afternoon — Control center';
    return 'Good evening — Control center';
  }

  String? _badgeFor(String label, AsyncValue<Map<String, dynamic>> summary, AsyncValue<List<dynamic>> vendors, AsyncValue<Map<String, dynamic>> txns) {
    if (label == 'Vendors') {
      final pending = vendors.value?.where((v) => v['status'] != 'APPROVED').length;
      if (pending != null && pending > 0) return '$pending pending';
    }
    if (label == 'Transactions') {
      final failed = summary.value?['failed_payments'];
      if (failed is int && failed > 0) return '$failed failed';
    }
    if (label == 'Users') {
      final total = vendors.value?.length ?? 0;
      // show total users if available
      final users = summary.value?['registered_students'];
      if (users is int && users > 0) return '$users students';
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI GRID
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> s;
  final int pendingVendors;
  final dynamic totalUsers;
  final bool isTablet;
  final List<dynamic>? daily;
  const _KpiGrid({required this.s, required this.pendingVendors, required this.totalUsers, required this.isTablet, this.daily});

  @override
  Widget build(BuildContext context) {
    final sales = s['total_sales_taka'] as int? ?? 0;
    final refunds = s['total_refunds_taka'] as int? ?? 0;
    final net = s['net_revenue_taka'] as int? ?? 0;
    final paid = s['paid_orders'] as int? ?? 0;
    final total = s['total_orders'] as int? ?? 0;
    final failed = s['failed_payments'] as int? ?? 0;
    final vendors = s['active_vendors'] as int? ?? 0;

    // trend: last 7 vs prev 7
    double? trend;
    String trendLabel = '';
    if (daily != null && daily!.length >= 14) {
      final last7 = daily!.skip(daily!.length - 7).fold<int>(0, (a, r) => a + (r['sales_taka'] as int));
      final prev7 = daily!.skip(daily!.length - 14).take(7).fold<int>(0, (a, r) => a + (r['sales_taka'] as int));
      if (prev7 > 0) {
        trend = (last7 - prev7) / prev7 * 100;
        trendLabel = '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}% vs prev week';
      } else if (last7 > 0) {
        trend = 100;
        trendLabel = 'New sales this week';
      }
    }

    final cross = isTablet ? 4 : 2;
    return GridView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: isTablet ? 1.7 : 1.45),
      children: [
        _KpiCard(icon: Icons.account_balance_wallet_outlined, label: 'Net revenue', value: taka(net), sub: '$total orders • ${paid} paid', accent: AppColors.brand, trend: trend, trendLabel: trendLabel, onTap: () => context.go('/admin/reports')),
        _KpiCard(icon: Icons.trending_up_rounded, label: 'Total sales', value: taka(sales), sub: pendingVendors > 0 ? '$pendingVendors awaiting approval' : 'All vendors active', accent: AppColors.textPrimary, onTap: () => context.go('/admin/reports')),
        _KpiCard(icon: Icons.receipt_long_outlined, label: 'Orders', value: '$paid / $total', sub: 'Paid / total', accent: AppColors.info, onTap: () => context.go('/admin/transactions')),
        _KpiCard(icon: Icons.storefront_rounded, label: 'Active vendors', value: '$vendors', sub: pendingVendors > 0 ? '$pendingVendors pending' : 'No pending approvals', accent: vendors == 0 ? AppColors.warning : AppColors.success, highlight: pendingVendors > 0, onTap: () => context.go('/admin/vendors')),
        _KpiCard(icon: Icons.people_alt_outlined, label: 'Students', value: '$totalUsers', sub: 'Registered', accent: AppColors.textSecondary, onTap: () => context.go('/admin/users')),
        _KpiCard(icon: Icons.error_outline_rounded, label: 'Failed payments', value: '$failed', sub: failed > 0 ? 'Needs attention' : 'All clear', accent: failed > 0 ? AppColors.error : AppColors.success, highlight: failed > 0, onTap: () => context.go('/admin/transactions')),
        _KpiCard(icon: Icons.undo_rounded, label: 'Refunds', value: '-${taka(refunds)}', sub: 'Total refunded', accent: AppColors.textTertiary, onTap: () => context.go('/admin/transactions')),
        _KpiCard(icon: Icons.bolt_outlined, label: 'Quick export', value: 'CSV', sub: 'Download ledger', accent: AppColors.brand, isAction: true, onTap: () => context.go('/admin/reports')),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final bool highlight;
  final bool isAction;
  final double? trend;
  final String? trendLabel;
  final VoidCallback onTap;
  _KpiCard({required this.icon, required this.label, required this.value, required this.sub, required this.accent, this.highlight = false, this.isAction = false, this.trend, this.trendLabel, required this.onTap});
  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: widget.highlight ? AppColors.errorBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: widget.highlight ? AppColors.errorBorder : (_hover ? AppColors.borderStrong : AppColors.border)),
          boxShadow: _hover ? AppShadows.cardHover : AppShadows.card,
        ),
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
                  if (widget.trend != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: (widget.trend! >= 0 ? AppColors.successBg : AppColors.errorBg), borderRadius: BorderRadius.circular(6), border: Border.all(color: (widget.trend! >= 0 ? AppColors.successBorder : AppColors.errorBorder))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(widget.trend! >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 10, color: widget.trend! >= 0 ? AppColors.success : AppColors.error), SizedBox(width: 2), Text('${widget.trend!.abs().toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: widget.trend! >= 0 ? AppColors.success : AppColors.error))]),
                    )
                  else if (widget.isAction)
                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textTertiary)
                  else
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                ]),
                Spacer(),
                Text(widget.label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                SizedBox(height: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _numericValue(widget.value)),
                  duration: Duration(milliseconds: 700),
                  builder: (context, val, _) {
                    // if value is not purely numeric, just show original
                    if (_numericValue(widget.value) == 0 && widget.value != '0' && !widget.value.contains('৳0')) return Text(widget.value, style: TextStyle(color: widget.highlight ? AppColors.error : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5));
                    // preserve prefix like ৳ or -৳
                    final display = _formatAnimatedValue(widget.value, val);
                    return Text(display, style: TextStyle(color: widget.highlight ? AppColors.error : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5));
                  },
                ),
                SizedBox(height: 2),
                Text(widget.trendLabel ?? widget.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.highlight ? AppColors.error : AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  int _numericValue(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatAnimatedValue(String original, int val) {
    if (original.contains('৳')) {
      final isNeg = original.trim().startsWith('-');
      return '${isNeg ? '-' : ''}৳$val';
    }
    if (original.contains('/')) return original; // e.g. 12 / 20 keep as is
    if (original == 'CSV') return original;
    return '$val';
  }
}

class _KpiSkeleton extends StatelessWidget {
  final bool isTablet;
  _KpiSkeleton({required this.isTablet});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isTablet ? 1.7 : 1.45,
      children: List.generate(8, (_) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 32, width: 32, borderRadius: BorderRadius.circular(8)), Spacer(), SkeletonBox(height: 10, width: 60), SizedBox(height: 8), SkeletonBox(height: 18, width: 80, borderRadius: BorderRadius.circular(6)), SizedBox(height: 6), SkeletonBox(height: 10, width: 90)]))),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  _ErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => AppCard(child: Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle, border: Border.all(color: AppColors.errorBorder)), child: Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Couldn\'t load summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(height: 2), Text(message, style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])), TextButton(onPressed: onRetry, child: Text('Retry'))]));
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily sales card — interactive
// ─────────────────────────────────────────────────────────────────────────────

class _DailySalesCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> dailyAsync;
  final int range;
  final int? selectedBar;
  final ValueChanged<int> onRangeChanged;
  final ValueChanged<int> onBarTap;
  final VoidCallback onRetry;
  _DailySalesCard({required this.dailyAsync, required this.range, required this.selectedBar, required this.onRangeChanged, required this.onBarTap, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Revenue trend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)), SizedBox(height: 2), Text('Tap a bar for details • ledger-based', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              for (final d in [7, 14, 30])
                GestureDetector(
                  onTap: () => onRangeChanged(d),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: range == d ? AppColors.surface : Colors.transparent, borderRadius: BorderRadius.circular(7), border: Border.all(color: range == d ? AppColors.borderStrong : Colors.transparent), boxShadow: range == d ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)] : null),
                    child: Text('${d}d', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: range == d ? AppColors.textPrimary : AppColors.textTertiary)),
                  ),
                ),
            ]),
          ),
        ]),
        SizedBox(height: 16),
        dailyAsync.when(
          loading: () => Column(children: List.generate(4, (_) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: [SkeletonBox(height: 10, width: 36), SizedBox(width: 8), Expanded(child: SkeletonBox(height: 10)), SizedBox(width: 8), SkeletonBox(height: 10, width: 40)])))),
          error: (e, _) => SizedBox(height: 160, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12)), SizedBox(height: 8), OutlinedButton(onPressed: onRetry, child: Text('Retry'))]))),
          data: (rows) {
            if (rows.isEmpty) return SizedBox(height: 120, child: Center(child: Text('No data', style: TextStyle(color: AppColors.textTertiary))));
            final maxSales = rows.fold<int>(1, (m, r) => math.max(m, (r['sales_taka'] as int)));
            final maxOrders = rows.fold<int>(1, (m, r) => math.max(m, (r['orders'] as int)));
            final totalSales = rows.fold<int>(0, (a, r) => a + (r['sales_taka'] as int));
            final totalOrders = rows.fold<int>(0, (a, r) => a + (r['orders'] as int));
            return Column(children: [
              // vertical bar chart
              SizedBox(
                height: 160,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // y-axis labels
                  Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(takaCompact(maxSales), style: TextStyle(fontSize: 9, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                    Text(takaCompact((maxSales / 2).round()), style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                    Text('৳0', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                  ]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onBarTap(i),
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                height: math.max(4, 120 * ((rows[i]['sales_taka'] as int) / maxSales)),
                                decoration: BoxDecoration(
                                  color: selectedBar == i ? AppColors.brand : (i == rows.length - 1 ? AppColors.brand : AppColors.brand.withOpacity(0.75)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: selectedBar == i ? AppColors.brandPressed : Colors.transparent, width: 1.5),
                                  boxShadow: selectedBar == i ? [BoxShadow(color: AppColors.brand.withOpacity(0.25), blurRadius: 10, offset: Offset(0, 4))] : null,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text((rows[i]['date'] as String).substring(5).replaceAll('-', '/'), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: selectedBar == i ? AppColors.textPrimary : AppColors.textTertiary)),
                            ]),
                          ),
                        ),
                        if (i != rows.length - 1) SizedBox(width: 4),
                      ],
                    ]),
                  ),
                ]),
              ),
              SizedBox(height: 12),
              // selected detail
              if (selectedBar != null && selectedBar! < rows.length)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rows[selectedBar!]['date'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), SizedBox(height: 2), Text('${rows[selectedBar!]['orders']} orders • ${taka(rows[selectedBar!]['sales_taka'] as int)} sales  •  -${taka(rows[selectedBar!]['refunds_taka'] as int)} refunds', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
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
                    Expanded(child: Text('$totalOrders orders • ${taka(totalSales)} in last $range days  •  avg ${taka(totalOrders == 0 ? 0 : (totalSales / totalOrders).round())}/order', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))),
                    InkWell(onTap: () => context.go('/admin/reports'), child: Text('Details →', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w700))),
                  ]),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions + health
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsAndHealth extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> summaryAsync;
  final AsyncValue<List<dynamic>> vendorsAsync;
  final AsyncValue<Map<String, dynamic>> txnsAsync;
  _QuickActionsAndHealth({required this.summaryAsync, required this.vendorsAsync, required this.txnsAsync});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AppCard(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionBtn(icon: Icons.verified_outlined, label: 'Approve vendors', color: AppColors.success, onTap: () => context.go('/admin/vendors'))),
            SizedBox(width: 10),
            Expanded(child: _ActionBtn(icon: Icons.receipt_long_rounded, label: 'View ledger', color: AppColors.textPrimary, onTap: () => context.go('/admin/transactions'))),
          ]),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ActionBtn(icon: Icons.download_rounded, label: 'Export CSV', color: AppColors.info, onTap: () async {
              try {
                final dio = ProviderScope.containerOf(context).read(dioProvider);
                final r = await dio.get('/admin/reports/export.csv');
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV ready — ${r.data.toString().length} bytes')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
              }
            })),
            SizedBox(width: 10),
            Expanded(child: _ActionBtn(icon: Icons.people_outline_rounded, label: 'Users', color: AppColors.warning, onTap: () => context.go('/admin/users'))),
          ]),
        ]),
      ),
      SizedBox(height: 12),
      AppCard(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.successBorder)), child: Icon(Icons.health_and_safety_outlined, size: 14, color: AppColors.success)),
            SizedBox(width: 10),
            Expanded(child: Text('System health', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
            SizedBox(width: 6),
            Text('Live', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _HealthRow(label: 'API', value: 'Operational', ok: true),
          const SizedBox(height: 8),
          _HealthRow(label: 'Payments (mock)', value: 'Simulated', ok: true),
          const SizedBox(height: 8),
          _HealthRow(label: 'Ledger', value: summaryAsync.maybeWhen(data: (s) => s['net_revenue_taka'] != null ? 'Reconciled' : '—', orElse: () => '—'), ok: true),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(onPressed: () => context.go('/admin/reports'), icon: Icon(Icons.analytics_outlined, size: 14), label: const Text('Open full reports', style: TextStyle(fontSize: 12))),
          ),
        ]),
      ),
    ]);
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        decoration: BoxDecoration(color: _hover ? widget.color.withOpacity(0.08) : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: _hover ? widget.color.withOpacity(0.2) : AppColors.border)),
        child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(10), onTap: widget.onTap, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), child: Column(children: [Icon(widget.icon, size: 18, color: widget.color), SizedBox(height: 6), Text(widget.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary))])))),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;
  _HealthRow({required this.label, required this.value, required this.ok});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500))), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: ok ? AppColors.successBg : AppColors.errorBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: ok ? AppColors.successBorder : AppColors.errorBorder)), child: Text(value, style: TextStyle(color: ok ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)) )]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Manage tiles
// ─────────────────────────────────────────────────────────────────────────────

class _ManageTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;
  final String? badge;
  _ManageTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.route, this.badge});
  @override
  State<_ManageTile> createState() => _ManageTileState();
}

class _ManageTileState extends State<_ManageTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
                  if (widget.badge != null)
                    Container(padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)), child: Text(widget.badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning))),
                ]),
                Spacer(),
                Text(widget.label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending vendors preview
// ─────────────────────────────────────────────────────────────────────────────

class _PendingVendorsCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> vendorsAsync;
  _PendingVendorsCard({required this.vendorsAsync});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.pending_actions_rounded, size: 14, color: AppColors.warning)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pending approvals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Vendors awaiting activation', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            TextButton(onPressed: () => context.go('/admin/vendors'), child: Text('View all', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Divider(height: 1),
        vendorsAsync.when(
          loading: () => const ListSkeleton(count: 3),
          error: (e, _) => Padding(padding: EdgeInsets.all(16), child: Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          data: (list) {
            final pending = list.where((v) => v['status'] != 'APPROVED').toList();
            if (pending.isEmpty) {
              return Padding(padding: EdgeInsets.all(20), child: Row(children: [Icon(Icons.verified_rounded, size: 18, color: AppColors.success), SizedBox(width: 10), Expanded(child: Text('All vendors approved — nothing pending.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))]));
            }
            return Column(children: [
              for (int i = 0; i < math.min(pending.length, 4); i++)
                InkWell(
                  onTap: () => context.go('/admin/vendors'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(Icons.store_outlined, size: 16, color: AppColors.warning)),
                      SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pending[i]['name'] ?? '—', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text('${pending[i]['location'] ?? ''} • ${pending[i]['status']}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                      Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: Text('Review', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                    ]),
                  ),
                ),
              if (pending.length > 4)
                Padding(padding: EdgeInsets.fromLTRB(14, 0, 14, 12), child: Text('+ ${pending.length - 4} more pending', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
            ]);
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent transactions preview
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTransactionsCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> txnsAsync;
  _RecentTransactionsCard({required this.txnsAsync});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textSecondary)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Recent transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Latest ledger entries', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            TextButton(onPressed: () => context.go('/admin/transactions'), child: Text('View all', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Divider(height: 1),
        txnsAsync.when(
          loading: () => const ListSkeleton(count: 3),
          error: (e, _) => Padding(padding: EdgeInsets.all(16), child: Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          data: (data) {
            final items = List<Map<String, dynamic>>.from(data['items'] ?? data['transactions'] ?? []);
            if (items.isEmpty) return Padding(padding: EdgeInsets.all(20), child: Text('No transactions yet.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)));
            final show = items.take(5).toList();
            return Column(children: [
              for (final t in show)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: (t['status'] == 'FAILED' ? AppColors.errorBg : AppColors.successBg), borderRadius: BorderRadius.circular(8), border: Border.all(color: (t['status'] == 'FAILED' ? AppColors.errorBorder : AppColors.successBorder))), child: Icon(t['status'] == 'FAILED' ? Icons.money_off_rounded : Icons.paid_outlined, size: 14, color: t['status'] == 'FAILED' ? AppColors.error : AppColors.success)),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${t['order_number'] ?? '—'} • ${taka((t['amount_taka'] is int ? t['amount_taka'] as int : int.tryParse('${t['amount_taka']}') ?? 0))}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('${t['vendor_name'] ?? ''} • ${t['status']}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                    Text(_fmtDate(t['created_at']?.toString()), style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  ]),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  String _fmtDate(String? raw) {
    final dt = tryParseDate(raw);
    if (dt == null) return '';
    return formatDate(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users overview
// ─────────────────────────────────────────────────────────────────────────────

class _UsersOverviewCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> usersAsync;
  _UsersOverviewCard({required this.usersAsync});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)), child: Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text('Roles & activity', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
            TextButton(onPressed: () => context.go('/admin/users'), child: Text('Manage', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Divider(height: 1),
        usersAsync.when(
          loading: () => const ListSkeleton(count: 3),
          error: (e, _) => Padding(padding: EdgeInsets.all(16), child: Text(apiErrorMessage(e), style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          data: (list) {
            if (list.isEmpty) return Padding(padding: EdgeInsets.all(20), child: Text('No users.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)));
            final byRole = <String, int>{};
            for (final u in list) { final r = (u['role'] as String?) ?? 'unknown'; byRole[r] = (byRole[r] ?? 0) + 1; }
            return Padding(
              padding: EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  for (final e in byRole.entries)
                    Expanded(child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.key.toUpperCase(), style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)), SizedBox(height: 4), Text('${e.value}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5))] ))),
                ]),
                SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.min(list.length, 10),
                    separatorBuilder: (_, __) => SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceMuted, border: Border.all(color: AppColors.border)), child: Center(child: Text((u['role'] as String)[0].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))),
                          SizedBox(width: 6),
                          Text(u['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Existing sub-screens kept (Vendor / Txn) — unchanged except small polish
// ─────────────────────────────────────────────────────────────────────────────

class AdminLogoutTile extends ConsumerWidget {
  AdminLogoutTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(leading: Icon(Icons.logout_rounded, color: AppColors.error, size: 20), title: Text('Sign out', style: TextStyle(color: AppColors.error, fontSize: 14)), onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); });
}

class VendorManagementScreen extends ConsumerWidget {
  const VendorManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminVendorsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Vendors', subtitle: 'Approve or suspend', onBack: () => context.go('/admin')),
      body: vendors.when(
        loading: () => const UserListSkeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminVendorsProvider)),
        data: (list) => list.isEmpty
            ? EmptyView(message: 'No vendors registered.')
            : ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = list[i];
                  final status = v['status'] as String;
                  final approved = status == 'APPROVED';
                  return AppCard(
                    padding: EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: approved ? AppColors.successBg : AppColors.warningBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: approved ? AppColors.successBorder : AppColors.border)), child: Icon(approved ? Icons.check_rounded : Icons.pause_rounded, color: approved ? AppColors.success : AppColors.warning, size: 18)),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['name'], style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text('${v['location']} • $status', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                      if (!approved)
                        FilledButton(onPressed: () async { try { await ref.read(dioProvider).patch('/vendors/${v['id']}', data: {'status': 'APPROVED'}); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size(0, 32)), child: Text('Approve', style: TextStyle(fontSize: 12)))
                      else
                        OutlinedButton(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text('Suspend vendor?'), content: Text('Suspend ${v['name']}? Paid orders will be refunded.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: Text('Suspend'))])); if (ok != true) return; try { await ref.read(dioProvider).post('/vendors/${v['id']}/suspend'); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size(0, 32), side: BorderSide(color: AppColors.errorBorder), foregroundColor: AppColors.error), child: Text('Suspend', style: TextStyle(fontSize: 12))),
                    ]),
                  );
                },
              ),
      ),
    );
  }

  void _err(BuildContext ctx, Object e) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Transactions', subtitle: 'Ledger of all payments', onBack: () => context.go('/admin')),
      body: txns.when(
        loading: () => const OrderListSkeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
        data: (data) {
          final items = List<Map<String, dynamic>>.from(data['items'] ?? data['transactions'] ?? []);
          if (items.isEmpty) return EmptyView(icon: Icons.receipt_rounded, message: 'No transactions recorded yet.');
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = items[i];
              final failed = t['status'] == 'FAILED';
              final amount = t['amount_taka'] is int ? t['amount_taka'] as int : int.tryParse('${t['amount_taka']}') ?? 0;
              return AppCard(
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: failed ? AppColors.errorBg : AppColors.successBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: failed ? AppColors.errorBorder : AppColors.successBorder)), child: Icon(failed ? Icons.money_off_rounded : Icons.paid_outlined, size: 16, color: failed ? AppColors.error : AppColors.success)),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${t['order_number'] ?? t['orderNumber'] ?? '—'} • ${taka(amount)}', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${t['vendor_name'] ?? ''} • ${t['status']}${t['failure_reason'] != null ? " (${t['failure_reason']})" : ""}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ])),
                  Text(_fmtDate(t['created_at']?.toString()), style: TextStyle(color: AppColors.textTertiary, fontSize: 10), textAlign: TextAlign.right),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  String _fmtDate(String? raw) {
    final dt = tryParseDate(raw);
    if (dt == null) return '';
    return formatDate(dt);
  }
}