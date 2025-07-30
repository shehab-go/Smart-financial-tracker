import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getDownloadsDirectory();
    }
    dir ??= await getTemporaryDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
