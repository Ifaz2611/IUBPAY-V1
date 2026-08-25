import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';

final vendorListProvider = FutureProvider<List<Vendor>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors');
  return (r.data as List).map((e) => Vendor.fromJson(e)).toList();
});

final vendorMenuProvider =
    FutureProvider.family<List<MenuItem>, String>((ref, vendorId) async {
  final r = await ref.read(dioProvider).get('/vendors/$vendorId/menu');
  return (r.data as List).map((e) => MenuItem.fromJson(e)).toList();
});

/// Cart is scoped to a single vendor at a time.
class CartLine {
  final MenuItem item;
  int qty;
  CartLine(this.item, {this.qty = 1});
}

class CartState {
  final String? vendorId;
  final Map<String, CartLine> lines;
  const CartState({this.vendorId, this.lines = const {}});

  int get subtotal => lines.values.fold(0, (s, l) => s + l.item.priceTaka * l.qty);
  bool get isEmpty => lines.isEmpty;

  CartState clear() => const CartState();
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void add(MenuItem item) {
    final current = state;
    if (current.vendorId != null && current.vendorId != item.vendorId) return;
    final lines = {...current.lines};
    final line = lines[item.id];
    if (line == null) {
      lines[item.id] = CartLine(item);
    } else if (line.qty < 20) {
      line.qty++;
    }
    state = CartState(vendorId: item.vendorId, lines: lines);
  }

  void decrement(String itemId) {
    final current = state;
    final lines = {...current.lines};
    final line = lines[itemId];
    if (line == null) return;
    if (line.qty <= 1) {
      lines.remove(itemId);
    } else {
      line.qty--;
    }
    state =
        lines.isEmpty ? const CartState() : CartState(vendorId: current.vendorId, lines: lines);
  }

  void reset() => state = const CartState();
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final r = await ref.read(dioProvider).get('/students/me/orders');
  return (r.data as List).map((e) => Order.fromJson(e)).toList();
});

final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  try {
    final r = await ref.read(dioProvider).get('/orders/$orderId');
    return Order.fromJson(r.data);
  } on DioException catch (e) {
    throw Exception(apiErrorMessage(e));
  }
});
