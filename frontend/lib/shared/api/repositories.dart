import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../models/models.dart';

/// Repository layer to decouple UI widgets from Dio.
/// Widgets should depend on these repositories, not call Dio directly.

// ---------- Order Repository ----------

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  Future<Order> createOrder({required String vendorId, required List<Map<String, dynamic>> items, required String idempotencyKey}) async {
    final r = await _dio.post('/orders', data: {
      'vendor_id': vendorId,
      'items': items,
      'idempotency_key': idempotencyKey,
    });
    return Order.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<Order> getOrder(String orderId) async {
    final r = await _dio.get('/orders/$orderId');
    return Order.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<List<Order>> myOrders() async {
    final r = await _dio.get('/students/me/orders');
    return _parsePaginated(r.data, Order.fromJson);
  }

  Future<void> cancelOrder(String orderId) async {
    await _dio.post('/orders/$orderId/cancel');
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _dio.patch('/orders/$orderId/status', data: {'status': status});
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(dioProvider));
});

// ---------- Vendor Repository ----------

class VendorRepository {
  final Dio _dio;
  VendorRepository(this._dio);

  Future<List<Vendor>> listVendors({int? limit, int? offset, bool includeAll = false}) async {
    final r = await _dio.get('/vendors', queryParameters: {
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (includeAll) 'include_all': true,
    });
    return _parsePaginated(r.data, Vendor.fromJson);
  }

  Future<Vendor> getVendor(String id) async {
    final r = await _dio.get('/vendors/$id');
    return Vendor.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<List<MenuItem>> vendorMenu(String vendorId) async {
    final r = await _dio.get('/vendors/$vendorId/menu');
    return _parsePaginated(r.data, MenuItem.fromJson);
  }

  Future<List<MenuItem>> myMenu() async {
    final r = await _dio.get('/vendors/me/menu');
    return _parsePaginated(r.data, MenuItem.fromJson);
  }

  Future<List<Order>> myOrders() async {
    final r = await _dio.get('/vendors/me/orders');
    return _parsePaginated(r.data, Order.fromJson);
  }

  Future<Map<String, dynamic>> sales() async {
    final r = await _dio.get('/vendors/me/sales');
    return Map<String, dynamic>.from(r.data as Map);
  }
}

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository(ref.read(dioProvider));
});

// ---------- Menu Repository ----------

class MenuRepository {
  final Dio _dio;
  MenuRepository(this._dio);

  Future<List<MenuItem>> list(String vendorId) async {
    final r = await _dio.get('/vendors/$vendorId/menu');
    return _parsePaginated(r.data, MenuItem.fromJson);
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) => MenuRepository(ref.read(dioProvider)));

// ---------- Payment Repository ----------

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  Future<Map<String, dynamic>> createPayment(String orderId) async {
    final r = await _dio.post('/payments/create', data: {'order_id': orderId});
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> mockComplete(String paymentId, {int delaySeconds = 0}) async {
    final r = await _dio.post('/payments/mock/complete', data: {'payment_id': paymentId, 'delay_seconds': delaySeconds});
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> mockFail(String paymentId, {int delaySeconds = 0}) async {
    final r = await _dio.post('/payments/mock/fail', data: {'payment_id': paymentId, 'delay_seconds': delaySeconds});
    return Map<String, dynamic>.from(r.data as Map);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository(ref.read(dioProvider)));

// ---------- helpers ----------

List<T> _parsePaginated<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is List) return data.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
  if (data is Map && data['items'] is List) {
    return (data['items'] as List).map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  return [];
}
