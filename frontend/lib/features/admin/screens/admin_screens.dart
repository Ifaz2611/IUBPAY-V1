import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
      (Icons.store_rounded, 'Vendors', 'Manage', '/admin/vendors', [AppColors.neonCyan, const Color(0xFF06B6D4)]),
      (Icons.receipt_long_rounded, 'Transactions', 'Ledger', '/admin/transactions', [AppColors.neonPurple, const Color(0xFF8B5CF6)]),
      (Icons.bar_chart_rounded, 'Reports', 'Analytics', '/admin/reports', [AppColors.neonPink, const Color(0xFFF43F5E)]),
      (Icons.people_rounded, 'Users', 'Directory', '/admin/users', [const Color(0xFF10B981), const Color(0xFF06B6D4)]),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Row(children: [
              Container(width: 42, height: 42, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ADMIN COMMAND', style: TextStyle(color: AppColors.neonRed, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)), Text('Control Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))])),
              GestureDetector(onTap: () => context.go('/admin/vendors'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: const Text('v0.1 • PROTOTYPE', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700)))),
            ])),
            Expanded(child: GridView.count(padding: const EdgeInsets.all(16), crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [for (final t in tiles) GlassCard(onTap: () => context.go(t.$4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(colors: t.$5), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: t.$5.first.withOpacity(0.3), blurRadius: 14)]), child: Icon(t.$1, color: Colors.white, size: 28)), const SizedBox(height: 10), Text(t.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)), Text(t.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))]))])),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: GlassCard(child: Row(children: [const Icon(Icons.logout_rounded, size: 16, color: AppColors.neonRed), const SizedBox(width: 8), const Text('Logout', style: TextStyle(color: AppColors.neonRed, fontWeight: FontWeight.w700)), const Spacer(), Consumer(builder: (_, ref, __) => GestureDetector(onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Text('EXIT', style: TextStyle(color: AppColors.neonRed, fontSize: 11, fontWeight: FontWeight.w900)))))]))),
          ]),
        ),
      ),
      drawer: Drawer(backgroundColor: AppColors.bgMid, child: Container(decoration: const BoxDecoration(gradient: AppColors.bgGradient), child: ListView(children: [
        Container(padding: const EdgeInsets.fromLTRB(20, 40, 20, 20), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.neonRed.withOpacity(0.15), Colors.transparent])), child: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
        for (final t in tiles) ListTile(leading: Icon(t.$1, color: t.$5.first), title: Text(t.$2, style: const TextStyle(color: Colors.white)), onTap: () => context.go(t.$4)),
        const Divider(color: AppColors.divider), const AdminLogoutTile(),
      ]))),
    );
  }
}

class AdminLogoutTile extends ConsumerWidget {
  const AdminLogoutTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(leading: const Icon(Icons.logout_rounded, color: AppColors.neonRed), title: const Text('Logout', style: TextStyle(color: AppColors.neonRed)), onTap: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); });
}

class VendorManagementScreen extends ConsumerWidget {
  const VendorManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminVendorsProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/admin')), const Text('Vendors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))])),
            Expanded(child: vendors.when(loading: () => const LoadingView(), error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminVendorsProvider)), data: (list) => list.isEmpty ? const EmptyView(message: 'No vendors registered.') : ListView.builder(padding: const EdgeInsets.all(14), itemCount: list.length, itemBuilder: (_, i) {final v = list[i]; final status = v['status']; final approved = status == 'APPROVED'; return GlassCard(margin: const EdgeInsets.only(bottom: 10), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: approved ? AppColors.neonGreen.withOpacity(0.14) : AppColors.neonAmber.withOpacity(0.14)), child: Icon(approved ? Icons.check_rounded : Icons.pause_rounded, color: approved ? AppColors.neonGreen : AppColors.neonAmber, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text('${v['location']} • $status', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))])), if (!approved) GestureDetector(onTap: () async { try { await ref.read(dioProvider).patch('/vendors/${v['id']}', data: {'status': 'APPROVED'}); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.14), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.neonGreen.withOpacity(0.25))), child: const Text('APPROVE', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 11)))), if (approved) ...[const SizedBox(width: 8), GestureDetector(onTap: () async { try { await ref.read(dioProvider).post('/vendors/${v['id']}/suspend'); ref.invalidate(adminVendorsProvider); } catch (e) { if (context.mounted) _err(context, e); } }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.neonRed.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.block_rounded, size: 14, color: AppColors.neonRed), SizedBox(width: 4), Text('SUSPEND', style: TextStyle(color: AppColors.neonRed, fontSize: 11, fontWeight: FontWeight.w800))])))] ]));}))),
          ]),
        ),
      ),
    );
  }
  void _err(BuildContext ctx, Object e) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)), backgroundColor: AppColors.bgCard));
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/admin')), const Text('Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))])),
            Expanded(child: txns.when(loading: () => const LoadingView(), error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(transactionsProvider)), data: (data) {final items = List<Map<String, dynamic>>.from(data['items']); if (items.isEmpty) return const EmptyView(icon: Icons.receipt_rounded, message: 'No transactions recorded yet.'); return ListView.builder(padding: const EdgeInsets.all(14), itemCount: items.length, itemBuilder: (_, i) {final t = items[i]; final failed = t['status'] == 'FAILED'; return GlassCard(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: failed ? AppColors.neonRed.withOpacity(0.12) : AppColors.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(failed ? Icons.money_off_rounded : Icons.paid_rounded, size: 18, color: failed ? AppColors.neonRed : AppColors.neonGreen)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${t['order_number']} • ৳${t['amount_taka']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)), Text('${t['vendor_name']} • ${t['status']}${t['failure_reason'] != null ? " (${t['failure_reason']})" : ""}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11))] )), Text((t['created_at']?.toString() ?? '').replaceFirst('T', '\n').split('.').first, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10), textAlign: TextAlign.right)]));} );})),
          ]),
        ),
      ),
    );
  }
}
