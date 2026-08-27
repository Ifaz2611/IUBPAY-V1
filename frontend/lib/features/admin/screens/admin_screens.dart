import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final adminSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/summary');
  return Map<String, dynamic>.from(r.data);
});
final dailyReportProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/daily?days=14');
  return List<dynamic>.from(r.data);
});
final transactionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/transactions');
  return Map<String, dynamic>.from(r.data);
});
final adminVendorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors?include_all=true');
  return List<dynamic>.from(r.data);
});
final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/users');
  return List<dynamic>.from(r.data);
});

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tiles = [
      (Icons.store_outlined, 'Vendors', 'Approve & manage', '/admin/vendors'),
      (Icons.receipt_long_outlined, 'Transactions', 'Ledger', '/admin/transactions'),
      (Icons.bar_chart_outlined, 'Reports', 'Analytics', '/admin/reports'),
      (Icons.people_outline_rounded, 'Users', 'Directory', '/admin/users'),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)), Text('Control center', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, size: 18), tooltip: 'Sign out', onPressed: () => context.go('/admin/vendors')),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(children: [
          Container(padding: const EdgeInsets.fromLTRB(20, 40, 20, 20), decoration: const BoxDecoration(color: AppColors.surfaceMuted, border: Border(bottom: BorderSide(color: AppColors.border))), child: const Text('Admin panel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16))),
          for (final t in tiles) ListTile(leading: Icon(t.$1, color: AppColors.textSecondary, size: 20), title: Text(t.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)), subtitle: Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)), onTap: () => context.go(t.$4)),
          const Divider(color: AppColors.border, height: 1),
          const AdminLogoutTile(),
        ]),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [for (final t in tiles) AppCard(onTap: () => context.go(t.$4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Icon(t.$1, color: AppColors.textSecondary, size: 22)), const SizedBox(height: 10), Text(t.$2, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)), Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))]))],
      ),
    );
  }
}

class AdminLogoutTile extends ConsumerWidget {
  const AdminLogoutTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20), title: const Text('Sign out', style: TextStyle(color: AppColors.error, fontSize: 14)), onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); });
}

class VendorManagementScreen extends ConsumerWidget {
  const VendorManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminVendorsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Vendors', subtitle: 'Approve or suspend', onBack: () => context.go('/admin')),
      body: vendors.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminVendorsProvider)),
        data: (list) => list.isEmpty
            ? const EmptyView(message: 'No vendors registered.')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = list[i];
                  final status = v['status'] as String;
                  final approved = status == 'APPROVED';
                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: approved ? AppColors.successBg : AppColors.warningBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: approved ? AppColors.successBorder : AppColors.border)), child: Icon(approved ? Icons.check_rounded : Icons.pause_rounded, color: approved ? AppColors.success : AppColors.warning, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['name'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text('${v['location']} • $status', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                      if (!approved)
                        FilledButton(onPressed: () async { try { await ref.read(dioProvider).patch('/vendors/${v['id']}', data: {'status': 'APPROVED'}); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32)), child: const Text('Approve', style: TextStyle(fontSize: 12)))
                      else
                        OutlinedButton(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Suspend vendor?'), content: Text('Suspend ${v['name']}? Paid orders will be refunded.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Suspend'))])); if (ok != true) return; try { await ref.read(dioProvider).post('/vendors/${v['id']}/suspend'); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32), side: const BorderSide(color: AppColors.errorBorder), foregroundColor: AppColors.error), child: const Text('Suspend', style: TextStyle(fontSize: 12))),
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
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Transactions', subtitle: 'Ledger of all payments', onBack: () => context.go('/admin')),
      body: txns.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
        data: (data) {
          final items = List<Map<String, dynamic>>.from(data['items'] ?? data['transactions'] ?? []);
          if (items.isEmpty) return const EmptyView(icon: Icons.receipt_rounded, message: 'No transactions recorded yet.');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = items[i];
              final failed = t['status'] == 'FAILED';
              final amount = t['amount_taka'] is int ? t['amount_taka'] as int : int.tryParse('${t['amount_taka']}') ?? 0;
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: failed ? AppColors.errorBg : AppColors.successBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: failed ? AppColors.errorBorder : AppColors.successBorder)), child: Icon(failed ? Icons.money_off_rounded : Icons.paid_outlined, size: 16, color: failed ? AppColors.error : AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${t['order_number'] ?? t['orderNumber'] ?? '—'} • ${taka(amount)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${t['vendor_name'] ?? ''} • ${t['status']}${t['failure_reason'] != null ? " (${t['failure_reason']})" : ""}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ])),
                  Text(_fmtDate(t['created_at']?.toString()), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10), textAlign: TextAlign.right),
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
