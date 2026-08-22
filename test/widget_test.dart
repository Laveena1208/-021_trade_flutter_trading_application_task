import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/utils/money.dart';

void main() {
  test('Money.format and helpers', () {
    // ₹1.00 = 100 paise
    expect(Money.format(100), contains('1.00'));
    expect(Money.format(12345678), contains('1,23,456.78'));
    expect(Money.formatPlain(12345678), contains('1,23,456.78'));

    expect(Money.formatSignedChange(150), contains('+')); // +₹1.50
    expect(Money.formatSignedChange(-50), contains('-')); // -₹0.50

    expect(Money.formatPct(1.2345), contains('+1.23%'));
    expect(Money.formatPct(-0.5), contains('-0.50%'));
  });
}
