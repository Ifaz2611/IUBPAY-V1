import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});
  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Vendors', subtitle: 'Choose a cafeteria to start ordering', onBack: () => context.go('/student')),
      body: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
            ),
          ]),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: vendors.when(
            loading: () => const LoadingView(message: 'Loading vendors…'),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorListProvider)),
            data: (list) {
              final filtered = _query.isEmpty ? list : list.where((v) => v.name.toLowerCase().contains(_query) || v.location.toLowerCase().contains(_query)).toList();
              if (filtered.isEmpty) {
                return EmptyView(icon: Icons.storefront_rounded, message: _query.isEmpty ? 'No approved vendors yet.' : 'No vendors match “$_query”.');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final v = filtered[i];
                  return AppCard(
                    onTap: () => context.go('/student/vendor/${v.id}'),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.brand, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.place_outlined, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(v.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                        ]),
                        const SizedBox(height: 6),
                        const _OpenChip(),
                      ])),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class VendorMenuScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorMenuScreen({super.key, required this.vendorId});
  @override
  ConsumerState<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends ConsumerState<VendorMenuScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(vendorMenuProvider(widget.vendorId));
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Menu',
        subtitle: cart.isEmpty ? null : '${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'} in cart',
        onBack: () => context.go('/student/vendors'),
        action: !cart.isEmpty
            ? FilledButton.icon(
                onPressed: () => context.go('/student/cart'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                label: Text('${cart.lines.length}'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              )
            : null,
      ),
      body: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(hintText: 'Search dishes', prefixIcon: Icon(Icons.search_rounded, size: 18), isDense: true),
            ),
            const SizedBox(height: 10),
            menu.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                final cats = <String>{'All', ...items.map((e) => e.category)}.toList();
                return SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      final selected = c == _category;
                      return ChoiceChip(
                        label: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.brand : AppColors.textSecondary)),
                        selected: selected,
                        selectedColor: AppColors.brandSubtle,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: selected ? AppColors.brand.withValues(alpha: 0.3) : AppColors.border),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _category = c),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    },
                  ),
                );
              },
            ),
          ]),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: menu.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorMenuProvider(widget.vendorId))),
            data: (items) {
              var filtered = items.where((it) {
                final matchesQuery = _query.isEmpty || it.name.toLowerCase().contains(_query) || (it.description ?? '').toLowerCase().contains(_query);
                final matchesCat = _category == 'All' || it.category == _category;
                return matchesQuery && matchesCat;
              }).toList();
              if (filtered.isEmpty) {
                return const EmptyView(icon: Icons.no_food_rounded, message: 'No items match your search.');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final unavailable = !item.isAvailable;
                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: unavailable ? AppColors.surfaceMuted : AppColors.brandSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border)),
                        child: Icon(Icons.lunch_dining_rounded, size: 24, color: unavailable ? AppColors.textTertiary : AppColors.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(item.name, style: TextStyle(color: unavailable ? AppColors.textTertiary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14, decoration: unavailable ? TextDecoration.lineThrough : null))),
                          if (unavailable)
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                                child: const Text('Unavailable', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 2),
                        PriceText(item.priceTaka, fontSize: 13, color: unavailable ? AppColors.textTertiary : AppColors.textPrimary),
                        if (item.description != null && item.description!.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item.description!,
                                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        Text(item.category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                      ])),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 34,
                        child: unavailable
                            ? const SizedBox.shrink()
                            : OutlinedButton(
                                onPressed: () {
                                  final cart = ref.read(cartProvider);
                                  if (cart.vendorId != null && cart.vendorId != item.vendorId) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Clear your cart to order from a different vendor'), behavior: SnackBarBehavior.floating),
                                    );
                                    return;
                                  }
                                  final added = ref.read(cartProvider.notifier).add(item);
                                  if (!added) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Maximum quantity (20) reached'), behavior: SnackBarBehavior.floating),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} added'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating));
                                },
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14), minimumSize: const Size(0, 34)),
                                child: const Text('Add', style: TextStyle(fontSize: 12)),
                              ),
                      ),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
              child: SafeArea(
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    PriceText(cart.subtotal, fontSize: 16),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryButton(label: 'View cart', icon: Icons.shopping_bag_outlined, onPressed: () => context.go('/student/cart'))),
                ]),
              ),
            ),
    );
  }
}

class _OpenChip extends StatelessWidget {
  const _OpenChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 6, color: AppColors.success),
        SizedBox(width: 6),
        Text('Open', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }
}
