import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------- providers ----------------

final adminSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/summary');
  return Map<String, dynamic>.from(r.data);
});

final dailyReportProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/daily?days=14');
  return List<dynamic>.from(r.data);
});

final transactionsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
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

// ---------------- dashboard ----------------

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    final tiles = [
      (Icons.store, 'Vendor Management', '/admin/vendors'),
      (Icons.receipt_long, 'Transactions', '/admin/transactions'),
      (Icons.bar_chart, 'Reports', '/admin/reports'),
      (Icons.people, 'Users', '/admin/users'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('IUB Cafeteria — Admin')),
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1B3A6B)),
              child: Text('Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 22))),
          for (final t in tiles)
            ListTile(leading: Icon(t.$1), title: Text(t.$2),
                onTap: () => context.go(t.$3)),
          const AdminLogoutTile(),
        ]),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: wide ? 4 : 2,
        children: [
          for (final t in tiles)
            Card(
              child: InkWell(borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(t.$3),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.$1, size: 46, color: const Color(0xFF1B3A6B)),
                      const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(t.$2, textAlign: TextAlign.center)),
                    ])),
            ),
        ],
      ),
    );
  }
}

class AdminLogoutTile extends ConsumerWidget {
  const AdminLogoutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      );
}

// ---------------- vendor management ----------------

class VendorManagementScreen extends ConsumerWidget {
  const VendorManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminVendorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Management')),
      body: vendors.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(adminVendorsProvider)),
        data: (list) => list.isEmpty
            ? const EmptyView(message: 'No vendors registered.')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final v = list[i];
                  final status = v['status'];
                  final approved = status == 'APPROVED';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: approved
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(approved ? Icons.check : Icons.pause,
                              color: approved ? Colors.green : Colors.orange)),
                      title: Text(v['name'],
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${v['location']} · $status'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (!approved)
                          FilledButton.tonal(
                            child: const Text('Approve'),
                            onPressed: () async {
                              try {
                                await ref.read(dioProvider).patch(
                                    '/vendors/${v['id']}',
                                    data: {'status': 'APPROVED'});
                                ref.invalidate(adminVendorsProvider);
                              } catch (e) {
                                if (context.mounted) _err(context, e);
                              }
                            },
                          ),
                        if (approved) ...[
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                                foregroundColor: Colors.red),
                            icon: const Icon(Icons.block),
                            label: const Text('Suspend'),
                            onPressed: () async {
                              try {
                                await ref.read(dioProvider)
                                    .post('/vendors/${v['id']}/suspend');
                                ref.invalidate(adminVendorsProvider);
                              } catch (e) {
                                if (context.mounted) _err(context, e);
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                  );
                }),
      ),
    );
  }

  void _err(BuildContext ctx, Object e) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))));
}

// ---------------- transactions ----------------

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: txns.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
        data: (data) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          if (items.isEmpty) {
            return const EmptyView(icon: Icons.receipt,
                message: 'No transactions recorded yet.');
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              final failed = t['status'] == 'FAILED';
              return ListTile(
                leading: Icon(failed ? Icons.money_off : Icons.paid,
                    color: failed ? Colors.red : Colors.green),
                title: Text('${t['order_number']} · ৳${t['amount_taka']}'),
                subtitle: Text(
                    '${t['vendor_name']} · ${t['status']}'
                    '${t['failure_reason'] != null ? " (${t['failure_reason']})" : ""}'),
                trailing: Text((t['created_at']?.toString() ?? '')
                        .replaceFirst('T', '\n')
                        .split('.').first),
              );
            },
          );
        },
      ),
    );
  }
}
