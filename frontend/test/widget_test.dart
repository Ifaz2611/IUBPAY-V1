import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iub_pay/core/utils/money_formatter.dart';
import 'package:iub_pay/features/student/providers/student_providers.dart';
import 'package:iub_pay/shared/models/models.dart';

void main() {
  test('taka formatting', () {
    expect(taka(180), '\u09f3180');
    expect(taka(25), '\u09f325');
  });

  group('CartController', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartProvider);
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0);
      expect(cart.vendorId, isNull);
    });

    test('adds items and updates subtotal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final item1 = MenuItem(
        id: 'item1',
        vendorId: 'v1',
        name: 'Burger',
        priceTaka: 150,
        category: 'MEAL',
        isAvailable: true,
      );

      final ok = notifier.add(item1);
      expect(ok, isTrue);
      var cart = container.read(cartProvider);
      expect(cart.isEmpty, isFalse);
      expect(cart.vendorId, 'v1');
      expect(cart.lines['item1']?.qty, 1);
      expect(cart.subtotal, 150);

      // Add same item again
      notifier.add(item1);
      cart = container.read(cartProvider);
      expect(cart.lines['item1']?.qty, 2);
      expect(cart.subtotal, 300);
    });

    test('rejects items from a different vendor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final item1 = MenuItem(
        id: 'item1',
        vendorId: 'v1',
        name: 'Burger',
        priceTaka: 150,
        category: 'MEAL',
        isAvailable: true,
      );
      final item2 = MenuItem(
        id: 'item2',
        vendorId: 'v2',
        name: 'Pizza',
        priceTaka: 250,
        category: 'MEAL',
        isAvailable: true,
      );

      expect(notifier.add(item1), isTrue);
      expect(notifier.add(item2), isFalse);
      final cart = container.read(cartProvider);
      expect(cart.lines.containsKey('item2'), isFalse);
    });

    test('enforces max 20 quantity limit per item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final item = MenuItem(
        id: 'item1',
        vendorId: 'v1',
        name: 'Burger',
        priceTaka: 100,
        category: 'MEAL',
        isAvailable: true,
      );

      for (int i = 0; i < 20; i++) {
        expect(notifier.add(item), isTrue);
      }
      expect(container.read(cartProvider).lines['item1']?.qty, 20);
      expect(notifier.add(item), isFalse);
      expect(container.read(cartProvider).lines['item1']?.qty, 20);
    });

    test('decrement reduces quantity and removes when 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final item = MenuItem(
        id: 'item1',
        vendorId: 'v1',
        name: 'Burger',
        priceTaka: 100,
        category: 'MEAL',
        isAvailable: true,
      );

      notifier.add(item);
      notifier.add(item);
      expect(container.read(cartProvider).lines['item1']?.qty, 2);

      notifier.decrement('item1');
      expect(container.read(cartProvider).lines['item1']?.qty, 1);

      notifier.decrement('item1');
      expect(container.read(cartProvider).lines.containsKey('item1'), isFalse);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('reset clears cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      final item = MenuItem(
        id: 'item1',
        vendorId: 'v1',
        name: 'Burger',
        priceTaka: 100,
        category: 'MEAL',
        isAvailable: true,
      );
      notifier.add(item);
      expect(container.read(cartProvider).isEmpty, isFalse);

      notifier.reset();
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(container.read(cartProvider).vendorId, isNull);
    });
  });

  group('Model parsing', () {
    test('Order.fromJson handles string and num values defensively', () {
      final json = {
        'id': 'ord-123',
        'order_number': 'IUB-2026-ABC',
        'status': 'PAID',
        'pickup_code': 'ABC123',
        'vendor_id': 'v-1',
        'student_id': 's-1',
        'subtotal_taka': '300',
        'service_fee_taka': 5,
        'total_amount_taka': '305',
        'items': [
          {
            'item_name_snapshot': 'Biryani',
            'unit_price_snapshot_taka': '150',
            'quantity': 2,
            'subtotal_taka': 300,
          }
        ],
        'payments': [
          {
            'id': 'pay-1',
            'status': 'SUCCEEDED',
            'amount_taka': '305',
          }
        ],
      };

      final order = Order.fromJson(json);
      expect(order.id, 'ord-123');
      expect(order.subtotal, 300);
      expect(order.serviceFee, 5);
      expect(order.totalAmount, 305);
      expect(order.items.length, 1);
      expect(order.items.first.unitPrice, 150);
      expect(order.latestPayment?.amountTaka, 305);
    });
  });
}
