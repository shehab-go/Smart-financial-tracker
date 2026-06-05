import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import '../db/database_helper.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ReportService {
  static final Future<pw.Font> _arabicFontFuture = _loadArabicFont();
  static Uint8List? _cachedAppIconBytes;

  static Future<void> _ensureAssetsLoaded() async {
    if (_cachedAppIconBytes == null) {
      try {
        final data = await rootBundle.load('assets/images/app_icon.png');
        _cachedAppIconBytes = data.buffer.asUint8List();
      } catch (e) {
        debugPrint('Error loading app icon asset: $e');
      }
    }
  }
  
  // Premium Design System Colors
  static final PdfColor primaryColor = PdfColor.fromInt(AppTheme.primaryColor.value);
  static final PdfColor slate800 = PdfColor.fromInt(0xFF1E293B);
  static final PdfColor slate500 = PdfColor.fromInt(0xFF64748B);
  static final PdfColor slate200 = PdfColor.fromInt(0xFFE2E8F0);
  static final PdfColor slate50 = PdfColor.fromInt(0xFFF8FAFC);
  static final PdfColor successGreen = PdfColor.fromInt(0xFF10B981);
  static final PdfColor errorRed = PdfColor.fromInt(0xFFEF4444);

  static String _getInitials(String text) {
    if (text.isEmpty) return '';
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0] : '';
    } else if (words.length >= 2) {
      final first = words[0].isNotEmpty ? words[0][0] : '';
      final second = words[1].isNotEmpty ? words[1][0] : '';
      return '$first$second';
    }
    return '';
  }

  // Bento Card Layout Helper
  static pw.Widget buildCard({
    required List<pw.Widget> children,
    PdfColor? color,
    pw.EdgeInsetsGeometry? padding,
    pw.CrossAxisAlignment crossAxisAlignment = pw.CrossAxisAlignment.start,
  }) {
    return pw.Container(
      padding: padding ?? const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color ?? slate50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: slate200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }

  static pw.Widget buildInfoRow(
    String label,
    String value, {
    bool? isNegative,
    bool? isPositive,
    pw.TextStyle? labelStyle,
    pw.TextStyle? valueStyle,
  }) {
    final defaultLabelStyle = pw.TextStyle(fontSize: 10, color: slate500);
    final defaultValColor = (isNegative == true)
        ? errorRed
        : (isPositive == true)
            ? successGreen
            : slate800;
    final defaultValueStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: defaultValColor,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            value,
            style: valueStyle ?? defaultValueStyle,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            label,
            style: labelStyle ?? defaultLabelStyle,
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  static pw.Widget buildInfoItem(
    String label,
    String value, {
    bool? isNegative,
    bool? isPositive,
    pw.TextStyle? labelStyle,
    pw.TextStyle? valueStyle,
  }) {
    final defaultLabelStyle = pw.TextStyle(fontSize: 9, color: slate500, height: 1.4);
    final defaultValColor = (isNegative == true)
        ? errorRed
        : (isPositive == true)
            ? successGreen
            : slate800;
    final defaultValueStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: defaultValColor,
      height: 1.4,
    );

    final resolvedLabelStyle = labelStyle != null
        ? labelStyle.copyWith(height: labelStyle.height ?? 1.4)
        : defaultLabelStyle;

    final resolvedValueStyle = valueStyle != null
        ? valueStyle.copyWith(height: valueStyle.height ?? 1.4)
        : defaultValueStyle;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: resolvedLabelStyle,
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: resolvedValueStyle,
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget buildValueBlock(
    String label,
    String amount,
    String currency, {
    bool? isNegative,
    bool? isPositive,
  }) {
    final defaultValColor = (isNegative == true)
        ? errorRed
        : (isPositive == true)
            ? successGreen
            : slate800;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: slate200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: slate500, height: 1.4),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                ' $currency',
                style: pw.TextStyle(fontSize: 10, color: slate500, height: 1.4),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                amount,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: defaultValColor,
                  height: 1.4,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 15, bottom: 8),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: slate800,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

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
    await _ensureAssetsLoaded();
    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
      italic: arabicFont,
      boldItalic: arabicFont,
    );

    final userProfile = await _getUserProfile();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
        header: (context) => _buildProfessionalHeader(title, userProfile),
        footer: (context) => _buildProfessionalFooter(context),
        maxPages: 100,
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

    final bytes = await pdf.save();
    await _savePdfFile(bytes, title);
  }

  static pw.Widget _buildProfessionalHeader(String title, UserProfile? profile) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: slate200, width: 1)),
      ),
      child: pw.Row(
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
                  style: pw.TextStyle(fontSize: 9, color: slate500, height: 1.4),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'الوقت: ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, color: slate500, height: 1.4),
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
                  (profile?.businessName?.isNotEmpty == true)
                      ? profile!.businessName!
                      : (profile?.fullName?.isNotEmpty == true)
                          ? profile!.fullName!
                          : 'حسابات يومية',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: slate800, height: 1.4),
                  textDirection: pw.TextDirection.rtl,
                ),
                if (profile?.fullName?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    profile!.fullName!,
                    style: pw.TextStyle(fontSize: 10, color: slate500, height: 1.4),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ),
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
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: primaryColor, width: 1.5),
            ),
            child: pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 47,
                height: 47,
                fit: pw.BoxFit.cover,
              ),
            ),
          );
        }
      } catch (e) {
        // If there's an error loading the logo, fall back
      }
    }
    
    // Fallback to app icon asset if available
    if (_cachedAppIconBytes != null) {
      return pw.Container(
        width: 50,
        height: 50,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: primaryColor, width: 1.5),
        ),
        child: pw.ClipOval(
          child: pw.Image(
            pw.MemoryImage(_cachedAppIconBytes!),
            width: 47,
            height: 47,
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }
    
    // Fallback placeholder
    final nameForInitials = (profile?.businessName?.isNotEmpty == true)
        ? profile!.businessName!
        : (profile?.fullName?.isNotEmpty == true)
            ? profile!.fullName!
            : 'حسابات يومية';
    final initials = _getInitials(nameForInitials);

    return pw.Container(
      width: 50,
      height: 50,
      decoration: pw.BoxDecoration(
        color: slate50,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: primaryColor, width: 1.5),
      ),
      child: pw.Center(
        child: pw.Text(
          initials,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
    );
  }

  static pw.Widget _buildProfessionalFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 15),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: slate200, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: slate500),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            'تم الإنشاء بواسطة تطبيق حسابات يومية',
            style: pw.TextStyle(fontSize: 8, color: slate500),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
  static List<pw.Widget> _buildProfileHeader(UserProfile profile) {
    return [
      buildCard(
        children: [
          pw.Text(
            (profile.businessName?.isNotEmpty == true)
                ? profile.businessName!
                : (profile.fullName.isNotEmpty == true)
                    ? profile.fullName
                    : 'حسابات يومية',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: slate800, height: 1.4),
            textDirection: pw.TextDirection.rtl,
          ),
          if (profile.fullName?.isNotEmpty == true) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              profile.fullName!,
              style: pw.TextStyle(fontSize: 12, color: slate800, height: 1.4),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Text(
            'النشاط التجاري: ${(profile.tradingActivity?.isNotEmpty == true) ? profile.tradingActivity! : "غير محدد"}',
            style: pw.TextStyle(fontSize: 10, color: slate500, height: 1.4),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الهاتف: ${(profile.phone?.isNotEmpty == true) ? profile.phone! : "غير محدد"}',
                style: pw.TextStyle(fontSize: 9, color: slate500, height: 1.4),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'العنوان: ${(profile.address?.isNotEmpty == true) ? profile.address! : "غير محدد"}',
                style: pw.TextStyle(fontSize: 9, color: slate500, height: 1.4),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
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
    await _ensureAssetsLoaded();
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
    final orderedTableData = tableData.reversed
        .map((row) => List<String>.from(row))
        .toList();

    final tableWidgets = <pw.Widget>[];
    if (orderedTableData.isEmpty) {
      tableWidgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Text(
            'لا توجد معاملات لعرضها في هذا الجدول',
            style: const pw.TextStyle(fontSize: 14),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      );
    } else {
      const rowsPerChunk = 10;
      for (int i = 0; i < orderedTableData.length; i += rowsPerChunk) {
        final endIndex = (i + rowsPerChunk) > orderedTableData.length
            ? orderedTableData.length
            : i + rowsPerChunk;
        final chunk = orderedTableData.sublist(i, endIndex);
        tableWidgets.add(
          pw.Table.fromTextArray(
            headers: tableHeaders,
            data: chunk,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: primaryColor,
            ),
            cellStyle: pw.TextStyle(fontSize: 9, color: slate800),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: slate200, width: 0.5),
              bottom: pw.BorderSide(color: slate200, width: 0.5),
            ),
            oddRowDecoration: pw.BoxDecoration(
              color: slate50,
            ),
          ),
        );
        if (endIndex < orderedTableData.length) {
          tableWidgets.add(pw.SizedBox(height: 12));
        }
      }
    }

    const tablesPerSection = 4;
    final sectionedContent = <List<pw.Widget>>[];

    var currentSection = <pw.Widget>[];
    int tablesInSection = 0;
    for (final widget in tableWidgets) {
      currentSection.add(widget);
      if (widget is pw.Table) {
        tablesInSection++;
      }
      if (tablesInSection >= tablesPerSection) {
        sectionedContent.add(currentSection);
        currentSection = <pw.Widget>[];
        tablesInSection = 0;
      }
    }
    if (currentSection.isNotEmpty) {
      sectionedContent.add(currentSection);
    }

    if (sectionedContent.isEmpty) {
      sectionedContent.add([]);
    }

    for (int i = 0; i < sectionedContent.length; i++) {
      final isFirstSection = i == 0;
      final bodyContent = <pw.Widget>[
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (isFirstSection) ...headerContent,
              if (isFirstSection && headerContent.isNotEmpty)
                pw.SizedBox(height: 15),
              ...sectionedContent[i],
            ],
          ),
        ),
      ];

      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0.5 * PdfPageFormat.cm),
          header: (context) => _buildProfessionalHeader(
            _formatPaginatedTitle(title, context.pageNumber, context.pagesCount),
            userProfile,
          ),
          footer: (context) => _buildProfessionalFooter(context),
          maxPages: 250,
          build: (context) => bodyContent,
        ),
      );
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
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primaryColor,
      ),
      cellStyle: pw.TextStyle(fontSize: 9, color: slate800),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: slate200, width: 0.5),
        bottom: pw.BorderSide(color: slate200, width: 0.5),
      ),
      oddRowDecoration: pw.BoxDecoration(
        color: slate50,
      ),
    );
  }

  static String _formatPaginatedTitle(String baseTitle, int currentPage, int totalPages) {
    if (totalPages <= 1) return baseTitle;
    return '$baseTitle (الصفحة $currentPage من $totalPages)';
  }

  static Future<void> _savePdfFile(List<int> bytes, String title) async {
    Directory dir;
    if (Platform.isAndroid) {
      // Use app-scoped storage to comply with Play policies (no MANAGE_EXTERNAL_STORAGE).
      final externalDir = await getExternalStorageDirectory();
      final basePath = externalDir?.path ?? (await getTemporaryDirectory()).path;
      dir = Directory(p.join(basePath, 'FinanceApp', 'report'));
    } else {
      final downloads = await getDownloadsDirectory();
      final basePath = downloads?.path ?? (await getApplicationDocumentsDirectory()).path;
      dir = Directory(p.join(basePath, 'FinanceApp', 'report'));
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Create more descriptive file names based on report type
    String baseFileName;
    if (title.contains('تقرير حساب ')) {
      // Single account report: "Account_[AccountName]"
      final accountName = title.replaceFirst('تقرير حساب ', '').trim();
      baseFileName = 'Account_${accountName.replaceAll(RegExp(r'[^A-Za-z0-9_\-\u0600-\u06FF]'), '_')}';
    } else if (title.contains('تقرير فئة ')) {
      // Single category report: "Category_[CategoryName]"
      final categoryName = title.replaceFirst('تقرير فئة ', '').trim();
      baseFileName = 'Category_${categoryName.replaceAll(RegExp(r'[^A-Za-z0-9_\-\u0600-\u06FF]'), '_')}';
    } else if (title.contains('تقرير جميع الحسابات')) {
      // All accounts report: "AllAccounts_Report"
      baseFileName = 'AllAccounts_Report';
    } else if (title.contains('معاملات مختارة')) {
      // Selected transactions: "SelectedTransactions_[AccountName]"
      final accountName = title.replaceFirst('معاملات مختارة - ', '').trim();
      baseFileName = 'SelectedTransactions_${accountName.replaceAll(RegExp(r'[^A-Za-z0-9_\-\u0600-\u06FF]'), '_')}';
    } else if (title.contains('حسابات مختارة')) {
      // Selected accounts: "SelectedAccounts"
      baseFileName = 'SelectedAccounts';
    } else {
      // Fallback to original logic
      baseFileName = title
          .replaceAll(RegExp(r'[^A-Za-z0-9_\-\u0600-\u06FF]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
    }

    // Clean up the base filename
    baseFileName = baseFileName
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final reportFileList = await dir.list().toList();
    final existingIndexes = reportFileList
        .whereType<File>()
        .where((f) => p.extension(f.path) == '.pdf')
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((name) => name.contains(baseFileName))
        .map((name) {
          // Extract index from filename pattern: [index]_[baseFileName]_[date].pdf
          final parts = name.split('_');
          if (parts.isNotEmpty) {
            return int.tryParse(parts[0]) ?? -1;
          }
          return -1;
        })
        .where((n) => n >= 0)
        .toList();
    final nextIndex = existingIndexes.isEmpty ? 0 : (existingIndexes.reduce((a, b) => a > b ? a : b) + 1);

    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final fileName = '${nextIndex}_${baseFileName}_$dateStr.pdf';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes);
    debugPrint('PDF saved to: ${file.path}');
    final result = await OpenFile.open(file.path);
    debugPrint('OpenFile result: ${result.type}');
  }

  static Future<pw.Font> _loadArabicFont() async {
    final data = await rootBundle.load('assets/fonts/ArbFONTS-IBMPlexArabic-Text.ttf');
    return pw.Font.ttf(data);
  }
}
