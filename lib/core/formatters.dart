import 'package:intl/intl.dart';

class Formatters {
  static final _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static String formatRupiah(double amount) {
    return _rupiahFormat.format(amount);
  }

  static String formatCompactRupiah(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else {
      return _rupiahFormat.format(amount);
    }
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
}
