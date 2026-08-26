import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import 'vendor_screens.dart' show myVendorMenuProvider, myVendorOrdersProvider;

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(myVendorMenuProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Text('Manage Menu',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showEditor(context, ref, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration:
                        BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('ADD ITEM',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: menu.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorMenuProvider)),
                data: (items) => items.isEmpty
                    ? const EmptyView(icon: Icons.no_meals_rounded, message: 'No items yet. Add your first menu item.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: it.isAvailable
                                      ? AppColors.neonGreen.withOpacity(0.14)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  it.isAvailable ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  size: 18,
                                  color: it.isAvailable ? AppColors.neonGreen : AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(it.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        decoration: it.isAvailable ? null : TextDecoration.lineThrough,
                                        decorationColor: Colors.white54,
                                      )),
                                  Text('${it.category} • ৳${it.priceTaka}',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                ]),
                              ),
                              Switch(
                                value: it.isAvailable,
                                activeThumbColor: AppColors.neonCyan,
                                onChanged: (_) async {
                                  try {
                                    await ref.read(dioProvider).patch('/menu-items/${it.id}',
                                        data: {'is_available': !it.isAvailable});
                                    ref.invalidate(myVendorMenuProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
                                onPressed: () => _showEditor(context, ref, it),
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

  void _showEditor(BuildContext context, WidgetRef ref, MenuItem? existing) {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(text: existing == null ? '' : '${existing.priceTaka}');
    final desc = TextEditingController(text: existing?.description ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgMid,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(existing == null ? 'Add menu item' : 'Edit item',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.fastfood_rounded))),
          const SizedBox(height: 10),
          TextField(
              controller: price,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Price (৳)', prefixIcon: Icon(Icons.payments_rounded))),
          const SizedBox(height: 10),
          TextField(
              controller: desc,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'SAVE',
              icon: Icons.check_rounded,
              onPressed: () async {
                final trimmedName = name.text.trim();
                if (trimmedName.length < 2) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Name must be at least 2 characters')));
                  return;
                }
                int? parsedPrice;
                if (existing == null) {
                  // Creation requires a valid price.
                  parsedPrice = int.tryParse(price.text.trim());
                  if (parsedPrice == null || parsedPrice < 1 || parsedPrice > 100000) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Enter a valid price (1–100000)')));
                    return;
                  }
                } else if (price.text.trim().isNotEmpty) {
                  parsedPrice = int.tryParse(price.text.trim());
                  if (parsedPrice == null || parsedPrice < 1 || parsedPrice > 100000) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Enter a valid price (1–100000)')));
                    return;
                  }
                }
                final dio = ref.read(dioProvider);
                final body = <String, dynamic>{
                  'name': trimmedName,
                  if (parsedPrice != null) 'price_taka': parsedPrice,
                  if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
                };
                try {
                  if (existing == null) {
                    final vendorId = ref.read(authProvider).valueOrNull?.vendorId;
                    final resolvedVendorId = vendorId ??
                        (await dio.get('/auth/me')).data['vendor_id'] as String?;
                    if (resolvedVendorId == null) {
                      throw Exception('No vendor linked to this account');
                    }
                    await dio.post('/vendors/$resolvedVendorId/menu-items', data: body);
                  } else {
                    await dio.patch('/menu-items/${existing.id}', data: body);
                  }
                  ref.invalidate(myVendorMenuProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
                  }
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class SalesSummaryScreen extends ConsumerWidget {
  const SalesSummaryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myVendorOrdersProvider);
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
                const Text('Sales Summary',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
            ),
            Expanded(
              child: orders.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorOrdersProvider)),
                data: (list) {
                  final collected = list.where((o) => o.status == 'COLLECTED').toList();
                  final live = list.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status));
                  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                  final todayCollected =
                      collected.where((o) => o.createdAt != null && o.createdAt!.toIso8601String().substring(0, 10) == todayStr);
                  int sum(Iterable<Order> os) => os.fold(0, (s, o) => s + o.totalAmount);
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    _statCard('Today (collected)', '${todayCollected.length} orders', '৳${sum(todayCollected)}',
                        AppColors.neonCyan),
                    _statCard(
                        'All-time (collected)', '${collected.length} orders', '৳${sum(collected)}', AppColors.neonPurple),
                    _statCard('Live orders now', '${live.length} in progress', '৳${sum(live)}', AppColors.neonPink),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String title, String sub, String amount, Color c) => GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c, c.withOpacity(0.2)]),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.trending_up_rounded, color: c, size: 20),
          ),
        ]),
      );
}
