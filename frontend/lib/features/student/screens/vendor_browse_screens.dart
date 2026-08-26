import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorListProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.go('/student')),
                const Text('Vendors', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.neonCyan.withOpacity(0.2))), child: const Row(children: [Icon(Icons.storefront_rounded, size: 14, color: AppColors.neonCyan), SizedBox(width: 6), Text('CANTEENS', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))])),
              ]),
            ),
            Expanded(
              child: vendors.when(
                loading: () => const LoadingView(message: 'Scanning campus…'),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorListProvider)),
                data: (list) => list.isEmpty
                    ? const EmptyView(icon: Icons.storefront_rounded, message: 'No approved vendors yet.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final v = list[i];
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            onTap: () => context.go('/student/vendor/${v.id}'),
                            child: Row(children: [
                              Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 26)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(v.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 3),
                                Row(children: [const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textTertiary), const SizedBox(width: 4), Expanded(child: Text(v.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)))]),
                                const SizedBox(height: 6),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('OPEN • READY', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                              ])),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
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

class VendorMenuScreen extends ConsumerWidget {
  final String vendorId;
  const VendorMenuScreen({super.key, required this.vendorId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(vendorMenuProvider(vendorId));
    final cart = ref.watch(cartProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.go('/student/vendors')),
                const Text('Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (!cart.isEmpty)
                  GestureDetector(
                    onTap: () => context.go('/student/cart'),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 12)]), child: Row(children: [const Icon(Icons.shopping_bag_rounded, size: 16, color: Colors.white), const SizedBox(width: 6), Text('${cart.lines.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))])),
                  ),
              ]),
            ),
            Expanded(
              child: menu.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorMenuProvider(vendorId))),
                data: (items) => items.isEmpty
                    ? const EmptyView(icon: Icons.no_food_rounded, message: 'No items available right now.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(width: 64, height: 64, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.neonAmber.withOpacity(0.25), AppColors.neonPink.withOpacity(0.15)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))), child: const Icon(Icons.lunch_dining_rounded, size: 30, color: Colors.white)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                const SizedBox(height: 4),
                                PriceText(item.priceTaka, fontSize: 14),
                                if (item.description != null && item.description!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.description!, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              ])),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => ref.read(cartProvider.notifier).add(item),
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.25), blurRadius: 10)]), child: const Row(children: [Icon(Icons.add_rounded, size: 16, color: Colors.white), SizedBox(width: 4), Text('ADD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))])),
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
      floatingActionButton: cart.isEmpty ? null : null,
    );
  }
}
