import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExportService {
  // تنسيق التاريخ العربي
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  // ==================== PDF التصدير إلى ====================
  static Future<File> exportToPdf({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    required String institutionName,
    String? logoPath,
    bool withCharts = false,
    bool withSummary = true,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    try {
      final pdf = pw.Document();

      // إضافة الصفحات مع معالجة البيانات الكبيرة
      final dataChunks = _splitData(data, 30); // 30 صف لكل صفحة

      for (int i = 0; i < dataChunks.length; i++) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: pageFormat,
            header: (context) => _buildPdfHeader(institutionName, title, logoPath, i + 1, dataChunks.length),
            footer: (context) => _buildPdfFooter(),
            build: (context) => [
              if (i == 0 && withSummary) ..._buildPdfSummary(data, title),
              if (i == 0 && withCharts) ..._buildPdfCharts(data),
              _buildPdfDataTable(dataChunks[i], columns, i == 0),
              if (i == dataChunks.length - 1) _buildPdfConclusion(data),
            ],
          ),
        );
      }

      // حفظ الملف
      final output = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      throw Exception('فشل إنشاء PDF: $e');
    }
  }

  // ==================== Excel التصدير إلى ====================
  static Future<File> exportToExcel({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    required String institutionName,
    bool withCharts = false,
  }) async {
    try {
      // إنشاء ملف Excel جديد
      final excel = Excel.createExcel();
      final sheet = excel[_sanitizeSheetName(title)];

      // إضافة الترويسة
      _appendExcelRow(sheet, [institutionName]);
      _appendExcelRow(sheet, [title]);
      _appendExcelRow(sheet, ['تاريخ التصدير:', _dateFormat.format(DateTime.now())]);
      _appendExcelRow(sheet, ['عدد السجلات:', data.length.toString()]);
      _appendExcelRow(sheet, []); // سطر فارغ

      // إضافة عناوين الأعمدة
      _appendExcelRow(sheet, columns);

      // إضافة البيانات
      for (final row in data) {
        final List<String> rowData = [];
        for (final column in columns) {
          final value = row[column];
          if (value is DateTime) {
            rowData.add(_dateFormat.format(value));
          } else if (value is num) {
            rowData.add(value.toString());
          } else {
            rowData.add(value?.toString() ?? '');
          }
        }
        _appendExcelRow(sheet, rowData);
      }

      // إضافة الإحصائيات إن وجدت
      if (data.isNotEmpty) {
        _appendExcelRow(sheet, []);
        _appendExcelRow(sheet, ['الإحصائيات:', 'القيمة']);
        _appendExcelRow(sheet, ['إجمالي السجلات:', data.length.toString()]);
        
        // إحصائيات رقمية إن وجدت
        _addExcelStatistics(sheet, data, columns);
      }

      // حفظ الملف
      final output = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File("${output.path}/$fileName");
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception('فشل حفظ ملف Excel');
      }
    } catch (e) {
      throw Exception('فشل إنشاء Excel: $e');
    }
  }

  // دالة مساعدة لإضافة صف في Excel
  static void _appendExcelRow(Sheet sheet, List<String> values) {
    final row = sheet.rows.length;
    for (int i = 0; i < values.length; i++) {
      sheet.cell(CellIndex.indexByString('${_numberToExcelColumn(i)}${row + 1}')).value = values[i] as CellValue?;
    }
  }

  // تحويل رقم العمود إلى حرف Excel (A, B, C, ...)
  static String _numberToExcelColumn(int number) {
    String column = '';
    while (number >= 0) {
      column = String.fromCharCode(65 + (number % 26)) + column;
      number = (number ~/ 26) - 1;
    }
    return column;
  }

  // ==================== PDF مكونات ====================
  static pw.Widget _buildPdfHeader(String institution, String title, String? logoPath, int currentPage, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // الشعار (إن وجد)
          if (logoPath != null && File(logoPath).existsSync())
            pw.Image(
              pw.MemoryImage(File(logoPath).readAsBytesSync()),
              width: 50,
              height: 50,
            )
          else
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(25),
              ),
              child: pw.Center(
                child: pw.Text(
                  institution.substring(0, 1),
                  style:  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
          
          // العنوان والمعلومات
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(institution, style:  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(title, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.Text('تاريخ التصدير: ${_dateFormat.format(DateTime.now())}', 
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              ],
            ),
          ),
          
          // رقم الصفحة
          pw.Text('ص $currentPage من $totalPages', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('نظام إلكتروني كفيل - E-Kafel', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          pw.Text('تم الإنشاء في: ${DateTime.now().toString().split(' ')[0]}', 
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildPdfSummary(List<Map<String, dynamic>> data, String title) {
    return [
      pw.Header(level: 1, child: pw.Text('ملخص التقرير')),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue200),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('إجمالي السجلات', data.length.toString()),
            _buildSummaryItem('تاريخ الإنشاء', _dateFormat.format(DateTime.now())),
            _buildSummaryItem('نوع التقرير', title),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style:  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static List<pw.Widget> _buildPdfCharts(List<Map<String, dynamic>> data) {
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text('ملاحظة: يمكن إضافة رسوم بيانية في الإصدارات المتقدمة',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ),
    ];
  }

  static pw.Widget _buildPdfDataTable(List<Map<String, dynamic>> data, List<String> columns, bool isFirstPage) {
    // إنشاء بيانات الجدول
    final tableData = <List<String>>[
      columns, // Header
      ...data.map((row) => columns.map((col) => _formatCellValue(row[col])).toList()),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // رأس الجدول
        pw.TableRow(
          children: columns.map((col) => 
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.blue50,
              child: pw.Text(
                col,
                style:  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            )
          ).toList(),
        ),
        // بيانات الجدول
        for (final row in data) pw.TableRow(
          children: columns.map((col) => 
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                _formatCellValue(row[col]),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right,
              ),
            )
          ).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfConclusion(List<Map<String, dynamic>> data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('خاتمة التقرير', style:  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('• تم تصدير ${data.length} سجل بنجاح', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('• تاريخ الإنشاء: ${_dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('• تم الإنشاء بواسطة نظام إلكتروني كفيل', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ==================== Excel مكونات ====================
  static void _addExcelStatistics(Sheet sheet, List<Map<String, dynamic>> data, List<String> columns) {
    // البحث عن أعمدة رقمية لإضافة إحصائيات
    final numericColumns = columns.where((col) {
      return data.any((row) {
        final value = row[col];
        return value is num;
      });
    }).toList();

    for (final column in numericColumns.take(3)) { // أخذ أول 3 أعمدة رقمية فقط
      final values = data.map((row) {
        final value = row[column];
        return value is num ? value.toDouble() : 0.0;
      }).where((value) => value > 0).toList();

      if (values.isNotEmpty) {
        _appendExcelRow(sheet, ['$column - المتوسط:', (values.reduce((a, b) => a + b) / values.length).toStringAsFixed(2)]);
        _appendExcelRow(sheet, ['$column - المجموع:', values.reduce((a, b) => a + b).toStringAsFixed(2)]);
        _appendExcelRow(sheet, ['$column - الأعلى:', values.reduce(max).toStringAsFixed(2)]);
        _appendExcelRow(sheet, ['$column - الأدنى:', values.reduce(min).toStringAsFixed(2)]);
        _appendExcelRow(sheet, []);
      }
    }
  }

  // ==================== أدوات مساعدة ====================
  static List<List<Map<String, dynamic>>> _splitData(List<Map<String, dynamic>> data, int chunkSize) {
    final chunks = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  static String _formatCellValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return _dateFormat.format(value);
    if (value is double) return value.toStringAsFixed(2);
    return value.toString();
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-_]'), '').replaceAll(' ', '_');
  }

  static String _sanitizeSheetName(String name) {
    // أسماء أوراق Excel محدودة بـ 31 حرفاً ولا يمكن أن تحتوي على بعض الرموز
    var sanitized = name.replaceAll(RegExp(r'[\\/*\[\]:?]'), '');
    return sanitized.length > 31 ? sanitized.substring(0, 31) : sanitized;
  }

  // ==================== المشاركة والمعاينة ====================
  static Future<void> shareFile(File file, BuildContext context, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        sharePositionOrigin: Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 300,
          height: 300,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل مشاركة الملف: $e')),
      );
    }
  }

  static Future<void> previewPdf(File file, BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => file.readAsBytes(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل معاينة PDF: $e')),
      );
    }
  }

  // ==================== إدارة الملفات المؤقتة ====================
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final stat = file.statSync();
          final fileAge = now.difference(stat.modified);
          
          // حذف الملفات الأقدم من ساعة
          if (fileAge.inHours > 1) {
            file.deleteSync();
          }
        }
      }
    } catch (e) {
      print('تنظيف الملفات المؤقتة فشل: $e');
    }
  }
}

// ==================== نموذج إعدادات التصدير ====================
class ExportSettings {
  final bool includeAllFields;
  final bool includeCharts;
  final bool splitLargeFiles;
  final List<String> selectedColumns;
  final PdfPageFormat pageFormat; // تم التغيير هنا
  final bool includeSummary;

  const ExportSettings({
    this.includeAllFields = true,
    this.includeCharts = false,
    this.splitLargeFiles = true,
    this.selectedColumns = const [],
    this.pageFormat = PdfPageFormat.a4, // تم التغيير هنا
    this.includeSummary = true,
  });

  ExportSettings copyWith({
    bool? includeAllFields,
    bool? includeCharts,
    bool? splitLargeFiles,
    List<String>? selectedColumns,
    PdfPageFormat? pageFormat, // تم التغيير هنا
    bool? includeSummary,
  }) {
    return ExportSettings(
      includeAllFields: includeAllFields ?? this.includeAllFields,
      includeCharts: includeCharts ?? this.includeCharts,
      splitLargeFiles: splitLargeFiles ?? this.splitLargeFiles,
      selectedColumns: selectedColumns ?? this.selectedColumns,
      pageFormat: pageFormat ?? this.pageFormat, // تم التغيير هنا
      includeSummary: includeSummary ?? this.includeSummary,
    );
  }
}
