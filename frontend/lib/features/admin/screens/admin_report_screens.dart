import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import 'admin_screens.dart'
    show adminSummaryProvider, dailyReportProvider, adminUsersProvider;

/// Reports: summary cards + simple daily bars (last 14 days).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider);
    final daily = ref.watch(dailyReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        summary.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e,
              onRetry: () => ref.invalidate(adminSummaryProvider)),
          data: (s) => Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _card('Total sales', '৳${s['total_sales_taka']}'),
                  _card('Paid orders', '${s['paid_orders']}'),
                  _card('Total orders', '${s['total_orders']}'),
                  _card('Refunds', '-৳${s['total_refunds_taka']}'),
                  _card('Net revenue', '৳${s['net_revenue_taka']}'),
                  _card('Failed payments', '${s['failed_payments']}',
                      highlight: s['failed_payments'] > 0),
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export transactions as CSV'),
                    onPressed: () async {
                      try {
                        final dio = ref.read(dioProvider);
                        final r = await dio.get('/admin/reports/export.csv');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'CSV exported (${r.data.toString().length} bytes). '
                                  'In production this downloads a file.')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(apiErrorMessage(e))));
                        }
                      }
                    }),
              ]),
        ),
        const SizedBox(height: 22),
        Text('Daily sales — last 14 days',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        daily.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e,
              onRetry: () => ref.invalidate(dailyReportProvider)),
          data: (rows) {
            final maxSales = rows.fold<int>(1,
                (m, r) => m > (r['sales_taka'] as int) ? m : r['sales_taka'] as int);
            return Column(
              children: [
                for (final r in rows.reversed)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                    SizedBox(width: 84,
                        child: Text((r['date'] as String).substring(5),
                            style: const TextStyle(fontSize: 12))),
                    Expanded(child:
                        LinearProgressIndicator(
                            value: maxSales == 0 ? 0 :
                                (r['sales_taka'] as int) / maxSales,
                            minHeight: 16)),
                    const SizedBox(width: 8),
                    SizedBox(width: 60,
                        child: Text('৳${r['sales_taka']}',
                            style: const TextStyle(fontSize: 12))),
                  ])),
              ],
            );
          },
        ),
      ]),
    );
  }

  Widget _card(String label, String value, {bool highlight = false}) =>
      Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: highlight ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 19,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

// ---------------- user management ----------------

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (list) => list.isEmpty
            ? const EmptyView(message: 'No users.')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final u = list[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(u['role'][0].toUpperCase())),
                    title: Text(u['name']),
                    subtitle: Text('${u['email']} · ${u['role']}'),
                    trailing: Text(u['status'],
                        style: TextStyle(color: u['status'] == 'ACTIVE'
                            ? Colors.green : Colors.red)),
                  );
                }),
      ),
    );
  }
}
