import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../shared/api/api_client.dart';
import 'admin_screens.dart' show adminSummaryProvider, dailyReportProvider, adminUsersProvider;

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final daily = ref.watch(dailyReportProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Reports', subtitle: 'Sales and revenue', onBack: () => context.go('/admin')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        summary.when(
          loading: () => const KpiGridSkeleton(count: 6, crossAxisCount: 2),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminSummaryProvider)),
          data: (s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              _card('Total sales', taka(s['total_sales_taka'] as int)),
              _card('Paid orders', '${s['paid_orders']}'),
              _card('Total orders', '${s['total_orders']}'),
              _card('Refunds', '-${taka(s['total_refunds_taka'] as int)}'),
              _card('Net revenue', taka(s['net_revenue_taka'] as int), big: true),
              _card('Failed', '${s['failed_payments']}', highlight: (s['failed_payments'] as int) > 0),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioProvider);
                    final r = await dio.get('/admin/reports/export.csv');
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported (${r.data.toString().length} bytes)')));
                  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)))); }
                },
                icon: Icon(Icons.download_outlined, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: 'Daily sales', subtitle: 'Last 14 days'),
        SizedBox(height: 10),
        daily.when(
          loading: () => const ListSkeleton(count: 6),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(dailyReportProvider)),
          data: (rows) {
            final maxSales = rows.fold<int>(1, (m, r) => m > (r['sales_taka'] as int) ? m : r['sales_taka'] as int);
            return AppCard(
              child: Column(children: [
                for (final r in rows.reversed)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 56, child: Text((r['date'] as String).substring(5), style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500))),
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: maxSales == 0 ? 0 : (r['sales_taka'] as int) / maxSales, minHeight: 10, backgroundColor: AppColors.surfaceMuted, valueColor: AlwaysStoppedAnimation(AppColors.brand)))),
                      SizedBox(width: 8),
                      SizedBox(width: 64, child: Text(taka(r['sales_taka'] as int), textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                    ]),
                  ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _card(String label, String value, {bool highlight = false, bool big = false}) => Container(
        width: 160,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: highlight ? AppColors.errorBg : AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: highlight ? AppColors.errorBorder : AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text(value, style: TextStyle(color: highlight ? AppColors.error : AppColors.textPrimary, fontSize: big ? 18 : 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        ]),
      );
}

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Users', subtitle: 'Directory', onBack: () => context.go('/admin')),
      body: users.when(
        loading: () => const UserListSkeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (list) => list.isEmpty
            ? EmptyView(message: 'No users.')
            : ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = list[i];
                  final isActive = u['status'] == 'ACTIVE';
                  return AppCard(
                    padding: EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceMuted, border: Border.all(color: AppColors.border)), child: Center(child: Text((u['role'] as String)[0].toUpperCase(), style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)))),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'], style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text('${u['email']} • ${u['role']}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))])),
                      Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isActive ? AppColors.successBg : AppColors.errorBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: isActive ? AppColors.successBorder : AppColors.errorBorder)), child: Text(u['status'], style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w700))),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}