// Basic widget smoke tests. Full API integration is covered by the backend
// pytest suite (see backend/tests).
import 'package:flutter_test/flutter_test.dart';

import 'package:iub_cafeteria/core/utils/money_formatter.dart';

void main() {
  test('taka formatting', () {
    expect(taka(180), '\u09f3180');
    expect(taka(25), '\u09f325');
  });
}
