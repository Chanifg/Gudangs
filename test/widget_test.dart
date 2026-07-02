import 'package:flutter_test/flutter_test.dart';
import 'package:gudangs/core/formatters.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Initialize date formatting locale for Indonesia
    await initializeDateFormatting('id_ID', null);
  });

  group('Formatters Unit Tests', () {
    test('formatRupiah formats currency correctly', () {
      expect(Formatters.formatRupiah(1000), 'Rp 1.000');
      expect(Formatters.formatRupiah(5700000), 'Rp 5.700.000');
      expect(Formatters.formatRupiah(0), 'Rp 0');
    });

    test('formatCompactRupiah formats large amounts compactly', () {
      expect(Formatters.formatCompactRupiah(500000), 'Rp 500.000');
      expect(Formatters.formatCompactRupiah(1500000), 'Rp 1.5Jt');
      expect(Formatters.formatCompactRupiah(1000000000), 'Rp 1.0M');
    });

    test('formatDate formats DateTime correctly', () {
      final date = DateTime(2024, 1, 20);
      expect(Formatters.formatDate(date), '20 Jan 2024');
    });

    test('formatMonth formats DateTime to Month Year correctly', () {
      final date = DateTime(2024, 1, 20);
      expect(Formatters.formatMonth(date), 'Januari 2024');
    });
  });
}
