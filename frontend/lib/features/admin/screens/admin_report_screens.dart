import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import 'admin_screens.dart' show adminSummaryProvider, dailyReportProvider, adminUsersProvider;

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final daily = ref.watch(dailyReportProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Text('Reports',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const SizedBox(height: 8),
            summary.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminSummaryProvider)),
              data: (s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 10, runSpacing: 10, children: [
                  _card('Total sales', '৳${s['total_sales_taka']}', AppColors.neonCyan),
                  _card('Paid orders', '${s['paid_orders']}', AppColors.neonPurple),
                  _card('Total orders', '${s['total_orders']}', AppColors.neonPink),
                  _card('Refunds', '-৳${s['total_refunds_taka']}', AppColors.neonAmber),
                  _card('Net revenue', '৳${s['net_revenue_taka']}', AppColors.neonGreen, big: true),
                  _card('Failed', '${s['failed_payments']}', AppColors.neonRed,
                      highlight: (s['failed_payments'] as int) > 0),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    try {
                      final dio = ref.read(dioProvider);
                      final r = await dio.get('/admin/reports/export.csv');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('CSV exported (${r.data.toString().length} bytes)'),
                          backgroundColor: AppColors.bgCard,
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(apiErrorMessage(e)),
                          backgroundColor: AppColors.bgCard,
                        ));
                      }
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.download_rounded, size: 18, color: AppColors.neonCyan),
                      SizedBox(width: 8),
                      Text('Export CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Daily sales', subtitle: 'Last 14 days'),
            const SizedBox(height: 10),
            daily.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(dailyReportProvider)),
              data: (rows) {
                final maxSales = rows.fold<int>(1, (m, r) => m > (r['sales_taka'] as int) ? m : r['sales_taka'] as int);
                return GlassCard(
                  child: Column(children: [
                    for (final r in rows.reversed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          SizedBox(
                            width: 56,
                            child: Text((r['date'] as String).substring(5),
                                style: const TextStyle(
                                    color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: maxSales == 0 ? 0 : (r['sales_taka'] as int) / maxSales,
                                minHeight: 14,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                valueColor: const AlwaysStoppedAnimation(AppColors.neonCyan),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 56,
                            child: Text('৳${r['sales_taka']}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                  ]),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _card(String label, String value, Color c, {bool highlight = false, bool big = false}) => Container(
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [c.withOpacity(highlight ? 0.18 : 0.10), c.withOpacity(0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.22)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: Colors.white, fontSize: big ? 20 : 18, fontWeight: FontWeight.w900)),
        ]),
      );
}

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Text('Users',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
            ),
            Expanded(
              child: users.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminUsersProvider)),
                data: (list) => list.isEmpty
                    ? const EmptyView(message: 'No users.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final u = list[i];
                          final isActive = u['status'] == 'ACTIVE';
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    AppColors.neonPurple.withOpacity(0.3),
                                    AppColors.neonCyan.withOpacity(0.3),
                                  ]),
                                ),
                                child: Center(
                                  child: Text(u['role'][0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(u['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text('${u['email']} • ${u['role']}',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                ]),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.neonGreen.withOpacity(0.12)
                                      : AppColors.neonRed.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(u['status'],
                                    style: TextStyle(
                                        color: isActive ? AppColors.neonGreen : AppColors.neonRed,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ]),
                          );
                        },
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
