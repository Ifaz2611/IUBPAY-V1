import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

/// Vendor list + vendor menu + item detail (kept in one file; each is small).
class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cafeterias & Vendors')),
      body: vendors.when(
        loading: () => const LoadingView(message: 'Loading vendors…'),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorListProvider)),
        data: (list) => list.isEmpty
            ? const EmptyView(icon: Icons.storefront,
                message: 'No approved vendors yet.')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final v = list[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                      title: Text(v.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(v.location),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/student/vendor/${v.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class VendorMenuScreen extends ConsumerWidget {
  final String vendorId;
  const VendorMenuScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(vendorMenuProvider(vendorId));
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart · ${cart.lines.length} items'),
              onPressed: () => context.go('/student/cart'),
            ),
      body: menu.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorMenuProvider(vendorId))),
        data: (items) => items.isEmpty
            ? const EmptyView(icon: Icons.no_food, message: 'No items available right now.')
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.lunch_dining, size: 30),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [PriceText(item.priceTaka)]),
                      trailing: FilledButton.tonal(
                        child: const Text('Add'),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).add(item),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
