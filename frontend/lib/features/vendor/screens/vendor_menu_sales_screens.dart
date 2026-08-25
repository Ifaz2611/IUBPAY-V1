import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';
import 'vendor_screens.dart' show myVendorMenuProvider;

/// Add / edit / disable menu items for the logged-in vendor.
class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(myVendorMenuProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Menu')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: () => _showEditor(context, ref, null),
      ),
      body: menu.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myVendorMenuProvider)),
        data: (items) => items.isEmpty
            ? const EmptyView(icon: Icons.no_meals,
                message: 'No items yet. Add your first menu item.')
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(it.isAvailable
                          ? Icons.visibility : Icons.visibility_off,
                          color: it.isAvailable ? Colors.green : Colors.grey),
                      title: Text(it.name,
                          style: TextStyle(
                              decoration: it.isAvailable
                                  ? null : TextDecoration.lineThrough)),
                      subtitle: Text('${it.category} · ৳${it.priceTaka}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(
                            value: it.isAvailable,
                            onChanged: (_) async {
                              try {
                                await ref.read(dioProvider).patch(
                                    '/menu-items/${it.id}',
                                    data: {'is_available': !it.isAvailable});
                                ref.invalidate(myVendorMenuProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content:
                                          Text(apiErrorMessage(e))));
                                }
                              }
                            }),
                        IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditor(context, ref, it)),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, MenuItem? existing) {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
        text: existing == null ? '' : '${existing.priceTaka}');
    final desc = TextEditingController(text: existing?.description ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add menu item' : 'Edit item',
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextField(controller: name,
              decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(controller: price,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Price (৳, whole taka)')),
          const SizedBox(height: 10),
          TextField(controller: desc,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              final body = <String, dynamic>{
                'name': name.text.trim(),
                if (price.text.isNotEmpty)
                  'price_taka': int.tryParse(price.text.trim()),
                if (desc.text.isNotEmpty) 'description': desc.text.trim(),
              };
              try {
                if (existing == null) {
                  // vendor id resolved server-side via /vendors/me/menu pattern
                  final me = await dio.get('/auth/me');
                  final vendorId = me.data['vendor_id'];
                  await dio.post('/vendors/$vendorId/menu-items',
                      data: {...body, if (body['price_taka'] == null)
                          'price_taka': 1});
                } else {
                  await dio.patch('/menu-items/${existing.id}', data: body);
                }
                ref.invalidate(myVendorMenuProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(apiErrorMessage(e))));
                }
              }
            },
            child: const Text('Save'),
          ),
        ]),
      ),
    );
  }
}

// ---------------- daily sales summary ----------------

class SalesSummaryScreen extends ConsumerWidget {
  const SalesSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myVendorOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Summary')),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myVendorOrdersProvider)),
        data: (list) {
          final collected = list.where((o) => o.status == 'COLLECTED').toList();
          final live = list.where((o) =>
              ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status));
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final todayCollected = collected.where((o) =>
              o.createdAt != null &&
              o.createdAt!.toIso8601String().substring(0, 10) == todayStr);
          int sum(Iterable<Order> os) =>
              os.fold(0, (s, o) => s + o.totalAmount);

          return ListView(padding: const EdgeInsets.all(16), children: [
            _statCard(context, 'Today (collected)',
                '${todayCollected.length} orders', '৳${sum(todayCollected)}'),
            _statCard(context, 'All-time (collected)',
                '${collected.length} orders', '৳${sum(collected)}'),
            _statCard(context, 'Live orders now',
                '${live.length} in progress', '৳${sum(live)}'),
          ]);
        },
      ),
    );
  }

  Widget _statCard(BuildContext ctx, String title, String sub, String amount) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(amount,
                style: Theme.of(ctx)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(sub),
          ]),
        ),
      );
}
