import 'package:intl/intl.dart';

class CurrencyFormatters {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double? amount) {
    if (amount == null) return '₹0';
    return _inr.format(amount);
  }

  static String formatWithDecimals(double? amount) {
    if (amount == null) return '₹0.00';
    return _inrWithDecimals.format(amount);
  }
}

