import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import '../db/database_helper.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ReportService {
  static final Future<pw.Font> _arabicFontFuture = _loadArabicFont();
  
  // Convert AppTheme primary color to PDF color
  static final PdfColor primaryColor = PdfColor.fromInt(AppTheme.primaryColor.value);

  static Future<UserProfile?> _getUserProfile() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getUserProfile();
  }

  static Future<void> generateAndOpenPdf({
    required String title,
    required List<pw.Widget> content,
  }) async {
    await _generatePdfInternal(
      title: title,
      content: content,
    );
  }

  static Future<void> generateAndOpenPdfWithTableData({
    required String title,
    required List<pw.Widget> headerContent,
    required List<String> tableHeaders,
    required List<List<String>> tableData,
  }) async {
    await _generatePdfWithPagination(
      title: title,
      headerContent: headerContent,
      tableHeaders: tableHeaders,
      tableData: tableData,
    );
  }

  static Future<void> _generatePdfInternal({
    required String title,
    required List<pw.Widget> content,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await _arabicFontFuture;
    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
      italic: arabicFont,
      boldItalic: arabicFont,
    );

    final userProfile = await _getUserProfile();

    try {
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
          header: (context) => _buildProfessionalHeader(title, userProfile),
          footer: (context) => _buildProfessionalFooter(context),
          maxPages: 100, // Set a reasonable limit
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  ...content,
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // If TooManyPagesException occurs, split content into smaller chunks
      if (e.toString().contains('TooManyPagesException')) {
        await _generatePaginatedPdf(pdf, theme, title, userProfile, content);
      } else {
        rethrow;
      }
    }

    final bytes = await pdf.save();
    await _savePdfFile(bytes, title);
  }

  static pw.Widget _buildProfessionalHeader(String title, UserProfile? profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Left side - Time
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تاريخ التقرير: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, color: primaryColor.shade(0.6)),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'الوقت: ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              // Center - Logo
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: _buildLogoWidget(profile),
                ),
              ),
              // Right side - User name and company
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      (profile?.businessName?.isNotEmpty == true) ? profile!.businessName! : 'غير محدد',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      (profile?.fullName?.isNotEmpty == true) ? profile!.fullName! : 'غير محدد',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Title removed as requested - account name is already in account info
        ],
      ),
    );
  }

  static pw.Widget _buildLogoWidget(UserProfile? profile) {
    if (profile?.logoPath != null && profile!.logoPath!.isNotEmpty) {
      try {
        final logoFile = File(profile.logoPath!);
        if (logoFile.existsSync()) {
          final logoBytes = logoFile.readAsBytesSync();
          return pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(30),
              border: pw.Border.all(color: primaryColor, width: 2),
            ),
            child: pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 56,
                height: 56,
                fit: pw.BoxFit.cover,
              ),
            ),
          );
        }
      } catch (e) {
        // If there's an error loading the logo, fall back to placeholder
      }
    }
    
    // Fallback placeholder
    return pw.Container(
      width: 60,
      height: 60,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(30),
        border: pw.Border.all(color: PdfColors.grey400, width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          'الشعار',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildProfessionalFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            'تم إنشاؤه بواسطة تطبيق إدارة الحسابات',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildProfileHeader(UserProfile profile) {
    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: primaryColor.shade(0.3)),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              (profile.businessName?.isNotEmpty == true) ? profile.businessName! : 'غير محدد',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              (profile.fullName?.isNotEmpty == true) ? profile.fullName! : 'غير محدد',
              style: const pw.TextStyle(fontSize: 14),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              'النشاط التجاري: ${(profile.tradingActivity?.isNotEmpty == true) ? profile.tradingActivity! : "غير محدد"}',
              style: const pw.TextStyle(fontSize: 12),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'الهاتف: ${(profile.phone?.isNotEmpty == true) ? profile.phone! : "غير محدد"}',
                      style: const pw.TextStyle(fontSize: 10),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.Expanded(
                  child: pw.Text(
                    'العنوان: ${(profile.address?.isNotEmpty == true) ? profile.address! : "غير محدد"}',
                    style: const pw.TextStyle(fontSize: 10),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  static Future<void> _generatePdfWithPagination({
    required String title,
    required List<pw.Widget> headerContent,
    required List<String> tableHeaders,
    required List<List<String>> tableData,
  }) async {

    final arabicFont = await _arabicFontFuture;
    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
      italic: arabicFont,
      boldItalic: arabicFont,
    );

    final userProfile = await _getUserProfile();
    const int maxRowsPerPage = 15;
    final primaryColor = PdfColor.fromInt(AppTheme.primaryColor.value);

    // Always generate a single PDF with multiple pages if needed
    await _generateSinglePagePdf(
      title: title,
      headerContent: headerContent,
      tableHeaders: tableHeaders,
      tableData: tableData,
      theme: theme,
      userProfile: userProfile,
      primaryColor: primaryColor,
    );
  }

  static Future<void> _generateSinglePagePdf({
    required String title,
    required List<pw.Widget> headerContent,
    required List<String> tableHeaders,
    required List<List<String>> tableData,
    required pw.ThemeData theme,
    required UserProfile? userProfile,
    required PdfColor primaryColor,
  }) async {
    final pdf = pw.Document();
    const int maxRowsPerPage = 25; // Safe limit for single PDF
    
    if (tableData.length <= maxRowsPerPage) {
      // Single page approach
      final table = tableData.isNotEmpty 
          ? pw.Table.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(8),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey50,
              ),
            )
          : pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Text(
                'لا توجد بيانات لعرضها',
                style: const pw.TextStyle(fontSize: 14),
                textDirection: pw.TextDirection.rtl,
              ),
            );

      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
          build: (context) => pw.Column(
            children: [
              _buildProfessionalHeader(title, userProfile),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...headerContent,
                      if (headerContent.isNotEmpty) pw.SizedBox(height: 15),
                      pw.Expanded(child: table),
                    ],
                  ),
                ),
              ),
              _buildProfessionalFooter(context),
            ],
          ),
        ),
      );
    } else {
      // Multi-page approach with safe pagination
      const int firstPageRows = 13;
      const int subsequentPageRows = 20;
      
      // First page
      final firstPageData = tableData.take(firstPageRows).toList();
      final firstPageTable = firstPageData.isNotEmpty
          ? pw.Table.fromTextArray(
              headers: tableHeaders,
              data: firstPageData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(8),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey50,
              ),
            )
          : pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Text(
                'لا توجد بيانات لعرضها',
                style: const pw.TextStyle(fontSize: 14),
                textDirection: pw.TextDirection.rtl,
              ),
            );

      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
          build: (context) => pw.Column(
            children: [
              _buildProfessionalHeader(title, userProfile),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...headerContent,
                      if (headerContent.isNotEmpty) pw.SizedBox(height: 15),
                      pw.Expanded(child: firstPageTable),
                    ],
                  ),
                ),
              ),
              _buildProfessionalFooter(context),
            ],
          ),
        ),
      );

      // Subsequent pages
      final remainingData = tableData.skip(firstPageRows).toList();
      final totalRemainingPages = (remainingData.length / subsequentPageRows).ceil();
      
      for (int pageIndex = 0; pageIndex < totalRemainingPages; pageIndex++) {
        final startIndex = pageIndex * subsequentPageRows;
        final endIndex = (startIndex + subsequentPageRows).clamp(0, remainingData.length);
        final pageData = remainingData.sublist(startIndex, endIndex);
        
        final table = pw.Table.fromTextArray(
          headers: tableHeaders,
          data: pageData,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: primaryColor,
          ),
          cellStyle: const pw.TextStyle(fontSize: 11),
          cellAlignment: pw.Alignment.center,
          cellPadding: const pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          oddRowDecoration: const pw.BoxDecoration(
            color: PdfColors.grey50,
          ),
        );

        final pageTitle = '$title (صفحة ${pageIndex + 2} من ${totalRemainingPages + 1})';
        
        pdf.addPage(
          pw.Page(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
            build: (context) => pw.Column(
              children: [
                _buildProfessionalHeader(pageTitle, userProfile),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(child: table),
                      ],
                    ),
                  ),
                ),
                _buildProfessionalFooter(context),
              ],
            ),
          ),
        );
      }
    }

    final bytes = await pdf.save();
    await _savePdfFile(bytes, title);
  }

  static Future<void> _generatePaginatedPdf(
    pw.Document pdf,
    pw.ThemeData theme,
    String title,
    UserProfile? userProfile,
    List<pw.Widget> content,
  ) async {
    // Split content into smaller chunks
    const int maxRowsPerPage = 25; // Adjust based on testing
    
    for (int i = 0; i < content.length; i++) {
      final widget = content[i];
      
      if (widget is pw.Table) {
        // Handle large tables by splitting them
        final table = widget;
        final headers = _extractTableHeaders(table);
        final data = _extractTableData(table);
        
        if (data.length > maxRowsPerPage) {
          // Split table into multiple pages
          for (int pageIndex = 0; pageIndex < (data.length / maxRowsPerPage).ceil(); pageIndex++) {
            final startIndex = pageIndex * maxRowsPerPage;
            final endIndex = (startIndex + maxRowsPerPage).clamp(0, data.length);
            final pageData = data.sublist(startIndex, endIndex);
            
            final pageContent = <pw.Widget>[
              if (pageIndex == 0) ...content.where((w) => w != widget),
              _createTableFromData(headers, pageData, table),
            ];
            
            pdf.addPage(
              pw.MultiPage(
                theme: theme,
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
                header: (context) => _buildProfessionalHeader(
                  pageIndex == 0 ? title : '$title (صفحة ${pageIndex + 1})',
                  userProfile,
                ),
                footer: (context) => _buildProfessionalFooter(context),
                maxPages: 50,
                build: (context) => [
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 10),
                        ...pageContent,
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          // Table is small enough, add normally
          pdf.addPage(
            pw.MultiPage(
              theme: theme,
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
              header: (context) => _buildProfessionalHeader(title, userProfile),
              footer: (context) => _buildProfessionalFooter(context),
              maxPages: 50,
              build: (context) => [
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      ...content,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  static List<String> _extractTableHeaders(pw.Table table) {
    // This is a simplified extraction - in practice, you might need to access table properties
    // For now, return default headers that match the report structure
    return ['الحساب', 'الفئة', 'لك', 'عليك', 'الصافي'];
  }

  static List<List<String>> _extractTableData(pw.Table table) {
    // This is a simplified extraction - in practice, you might need to access table data
    // For now, return empty list - this will be handled by the calling code
    return [];
  }

  static pw.Table _createTableFromData(
    List<String> headers,
    List<List<String>> data,
    pw.Table originalTable,
  ) {
    final primaryColor = PdfColor.fromHex('#2196F3');
    
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 11),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(8),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey50,
      ),
    );
  }

  static Future<void> _savePdfFile(List<int> bytes, String title) async {
    Directory dir;
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      dir = Directory('/storage/emulated/0/Download/FinanceApp/report');
    } else {
      final downloads = await getDownloadsDirectory();
      dir = Directory('${downloads?.path ?? (await getTemporaryDirectory()).path}/FinanceApp/report');
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final slug = title
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final existingIndexes = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path) == '.pdf')
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((name) => name.startsWith('$slug-'))
        .map((name) {
          final rest = name.substring(slug.length + 1);
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
