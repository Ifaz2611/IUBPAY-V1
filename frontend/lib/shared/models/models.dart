/// Plain Dart models mirroring backend JSON responses.
/// Parsing is defensive — missing or mistyped fields fall back to safe defaults
/// and never throw on rendering paths.
library;

class User {
  final String id, name, email, role, status;
  final String? studentId, phone, vendorId;

  User({required this.id, required this.name, required this.email, required this.role, required this.status, this.studentId, this.phone, this.vendorId});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? 'Unknown'}',
        email: '${j['email'] ?? ''}',
        role: '${j['role'] ?? 'student'}',
        status: '${j['status'] ?? 'ACTIVE'}',
        studentId: j['student_id']?.toString(),
        phone: j['phone']?.toString(),
        vendorId: j['vendor_id']?.toString(),
      );
}

class Vendor {
  final String id, name, location, status;
  final String? description;
  Vendor({required this.id, required this.name, required this.location, required this.status, this.description});

  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? 'Unknown vendor'}',
        location: '${j['location'] ?? ''}',
        status: '${j['status'] ?? 'APPROVED'}',
        description: j['description']?.toString(),
      );
}

class MenuItem {
  final String id, vendorId, name, category;
  final int priceTaka;
  final bool isAvailable;
  final String? description;
  MenuItem({required this.id, required this.vendorId, required this.name, required this.priceTaka, required this.category, required this.isAvailable, this.description});

  static int _int(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: '${j['id'] ?? ''}',
        vendorId: '${j['vendor_id'] ?? ''}',
        name: '${j['name'] ?? 'Item'}',
        priceTaka: _int(j['price_taka']),
        category: '${j['category'] ?? 'OTHER'}',
        isAvailable: j['is_available'] is bool ? j['is_available'] as bool : (j['is_available']?.toString() == 'true' ? true : true),
        description: j['description']?.toString(),
      );
}

class OrderItem {
  final String name;
  final int unitPrice, quantity, subtotal;
  OrderItem({required this.name, required this.unitPrice, required this.quantity, required this.subtotal});

  static int _int(dynamic v) => v is int ? v : v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: '${j['item_name_snapshot'] ?? j['name'] ?? 'Item'}',
        unitPrice: _int(j['unit_price_snapshot_taka'] ?? j['unit_price'] ?? 0),
        quantity: _int(j['quantity'] ?? 1),
        subtotal: _int(j['subtotal_taka'] ?? j['subtotal'] ?? 0),
      );
}

class Payment {
  final String id, status;
  final int amountTaka;
  final String? failureReason;
  Payment({required this.id, required this.status, required this.amountTaka, this.failureReason});

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: '${j['id'] ?? ''}',
        status: '${j['status'] ?? 'UNKNOWN'}',
        amountTaka: j['amount_taka'] is int ? j['amount_taka'] as int : int.tryParse('${j['amount_taka']}') ?? 0,
        failureReason: j['failure_reason']?.toString(),
      );
}

class Order {
  final String id, orderNumber, status, pickupCode, vendorId, studentId;
  final int subtotal, serviceFee, totalAmount;
  final List<OrderItem> items;
  final List<Payment> payments;
  final DateTime? createdAt;

  Order({required this.id, required this.orderNumber, required this.status, required this.pickupCode, required this.vendorId, required this.studentId, required this.subtotal, required this.serviceFee, required this.totalAmount, required this.items, required this.payments, this.createdAt});

  Payment? get latestPayment => payments.isNotEmpty ? payments.last : null;

  static int _int(dynamic v) => v is int ? v : v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: '${j['id'] ?? ''}',
        orderNumber: '${j['order_number'] ?? j['orderNumber'] ?? ''}',
        status: '${j['status'] ?? 'UNKNOWN'}',
        pickupCode: '${j['pickup_code'] ?? j['pickupCode'] ?? '—'}',
        vendorId: '${j['vendor_id'] ?? ''}',
        studentId: '${j['student_id'] ?? ''}',
        subtotal: _int(j['subtotal_taka'] ?? j['subtotal']),
        serviceFee: _int(j['service_fee_taka'] ?? j['service_fee'] ?? 0),
        totalAmount: _int(j['total_amount_taka'] ?? j['total_amount'] ?? j['totalAmount'] ?? 0),
        items: (j['items'] as List?)?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
        payments: (j['payments'] as List?)?.map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
        createdAt: j['created_at'] != null ? DateTime.tryParse('${j['created_at']}') : null,
      );
}
