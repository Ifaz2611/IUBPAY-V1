import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

// ─── Vendor List ─────────────────────────────────────────────
class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});
  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _query = '';
  bool _favoritesOnly = false;
  bool _gridMode = false;
  final Set<String> _favs = {};

  double _mockRating(String id) {
    // deterministic pseudo-rating 4.2-4.9
    final h = id.hashCode.abs() % 7;
    return 4.2 + h * 0.1;
  }

  String _mockTime(String id) => '${15 + (id.hashCode.abs() % 3) * 5}–${20 + (id.hashCode.abs() % 3) * 5} min';

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Vendors',
        subtitle: 'Choose a cafeteria to start ordering',
        onBack: () => context.go('/student'),
        action: Row(children: [
          IconButton(
            icon: Icon(_gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 18),
            tooltip: _gridMode ? 'List view' : 'Grid view',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _gridMode = !_gridMode);
            },
          ),
        ]),
      ),
      body: Column(children: [
        // Search + filters
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _query = ''))
                    : null,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              FilterChip(
                label: Row(children: [
                  Icon(_favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: _favoritesOnly ? Colors.white : AppColors.error),
                  const SizedBox(width: 6),
                  Text('Favorites', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _favoritesOnly ? Colors.white : AppColors.textSecondary)),
                ]),
                selected: _favoritesOnly,
                selectedColor: AppColors.error,
                backgroundColor: AppColors.surface,
                side: BorderSide(color: _favoritesOnly ? AppColors.error : AppColors.border),
                showCheckmark: false,
                onSelected: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _favoritesOnly = v);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('${_favs.length} saved', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.invalidate(vendorListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
              ),
            ]),
          ]),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: vendors.when(
            loading: () => const LoadingView(message: 'Loading vendors…'),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(vendorListProvider)),
            data: (list) {
              var filtered = _query.isEmpty ? list : list.where((v) => v.name.toLowerCase().contains(_query) || v.location.toLowerCase().contains(_query)).toList();
              if (_favoritesOnly) filtered = filtered.where((v) => _favs.contains(v.id)).toList();
              if (filtered.isEmpty) {
                return EmptyView(
                  icon: _favoritesOnly ? Icons.favorite_border_rounded : Icons.storefront_rounded,
                  message: _favoritesOnly
                      ? 'No favorites yet. Tap ♡ on a vendor to save it.'
                      : _query.isEmpty
                          ? 'No approved vendors yet.'
                          : 'No vendors match “$_query”.',
                );
              }
              if (_gridMode) {
                return RefreshIndicator(
                  color: AppColors.brand,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async => ref.invalidate(vendorListProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _VendorGridCard(
                      vendor: filtered[i],
                      rating: _mockRating(filtered[i].id),
                      eta: _mockTime(filtered[i].id),
                      isFav: _favs.contains(filtered[i].id),
                      onFav: () {
                        HapticFeedback.selectionClick();
                        setState(() => _favs.contains(filtered[i].id) ? _favs.remove(filtered[i].id) : _favs.add(filtered[i].id));
                      },
                      onTap: () => context.go('/student/vendor/${filtered[i].id}'),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.brand,
                backgroundColor: AppColors.surface,
                onRefresh: () async => ref.invalidate(vendorListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final v = filtered[i];
                    final isFav = _favs.contains(v.id);
                    return AppCard(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go('/student/vendor/${v.id}');
                      },
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Stack(children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.restaurant_rounded, color: AppColors.brand, size: 24),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                              child: const Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(v.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => isFav ? _favs.remove(v.id) : _favs.add(v.id));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: isFav ? AppColors.errorBg : AppColors.surfaceMuted, shape: BoxShape.circle, border: Border.all(color: isFav ? AppColors.errorBorder : AppColors.border)),
                                child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: isFav ? AppColors.error : AppColors.textTertiary),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.place_outlined, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(v.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const _OpenChip(),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                              child: Row(children: [
                                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 3),
                                Text(_mockRating(v.id).toStringAsFixed(1), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                              child: Row(children: [
                                const Icon(Icons.timer_outlined, size: 11, color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text(_mockTime(v.id), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ]),
                          if (v.description != null && v.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(v.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          ],
                        ])),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                      ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _VendorGridCard extends StatelessWidget {
  final dynamic vendor;
  final double rating;
  final String eta;
  final bool isFav;
  final VoidCallback onFav;
  final VoidCallback onTap;
  const _VendorGridCard({required this.vendor, required this.rating, required this.eta, required this.isFav, required this.onFav, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: const Icon(Icons.restaurant_rounded, color: AppColors.brand, size: 20)),
            const Spacer(),
            GestureDetector(
              onTap: onFav,
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isFav ? AppColors.errorBg : AppColors.surfaceMuted, shape: BoxShape.circle, border: Border.all(color: isFav ? AppColors.errorBorder : AppColors.border)), child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 13, color: isFav ? AppColors.error : AppColors.textTertiary)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(vendor.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Row(children: [const Icon(Icons.place_outlined, size: 11, color: AppColors.textTertiary), const SizedBox(width: 3), Expanded(child: Text(vendor.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)))]),
          const Spacer(),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.successBorder)), child: const Row(children: [Icon(Icons.circle, size: 5, color: AppColors.success), SizedBox(width: 4), Text('Open', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700))])),
            const SizedBox(width: 6),
            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
            Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Row(children: [const Icon(Icons.timer_outlined, size: 11, color: AppColors.textTertiary), const SizedBox(width: 4), Text(eta, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)), const Spacer(), const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textTertiary)]),
        ]),
      );
}

