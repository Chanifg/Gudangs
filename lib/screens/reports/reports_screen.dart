import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/export_service.dart';
import '../../core/formatters.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/inbound_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/salary_provider.dart';
import '../../models/outbound_record.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReportType = 'inventori';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  bool _isExporting = false;

  final List<Map<String, String>> _reportTypes = [
    {'value': 'inventori', 'label': 'Laporan Stok Inventori'},
    {'value': 'inbound', 'label': 'Laporan Barang Masuk (Inbound)'},
    {'value': 'outbound', 'label': 'Laporan Barang Keluar (Outbound)'},
    {'value': 'keuangan', 'label': 'Laporan Keuangan & Margin'},
    {'value': 'aktivitas', 'label': 'Laporan Aktivitas Harian'},
    {'value': 'gaji', 'label': 'Laporan Upah/Gaji Karyawan'},
  ];

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Rentang Laporan',
    );
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _exportReport(bool isPdf) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final start = _dateRange.start.subtract(const Duration(seconds: 1));
      final end = _dateRange.end.add(const Duration(days: 1));
      final dateStr = '${Formatters.formatDate(_dateRange.start)} - ${Formatters.formatDate(_dateRange.end)}';

      String title = '';
      List<String> headers = [];
      List<List<String>> rows = [];
      String? subtitle;

      switch (_selectedReportType) {
        case 'inventori':
          title = 'Laporan Stok Inventori Gudang';
          subtitle = 'Per Tanggal: ${Formatters.formatDate(DateTime.now())}';
          headers = ['Nama Produk', 'SKU', 'Kategori', 'Stok Saat Ini', 'Satuan'];
          final products = ref.read(inventoryProvider).products;
          rows = products.map((p) {
            return [
              p.name,
              p.sku,
              p.category ?? '-',
              p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 1),
              p.unit,
            ];
          }).toList();
          break;

        case 'inbound':
          title = 'Laporan Penerimaan Barang Masuk (Inbound)';
          subtitle = 'Periode: $dateStr';
          headers = ['Tanggal', 'Produk', 'SKU', 'Jumlah', 'Harga Unit', 'Total Biaya', 'Keterangan'];
          final allInbounds = ref.read(inboundProvider).records;
          final filtered = allInbounds.where((rec) => rec.date.isAfter(start) && rec.date.isBefore(end)).toList();
          rows = filtered.map((rec) {
            return [
              Formatters.formatDate(rec.date),
              rec.productName,
              rec.productSku,
              rec.quantity.toStringAsFixed(rec.quantity % 1 == 0 ? 0 : 1),
              Formatters.formatRupiah(rec.pricePerUnit),
              Formatters.formatRupiah(rec.totalCost),
              rec.notes ?? '-',
            ];
          }).toList();
          break;

        case 'outbound':
          title = 'Laporan Pengiriman Barang Keluar (Outbound)';
          subtitle = 'Periode: $dateStr';
          headers = ['Tanggal', 'Produk', 'Tujuan', 'Jumlah', 'Harga Unit', 'Total Nilai', 'Status'];
          final allOutbounds = ref.read(outboundProvider).records;
          final filtered = allOutbounds.where((rec) => rec.date.isAfter(start) && rec.date.isBefore(end)).toList();
          rows = filtered.map((rec) {
            return [
              Formatters.formatDate(rec.date),
              rec.productName,
              rec.destination,
              rec.quantity.toStringAsFixed(rec.quantity % 1 == 0 ? 0 : 1),
              Formatters.formatRupiah(rec.sellingPricePerUnit),
              Formatters.formatRupiah(rec.totalValue),
              rec.status == OutboundStatus.pending ? 'Pending' : rec.status == OutboundStatus.terkirim ? 'Terkirim' : 'Dibatalkan',
            ];
          }).toList();
          break;

        case 'keuangan':
          title = 'Ringkasan Keuangan Gudang';
          subtitle = 'Periode: $dateStr';
          headers = ['Metrik Operasional', 'Nilai / Jumlah'];
          
          final allInbounds = ref.read(inboundProvider).records;
          final filteredInbounds = allInbounds.where((rec) => rec.date.isAfter(start) && rec.date.isBefore(end)).toList();
          final totalInboundCost = filteredInbounds.fold(0.0, (sum, rec) => sum + rec.totalCost);

          final allOutbounds = ref.read(outboundProvider).records;
          final filteredOutbounds = allOutbounds.where((rec) => rec.date.isAfter(start) && rec.date.isBefore(end) && rec.status != OutboundStatus.dibatalkan).toList();
          final totalOutboundVal = filteredOutbounds.fold(0.0, (sum, rec) => sum + rec.totalValue);

          final margin = totalOutboundVal - totalInboundCost;

          rows = [
            ['Total Transaksi Inbound', filteredInbounds.length.toString()],
            ['Total Biaya Inbound (Belanja)', Formatters.formatRupiah(totalInboundCost)],
            ['Total Transaksi Outbound (Aktif)', filteredOutbounds.length.toString()],
            ['Total Estimasi Nilai Outbound (Jual)', Formatters.formatRupiah(totalOutboundVal)],
            ['Margin Kotor Keuangan Gudang', Formatters.formatRupiah(margin)],
          ];
          break;

        case 'aktivitas':
          title = 'Laporan Aktivitas Harian Karyawan';
          subtitle = 'Periode: $dateStr';
          headers = ['Tanggal', 'Karyawan', 'Pekerjaan', 'Hasil Kerja', 'Tarif Satuan', 'Upah'];
          final allActivities = ref.read(activityProvider).records;
          final filtered = allActivities.where((rec) => rec.date.isAfter(start) && rec.date.isBefore(end)).toList();
          rows = filtered.map((rec) {
            return [
              Formatters.formatDate(rec.date),
              rec.employeeName,
              rec.jobTypeName,
              '${rec.units.toStringAsFixed(rec.units % 1 == 0 ? 0 : 1)} unit',
              Formatters.formatRupiah(rec.ratePerUnit),
              Formatters.formatRupiah(rec.estimatedWage),
            ];
          }).toList();
          break;

        case 'gaji':
          title = 'Laporan Rekapitulasi Gaji Karyawan';
          subtitle = 'Periode: $dateStr';
          headers = ['Nama Karyawan', 'Posisi', 'Jumlah Hari Kerja', 'Total Gaji'];
          
          // Trigger salary calculator with temporary range
          final initialRange = ref.read(salaryProvider).dateRange;
          ref.read(salaryProvider.notifier).setDateRange(_dateRange);
          final summaries = ref.read(salaryProvider).summaries;
          
          rows = summaries.map((sum) {
            return [
              sum.employee.fullName,
              sum.employee.position,
              sum.totalActivities.toString(),
              Formatters.formatRupiah(sum.totalSalary),
            ];
          }).toList();

          // Reset back to initial date range
          ref.read(salaryProvider.notifier).setDateRange(initialRange);
          break;
      }

      if (isPdf) {
        await ExportService.sharePdfReport(
          title: title,
          subtitle: subtitle,
          headers: headers,
          rows: rows,
        );
      } else {
        await ExportService.shareExcelReport(
          title: '$title ($subtitle)',
          headers: headers,
          rows: rows,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil diekspor & siap dibagikan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor laporan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateRangeStr = '${Formatters.formatDate(_dateRange.start)} - ${Formatters.formatDate(_dateRange.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekspor Laporan'),
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang memproses dokumen laporan...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Help instruction card
                  Card(
                    color: colorScheme.primary.withOpacity(0.05),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF006E2F)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pilih tipe laporan dan rentang tanggal untuk mengekspor dokumen dalam format PDF atau Excel secara offline.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Report Type Dropdown
                  const Text(
                    'PILIH TIPE LAPORAN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    items: _reportTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReportType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date range selector (only show if not inventory snapshot)
                  if (_selectedReportType != 'inventori') ...[
                    const Text(
                      'RENTANG TANGGAL LAPORAN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          dateRangeStr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      '* Laporan stok inventori menggunakan data kondisi barang saat ini.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _exportReport(true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Ekspor PDF & Bagikan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _exportReport(false),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Ekspor Excel & Bagikan'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
