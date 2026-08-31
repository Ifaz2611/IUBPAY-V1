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
  final int qty;
  const CartLine(this.item, {this.qty = 1});

  CartLine copyWith({int? qty}) => CartLine(item, qty: qty ?? this.qty);
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

  /// Returns true if item was added/incremented, false if at max quantity.
  bool add(MenuItem item) {
    final current = state;
    if (current.vendorId != null && current.vendorId != item.vendorId) return false;
    final lines = Map<String, CartLine>.from(current.lines);
    final line = lines[item.id];
    if (line == null) {
      lines[item.id] = CartLine(item, qty: 1);
    } else if (line.qty < 20) {
      lines[item.id] = line.copyWith(qty: line.qty + 1);
    } else {
      return false;
    }
    state = CartState(vendorId: item.vendorId, lines: lines);
    return true;
  }

  void decrement(String itemId) {
    final current = state;
    final lines = Map<String, CartLine>.from(current.lines);
    final line = lines[itemId];
    if (line == null) return;
    if (line.qty <= 1) {
      lines.remove(itemId);
    } else {
      lines[itemId] = line.copyWith(qty: line.qty - 1);
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
