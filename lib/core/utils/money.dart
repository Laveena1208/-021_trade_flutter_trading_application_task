import 'package:intl/intl.dart';

/// All money in this app is represented as an [int] number of paise.
/// This file is the ONLY place formatting/rounding happens - every other
/// file does exact integer arithmetic, so there is never any visible
/// floating point drift.
class Money {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format paise as "₹1,23,456.78"
  static String format(int paise) {
    final rupees = paise / 100;
    return _inr.format(rupees);
  }

  /// Format paise as "1,23,456.78" (no currency symbol)
  static String formatPlain(int paise) {
    final rupees = paise / 100;
    return NumberFormat('#,##,##0.00', 'en_IN').format(rupees);
  }

  /// Format a percentage change, e.g. "+1.23%" / "-0.45%"
  static String formatPct(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  /// Format signed paise change, e.g. "+₹12.50" / "-₹3.20"
  static String formatSignedChange(int paise) {
    final sign = paise >= 0 ? '+' : '-';
    return '$sign${format(paise.abs())}';
  }
}
