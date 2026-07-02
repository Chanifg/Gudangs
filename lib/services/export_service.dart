import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  // Share a table as a beautiful PDF Document
  static Future<void> sharePdfReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 8),
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GUDANGS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.Text(
                        'Sistem Manajemen Gudang & Gaji Offline',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toLocal().toString().substring(0, 16),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),

            // Document Title
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            pw.SizedBox(height: 20),

            // Table Section
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.green800,
              ),
              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerCellDecoration: pw.BoxDecoration(
                color: PdfColors.green800,
                border: pw.Border.all(color: PdfColors.green900, width: 0.5),
              ),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          );
        },
      ),
    );

    // Save PDF file to temporary directory
    final output = await getTemporaryDirectory();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final file = File('${output.path}/Laporan_$sanitizedTitle.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share using share_plus
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan $title',
    );
  }

  // Share a table as an Excel Document
  static Future<void> shareExcelReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final excel = ex.Excel.createExcel();
    final sheetName = 'Laporan';
    final sheet = excel[sheetName];

    // Clear default sheet
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Append Title Block
    sheet.appendRow([ex.TextCellValue(title)]);
    sheet.appendRow([ex.TextCellValue('Diunduh pada: ${DateTime.now().toLocal().toString().substring(0, 16)}')]);
    sheet.appendRow([]); // empty row

    // Append Headers
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());

    // Append Rows
    for (final row in rows) {
      sheet.appendRow(row.map((r) => ex.TextCellValue(r)).toList());
    }

    // Save to temp file
    final output = await getTemporaryDirectory();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final filePath = '${output.path}/Laporan_$sanitizedTitle.xlsx';
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan $title (Excel)',
      );
    }
  }
}
