import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Full Indian currency format, e.g. ₹1,00,000 or ₹50,000
  static String formatInr(double amount, {bool showDecimals = false}) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return format.format(amount);
  }

  /// Short Indian currency format, e.g. ₹2.9L, ₹14K, ₹1.5Cr
  static String formatShort(double amount) {
    if (amount.isNaN || amount.isInfinite) return '₹0';

    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();

    if (abs >= 10000000) {
      final cr = abs / 10000000;
      return '$sign₹${_trimTrailingZeros(cr.toStringAsFixed(cr >= 10 ? 1 : 2))}Cr';
    } else if (abs >= 100000) {
      final l = abs / 100000;
      return '$sign₹${_trimTrailingZeros(l.toStringAsFixed(l >= 10 ? 1 : 2))}L';
    } else if (abs >= 1000) {
      final k = abs / 1000;
      return '$sign₹${_trimTrailingZeros(k.toStringAsFixed(k >= 10 ? 1 : 1))}K';
    } else {
      return '$sign₹${abs.toStringAsFixed(0)}';
    }
  }

  static String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    var result = value.replaceAll(RegExp(r'0+$'), '');
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
