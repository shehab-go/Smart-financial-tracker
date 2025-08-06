import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReportService {
  /// Generates a simple PDF report with the provided [title] and [content]
  /// and opens it automatically using the default PDF viewer on the device.
  static final Future<pw.Font> _arabicFontFuture = _loadArabicFont();

  static Future<void> generateAndOpenPdf({
    required String title,
    required List<pw.Widget> content,
  }) async {
    final pdf = pw.Document();

    // ensure Arabic font is loaded
    final arabicFont = await _arabicFontFuture;
    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
      italic: arabicFont,
      boldItalic: arabicFont,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(children: [
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(title, style: pw.TextStyle(fontSize: 24), textDirection: pw.TextDirection.rtl),
              ),
              ...content,
            ]),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    Directory dir;
    if (Platform.isAndroid) {
      // Ensure storage permission similar to BackupService
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      // Public Downloads/FinanceApp/report
      dir = Directory('/storage/emulated/0/Download/FinanceApp/report');
    } else {
      final downloads = await getDownloadsDirectory();
      dir = Directory('${downloads?.path ?? (await getTemporaryDirectory()).path}/FinanceApp/report');
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // Build file name: <slug>-<increment>-YYYY-MM-DD.pdf
    final slug = title
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    // Determine next incremental number for this slug.
    final existingIndexes = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path) == '.pdf')
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((name) => name.startsWith('$slug-'))
        .map((name) {
          final rest = name.substring(slug.length + 1); // after slug-
          final parts = rest.split('-');
          if (parts.isEmpty) return -1;
          return int.tryParse(parts[0]) ?? -1;
        })
        .where((n) => n >= 0)
        .toList();
    final nextIndex = existingIndexes.isEmpty ? 0 : (existingIndexes.reduce((a, b) => a > b ? a : b) + 1);

    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final fileName = '$nextIndex-$slug-$dateStr.pdf';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes);
    debugPrint('PDF saved to: ${file.path}');
    final result = await OpenFile.open(file.path);
    debugPrint('OpenFile result: ${result.type}');
  }

  static Future<pw.Font> _loadArabicFont() async {
    final data = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    return pw.Font.ttf(data);
  }
}
