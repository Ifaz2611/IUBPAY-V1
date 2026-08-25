/// Plain Dart models mirroring backend JSON responses.
class User {
  final String id, name, email, role, status;
  final String? studentId, phone, vendorId;

  User({required this.id, required this.name, required this.email,
    required this.role, required this.status,
    this.studentId, this.phone, this.vendorId});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'], name: j['name'], email: j['email'],
        role: j['role'], status: j['status'],
        studentId: j['student_id'], phone: j['phone'], vendorId: j['vendor_id'],
      );
}

class Vendor {
  final String id, name, location, status;
  final String? description;
  Vendor({required this.id, required this.name, required this.location,
    required this.status, this.description});

  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
      id: j['id'], name: j['name'], location: j['location'],
      status: j['status'], description: j['description']);
}

class MenuItem {
  final String id, vendorId, name, category;
  final int priceTaka;
  final bool isAvailable;
  final String? description;
  MenuItem({required this.id, required this.vendorId, required this.name,
    required this.priceTaka, required this.category,
    required this.isAvailable, this.description});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
      id: j['id'], vendorId: j['vendor_id'], name: j['name'],
      priceTaka: j['price_taka'], category: j['category'] ?? 'OTHER',
      isAvailable: j['is_available'] ?? true, description: j['description']);
}

class OrderItem {
  final String name;
  final int unitPrice, quantity, subtotal;
  OrderItem({required this.name, required this.unitPrice,
    required this.quantity, required this.subtotal});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
      name: j['item_name_snapshot'],
      unitPrice: j['unit_price_snapshot_taka'],
      quantity: j['quantity'], subtotal: j['subtotal_taka']);
}

class Payment {
  final String id, status;
  final int amountTaka;
  final String? failureReason;
  Payment({required this.id, required this.status, required this.amountTaka,
    this.failureReason});

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
      id: j['id'], status: j['status'], amountTaka: j['amount_taka'],
      failureReason: j['failure_reason']);
}

class Order {
  final String id, orderNumber, status, pickupCode, vendorId, studentId;
  final int subtotal, serviceFee, totalAmount;
  final List<OrderItem> items;
  final List<Payment> payments;
  final DateTime? createdAt;

  Order({required this.id, required this.orderNumber, required this.status,
    required this.pickupCode, required this.vendorId, required this.studentId,
    required this.subtotal, required this.serviceFee,
    required this.totalAmount, required this.items, required this.payments,
    this.createdAt});

  /// Latest payment, or null for unpaid orders.
  Payment? get latestPayment =>
      payments.isNotEmpty ? payments.last : null;

  factory Order.fromJson(Map<String, dynamic> j) => Order(
      id: j['id'], orderNumber: j['order_number'], status: j['status'],
      pickupCode: j['pickup_code'], vendorId: j['vendor_id'],
      studentId: j['student_id'],
      subtotal: j['subtotal_taka'], serviceFee: j['service_fee_taka'],
      totalAmount: j['total_amount_taka'],
      items: (j['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      payments: (j['payments'] as List?)?.map((e) => Payment.fromJson(e)).toList() ?? [],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at']) : null);
}
