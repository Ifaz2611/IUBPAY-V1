import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Menu',
        subtitle: 'Add, edit, and toggle availability',
        onBack: () => context.go('/vendor'),
        action: FilledButton.icon(
          onPressed: () => _showEditor(context, ref, null),
          icon: Icon(Icons.add_rounded, size: 16),
          label: const Text('Add item', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32)),
        ),
      ),
      body: menu.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorMenuProvider)),
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.no_meals_rounded, message: 'No items yet. Add your first menu item.')
            : ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = items[i];
                  return AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Icon(it.isAvailable ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: it.isAvailable ? AppColors.success : AppColors.textTertiary),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.name, style: TextStyle(color: it.isAvailable ? AppColors.textPrimary : AppColors.textTertiary, fontWeight: FontWeight.w600, decoration: it.isAvailable ? null : TextDecoration.lineThrough)),
                        Text('${it.category} • ${taka(it.priceTaka)}', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      ])),
                      Switch(value: it.isAvailable, activeThumbColor: AppColors.brand, onChanged: (_) async {
                        try { await ref.read(dioProvider).patch('/menu-items/${it.id}', data: {'is_available': !it.isAvailable}); ref.invalidate(myVendorMenuProvider); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)))); }
                      }),
                      IconButton(icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary), onPressed: () => _showEditor(context, ref, it), tooltip: 'Edit'),
                    ]),
                  );
                },
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Text(existing == null ? 'Add menu item' : 'Edit item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.fastfood_rounded, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (৳)', prefixIcon: Icon(Icons.payments_outlined, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded, size: 18))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onPressed: () async {
                final trimmedName = name.text.trim();
                if (trimmedName.length < 2) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Name must be at least 2 characters'))); return; }
                int? parsedPrice;
                if (existing == null) {
                  parsedPrice = int.tryParse(price.text.trim());
                  if (parsedPrice == null || parsedPrice < 1 || parsedPrice > 100000) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid price (1–100000)'))); return; }
                } else if (price.text.trim().isNotEmpty) {
                  parsedPrice = int.tryParse(price.text.trim());
                  if (parsedPrice == null || parsedPrice < 1 || parsedPrice > 100000) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid price (1–100000)'))); return; }
                }
                final dio = ref.read(dioProvider);
                final body = <String, dynamic>{'name': trimmedName, if (parsedPrice != null) 'price_taka': parsedPrice, if (desc.text.trim().isNotEmpty) 'description': desc.text.trim()};
                try {
                  if (existing == null) {
                    final vendorId = ref.read(authProvider).value?.vendorId;
                    final resolvedVendorId = vendorId ?? (await dio.get('/auth/me')).data['vendor_id'] as String?;
                    if (resolvedVendorId == null) throw Exception('No vendor linked to this account');
                    await dio.post('/vendors/$resolvedVendorId/menu-items', data: body);
                  } else {
                    await dio.patch('/menu-items/${existing.id}', data: body);
                  }
                  ref.invalidate(myVendorMenuProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(apiErrorMessage(e)))); }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: 'Sales', subtitle: 'Collected and live totals', onBack: () => context.go('/vendor')),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myVendorOrdersProvider)),
        data: (list) {
          final collected = list.where((o) => o.status == 'COLLECTED').toList();
          final live = list.where((o) => ['PAID', 'ACCEPTED', 'PREPARING', 'READY'].contains(o.status));
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final todayCollected = collected.where((o) => o.createdAt != null && o.createdAt!.toIso8601String().substring(0, 10) == todayStr);
          int sum(Iterable<Order> os) => os.fold(0, (s, o) => s + o.totalAmount);
          return ListView(padding: EdgeInsets.all(16), children: [
            _statCard('Today (collected)', '${todayCollected.length} orders', taka(sum(todayCollected))),
            _statCard('All-time (collected)', '${collected.length} orders', taka(sum(collected))),
            _statCard('Live orders now', '${live.length} in progress', taka(sum(live))),
          ]);
        },
      ),
    );
  }

  Widget _statCard(String title, String sub, String amount) => AppCard(
        margin: EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 3, height: 48, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(2))),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
            SizedBox(height: 4),
            Text(amount, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            Text(sub, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.trending_up_rounded, color: AppColors.brand, size: 18)),
        ]),
      );
}