import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/models/models.dart';

List<T> _parsePaginated<T>(dynamic data, T Function(Map<String, dynamic>) f) {
  if (data is List) return data.map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
  if (data is Map && data['items'] is List) return (data['items'] as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
  return [];
}

final myVendorOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/orders');
  return _parsePaginated(r.data, Order.fromJson);
});

final myVendorMenuProvider = FutureProvider<List<MenuItem>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/menu');
  return _parsePaginated(r.data, MenuItem.fromJson);
});

final vendorSalesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors/me/sales');
  return Map<String, dynamic>.from(r.data as Map);
});
