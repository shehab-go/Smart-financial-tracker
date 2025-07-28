import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  /// Generates a simple PDF report with the provided [title] and [content]
  /// and opens it automatically using the default PDF viewer on the device.
  static Future<void> generateAndOpenPdf({
    required String title,
    required List<pw.Widget> content,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: title, textStyle: pw.TextStyle(fontSize: 24)),
          ...content,
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

    await OpenFile.open(file.path);
  }
}
