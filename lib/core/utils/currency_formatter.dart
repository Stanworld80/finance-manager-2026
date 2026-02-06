import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _euroFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _euroFormat.format(amount);
  }
}