// ─── Vendor Menu ─────────────────────────────────────────────
class VendorMenuScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorMenuScreen({super.key, required this.vendorId});
  @override
  ConsumerState<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends ConsumerState<VendorMenuScreen> {
  String _query = '';
  String _category = 'All';
  bool _vegOnly = false;
  bool _availableOnly = false;
  String _sort = 'popular';
  final Set<String> _favs = {};

  IconData _catIcon(String c) {
    switch (c.toUpperCase()) {
      case 'RICE':
      case 'BIRYANI':
        return Icons.rice_bowl_rounded;
      case 'BURGER':
        return Icons.lunch_dining_rounded;
      case 'DRINKS':
        return Icons.local_cafe_rounded;
      case 'SNACKS':
        return Icons.cookie_rounded;
      case 'MAIN':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(vendorMenuProvider(widget.vendorId));
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Menu',
        subtitle: cart.isEmpty ? 'Freshly made on campus' : '${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'} • ${cart.subtotal}৳ in cart',
        onBack: () => context.go('/student/vendors'),
        action: !cart.isEmpty
            ? FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/student/cart');
                },
                icon: Badge(
                  label: Text('${cart.lines.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  backgroundColor: Colors.white,
                  textColor: AppColors.brand,
                  child: const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.white),
                ),
                label: Text('Cart • ${cart.subtotal}৳'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
              decoration: InputDecoration(
                hintText: 'Search dishes, e.g. chicken, biryani',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _query = '')) : null,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            // Category chips + filters
            menu.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                final cats = <String>{'All', ...items.map((e) => e.category)}.toList();
                return Column(children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = cats[i];
                        final selected = c == _category;
                        return ChoiceChip(
                          avatar: Icon(_catIcon(c), size: 14, color: selected ? AppColors.brand : AppColors.textTertiary),
                          label: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.brand : AppColors.textSecondary)),
                          selected: selected,
                          selectedColor: AppColors.brandSubtle,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: selected ? AppColors.brand.withValues(alpha: 0.3) : AppColors.border),
                          showCheckmark: false,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _category = c);
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      FilterChip(
                        label: const Text('Veg only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        avatar: Icon(Icons.eco_rounded, size: 14, color: _vegOnly ? Colors.white : AppColors.success),
                        selected: _vegOnly,
                        selectedColor: AppColors.success,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: _vegOnly ? AppColors.success : AppColors.border),
                        labelStyle: TextStyle(color: _vegOnly ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        showCheckmark: false,
                        onSelected: (v) => setState(() => _vegOnly = v),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        avatar: Icon(Icons.check_circle_outline_rounded, size: 14, color: _availableOnly ? Colors.white : AppColors.success),
                        selected: _availableOnly,
                        selectedColor: AppColors.brand,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: _availableOnly ? AppColors.brand : AppColors.border),
                        labelStyle: TextStyle(color: _availableOnly ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        showCheckmark: false,
                        onSelected: (v) => setState(() => _availableOnly = v),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: AppColors.border)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sort,
                            isDense: true,
                            icon: const Icon(Icons.sort_rounded, size: 14, color: AppColors.textTertiary),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'popular', child: Text('Popular')),
                              DropdownMenuItem(value: 'price_low', child: Text('Price ↑')),
                              DropdownMenuItem(value: 'price_high', child: Text('Price ↓')),
                              DropdownMenuItem(value: 'name', child: Text('Name A–Z')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _sort = v);
                            },
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]);
              },
            ),
            // cart hint
            if (!cart.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.brand.withOpacity(0.15))),
                child: Row(children: [
                  const Icon(Icons.shopping_bag_rounded, size: 14, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'} • ${cart.subtotal}৳ — tap Add (+/−) to adjust', style: const TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w600))),
                  GestureDetector(
                    onTap: () => context.go('/student/cart'),
                    child: const Text('View cart →', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ],
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
                final matchesVeg = !_vegOnly || it.category.toLowerCase().contains('veg') || it.name.toLowerCase().contains('veg');
                final matchesAvail = !_availableOnly || it.isAvailable;
                return matchesQuery && matchesCat && matchesVeg && matchesAvail;
              }).toList();
              // sort
              switch (_sort) {
                case 'price_low':
                  filtered.sort((a, b) => a.priceTaka.compareTo(b.priceTaka));
                  break;
                case 'price_high':
                  filtered.sort((a, b) => b.priceTaka.compareTo(a.priceTaka));
                  break;
                case 'name':
                  filtered.sort((a, b) => a.name.compareTo(b.name));
                  break;
                default:
                  // popular: available first, then by price
                  filtered.sort((a, b) {
                    if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
                    return 0;
                  });
              }
              if (filtered.isEmpty) {
                return EmptyView(
                  icon: Icons.no_food_rounded,
                  message: 'No items match — try clearing filters.',
                  actionLabel: 'Clear filters',
                  onAction: () => setState(() {
                    _query = '';
                    _category = 'All';
                    _vegOnly = false;
                    _availableOnly = false;
                  }),
                );
              }
              return RefreshIndicator(
                color: AppColors.brand,
                backgroundColor: AppColors.surface,
                onRefresh: () async => ref.invalidate(vendorMenuProvider(widget.vendorId)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final unavailable = !item.isAvailable;
                    final cartQty = cart.lines[item.id]?.qty ?? 0;
                    final isFav = _favs.contains(item.id);
                    final isPopular = i < 2 && item.isAvailable;
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Stack(children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                color: unavailable ? AppColors.surfaceMuted : AppColors.brandSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: unavailable ? AppColors.border : AppColors.brand.withOpacity(0.15))),
                            child: Icon(_catIcon(item.category), size: 26, color: unavailable ? AppColors.textTertiary : AppColors.brand),
                          ),
                          if (isPopular)
                            Positioned(
                              top: -2,
                              left: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
                                child: const Text('★ Popular', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                              ),
                            ),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(item.name, style: TextStyle(color: unavailable ? AppColors.textTertiary : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14, decoration: unavailable ? TextDecoration.lineThrough : null))),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => isFav ? _favs.remove(item.id) : _favs.add(item.id));
                              },
                              child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: isFav ? AppColors.error : AppColors.textTertiary),
                            ),
                            if (unavailable) ...[
                              const SizedBox(width: 6),
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                                  child: const Text('Unavailable', style: TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w700))),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [
                            PriceText(item.priceTaka, fontSize: 13, color: unavailable ? AppColors.textTertiary : AppColors.textPrimary),
                            const SizedBox(width: 6),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.border)), child: Text(item.category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600))),
                            if (cartQty > 0) ...[
                              const SizedBox(width: 6),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brandSubtle, borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.brand.withOpacity(0.15))), child: Text('×$cartQty in cart', style: const TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w700))),
                            ],
                          ]),
                          if (item.description != null && item.description!.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(item.description!,
                                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          Row(children: [
                            Icon(Icons.timer_outlined, size: 10, color: AppColors.textTertiary.withOpacity(0.8)),
                            const SizedBox(width: 3),
                            Text('${10 + (item.id.hashCode.abs() % 8)} min', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text((4.3 + (item.id.hashCode.abs() % 6) * 0.1).toStringAsFixed(1), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                          ]),
                        ])),
                        const SizedBox(width: 10),
                        // Quantity stepper or Add button
                        SizedBox(
                          height: 72,
                          child: unavailable
                              ? const SizedBox.shrink()
                              : cartQty == 0
                                  ? Column(children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          final cartState = ref.read(cartProvider);
                                          if (cartState.vendorId != null && cartState.vendorId != item.vendorId) {
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
                                          HapticFeedback.selectionClick();
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} added'), duration: const Duration(milliseconds: 900), behavior: SnackBarBehavior.floating));
                                        },
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: const Size(0, 36), side: const BorderSide(color: AppColors.brand)),
                                        child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${item.priceTaka}৳', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
                                    ])
                                  : Container(
                                      decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            ref.read(cartProvider.notifier).add(item);
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.add_rounded, size: 16, color: Colors.white)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                          child: Text('$cartQty', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 13)),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            ref.read(cartProvider.notifier).decrement(item.id);
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.remove_rounded, size: 16, color: Colors.white)),
                                        ),
                                      ]),
                                    ),
                        ),
                      ]),
                    );
                  },
                ),
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
                    Text('${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'} • ${cart.lines.values.fold(0, (s, l) => s + l.qty)} pcs', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    PriceText(cart.subtotal, fontSize: 16),
                    const Text('+ 5৳ service fee', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryButton(label: 'View cart → ${cart.subtotal + 5}৳', icon: Icons.shopping_bag_outlined, onPressed: () => context.go('/student/cart'))),
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
