import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:intl/intl.dart' hide TextDirection;

import 'package:debit_credit_app/core/db/database_helper.dart';

import 'package:debit_credit_app/core/models/income_balance.dart';

import 'package:debit_credit_app/core/models/income_resource.dart';

import 'package:debit_credit_app/core/theme/app_theme.dart';

import 'package:debit_credit_app/core/widgets/app_drawer.dart';

import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';

import 'package:debit_credit_app/features/currencies/presentation/widgets/local_currency_picker.dart';

import 'package:debit_credit_app/features/balances/application/reports/all_income_balances_report_generator.dart';

import 'package:debit_credit_app/features/balances/application/reports/all_income_resources_report_generator.dart';

import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/events/financial_events.dart';
import 'dart:async';



enum IncomeSection {

  resources,

  balances,

}



class IncomeBalancesScreen extends StatefulWidget {

  final Function(bool)? onDrawerChanged;



  const IncomeBalancesScreen({super.key, this.onDrawerChanged});



  @override

  State<IncomeBalancesScreen> createState() => _IncomeBalancesScreenState();

}



class _IncomeBalancesScreenState extends State<IncomeBalancesScreen> {

  final DatabaseHelper _db = DatabaseHelper();

  final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'ar');

  List<IncomeResourceModel> _resources = [];

  List<IncomeBalanceModel> _balances = [];

  Map<int, List<IncomeBalanceModel>> _balancesByResource = {};

  Map<int, double> _currentBalanceAmounts = {};

  bool _isLoading = true;

  bool _isDrawerOpen = false;

  IncomeSection _selectedSection = IncomeSection.resources;

  late final PageController _pageController;
  StreamSubscription<FinancialEvent>? _financialEventSubscription;



  @override

  void initState() {

    super.initState();

    _pageController = PageController(

      initialPage: _selectedSection == IncomeSection.resources ? 0 : 1,

    );

    _loadBalances();

    _financialEventSubscription = FinancialEventBus().events.listen((event) {
      if (event.type == FinancialEventType.balanceUpdated ||
          event.type == FinancialEventType.radarClassified ||
          event.type == FinancialEventType.expenseAdded ||
          event.type == FinancialEventType.expenseDeleted) {
        _loadBalances();
      }
    });

  }



  @override

  void dispose() {

    _pageController.dispose();
    _financialEventSubscription?.cancel();

    super.dispose();

  }



  Future<void> _loadBalances() async {

    try {

      final resources = await _db.getIncomeResources();

      final balances = await _db.getIncomeBalances();

      final currentAmounts = await _db.getIncomeBalanceCurrentAmounts();

      if (!mounted) return;



      final Map<int, List<IncomeBalanceModel>> grouped = {};

      for (final resource in resources) {

        if (resource.id != null) {

          grouped[resource.id!] =

              balances.where((b) => b.resourceId == resource.id).toList();

        }

      }



      setState(() {

        _resources = resources;

        _balances = balances;

        _balancesByResource = grouped;

        _currentBalanceAmounts = currentAmounts;

        _isLoading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _isLoading = false;

      });

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('خطأ في تحميل الأرصدة: $e'),

          backgroundColor: AppTheme.errorColor,

        ),

      );

    }

  }



  Future<Map<String, List<Map<String, Object?>>>> _getBalanceAllocationsDetails(

      int balanceId) async {

    final transactions =

        await _db.getBalanceTransactionAllocationsWithDetails(balanceId);

    final expenses =

        await _db.getBalanceExpenseAllocationsWithDetails(balanceId);

    return {

      'transactions': transactions,

      'expenses': expenses,

    };

  }



  Future<Map<String, List<Map<String, Object?>>>> _getResourceAllocationsDetails(

      int resourceId) async {

    final transactions =

        await _db.getResourceTransactionAllocationsWithDetails(resourceId);

    final expenses =

        await _db.getResourceExpenseAllocationsWithDetails(resourceId);

    return {

      'transactions': transactions,

      'expenses': expenses,

    };

  }



  String _formatDateFromMillis(int? millis) {

    if (millis == null) return '';

    final dt = DateTime.fromMillisecondsSinceEpoch(millis);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final year = dt.year.toString().padLeft(4, '0');

    final month = twoDigits(dt.month);

    final day = twoDigits(dt.day);

    return '$year-$month-$day';

  }



  Widget _buildTransactionAllocationItem(Map<String, Object?> row) {

    final accountName = (row['accountName'] ?? '') as String;

    final balanceNameValue = row['balanceName'];

    final balanceName =

        balanceNameValue == null ? '' : balanceNameValue.toString();

    final transactionType = (row['transactionType'] ?? '') as String;

    final allocated =

        (row['allocatedAmount'] as num?)?.toDouble() ?? 0.0;

    final transactionAmount =

        (row['transactionAmount'] as num?)?.toDouble() ?? 0.0;

    final dateMillis = row['transactionDate'] as int?;

    final dateText = _formatDateFromMillis(dateMillis);

    final descriptionValue = row['transactionDescription'];

    final description =

        descriptionValue == null ? '' : descriptionValue.toString();



    return Container(

      margin: const EdgeInsets.symmetric(vertical: 4),

      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(

        color: Colors.grey.shade50,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(

          color: Colors.grey.shade300,

        ),

      ),

      child: Row(

        children: [

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  accountName.isEmpty ? 'معاملة' : accountName,

                  style: const TextStyle(

                    fontSize: 13,

                    color: AppTheme.textPrimary,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 2),

                if (dateText.isNotEmpty)

                  Text(

                    dateText,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textSecondary,

                    ),

                  ),

                if (description.isNotEmpty) ...[

                  const SizedBox(height: 2),

                  Text(

                    description,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textSecondary,

                    ),

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                  ),

                ],

                if (balanceName.isNotEmpty) ...[

                  const SizedBox(height: 2),

                  Text(

                    'الرصيد: $balanceName',

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textSecondary,

                    ),

                  ),

                ],

                const SizedBox(height: 2),

                Text(

                  transactionType == 'credit'

                      ? 'معاملة دائنة (لك)'

                      : 'معاملة مدينة (عليك)',

                  style: const TextStyle(

                    fontSize: 11,

                    color: AppTheme.textSecondary,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(width: 8),

          Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(

                _amountFormat.format(allocated),

                style: const TextStyle(

                  fontSize: 13,

                  color: AppTheme.textPrimary,

                  fontWeight: FontWeight.w600,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                'من إجمالي ${_amountFormat.format(transactionAmount)}',

                style: const TextStyle(

                  fontSize: 11,

                  color: AppTheme.textSecondary,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Future<void> _showResourceDetailsDialog({

    required IncomeResourceModel resource,

  }) async {

    if (resource.id == null) return;



    await showDialog<void>(

      context: context,

      builder: (dialogContext) {

        return Dialog(

          insetPadding: const EdgeInsets.all(16),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(24),

          ),

          child: Directionality(

            textDirection: TextDirection.rtl,

            child: Container(

              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.05),

                    blurRadius: 10,

                    offset: const Offset(0, 2),

                  ),

                ],

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  // Header

                  Container(

                    padding: const EdgeInsets.symmetric(

                        horizontal: 20, vertical: 16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        topLeft: Radius.circular(24),

                        topRight: Radius.circular(24),

                      ),

                    ),

                    child: Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: AppTheme.primaryColor.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: const Icon(

                            Icons.analytics_outlined,

                            color: AppTheme.primaryColor,

                            size: 18,

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Text(

                                resource.name,

                                style: const TextStyle(

                                  color: AppTheme.textPrimary,

                                  fontWeight: FontWeight.bold,

                                  fontSize: 16,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                              if (resource.description != null &&

                                  resource.description!.isNotEmpty)

                                Padding(

                                  padding:

                                      const EdgeInsets.only(top: 2.0),

                                  child: Text(

                                    resource.description!,

                                    style: const TextStyle(

                                      fontSize: 12,

                                      color: AppTheme.textSecondary,

                                      fontFamily: 'ArbFONTSIBMPlexArabicText',

                                    ),

                                  ),

                                ),

                            ],

                          ),

                        ),

                        IconButton(

                          onPressed: () {

                            HapticFeedback.lightImpact();

                            Navigator.of(dialogContext).pop();

                          },

                          icon: Icon(

                            Icons.close,

                            color: AppTheme.textSecondary,

                            size: 18,

                          ),

                        ),

                      ],

                    ),

                  ),

                  const Divider(height: 1, color: AppTheme.dividerColor),

                  // Content

                  Flexible(

                    child: Padding(

                      padding: const EdgeInsets.all(20),

                      child: SizedBox(

                        width: double.maxFinite,

                        child: FutureBuilder<

                            Map<String, List<Map<String, Object?>>>>(

                          future:

                              _getResourceAllocationsDetails(resource.id!),

                          builder: (context, snapshot) {

                            if (snapshot.connectionState ==

                                ConnectionState.waiting) {

                              return const Center(

                                child: CircularProgressIndicator(),

                              );

                            }

                            if (snapshot.hasError) {

                              return Text(

                                'حدث خطأ أثناء تحميل التفاصيل: ${snapshot.error}',

                                style: const TextStyle(

                                  fontSize: 13,

                                  color: AppTheme.errorColor,

                                ),

                              );

                            }



                            final data = snapshot.data ?? {

                              'transactions': <Map<String, Object?>>[],

                              'expenses': <Map<String, Object?>>[],

                            };



                            final txAlloc = List<Map<String, Object?>>.from(

                                data['transactions']!);

                            final expAlloc = List<Map<String, Object?>>.from(

                                data['expenses']!);



                            final creditAlloc = txAlloc

                                .where((row) =>

                                    row['transactionType'] == 'credit')

                                .toList();

                            final debitAlloc = txAlloc

                                .where(

                                    (row) => row['transactionType'] == 'debit')

                                .toList();



                            if (creditAlloc.isEmpty &&

                                debitAlloc.isEmpty &&

                                expAlloc.isEmpty) {

                              return const Text(

                                'لا توجد عمليات مرتبطة بهذا المصدر حتى الآن',

                                style: TextStyle(

                                  fontSize: 13,

                                  color: AppTheme.textSecondary,

                                ),

                              );

                            }



                            return SingleChildScrollView(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                mainAxisSize: MainAxisSize.min,

                                children: [

                                  const Text(

                                    'المعاملات الدائنة (لك)',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (creditAlloc.isEmpty)

                                    const Text(

                                      'لا توجد معاملات دائنة لهذا المصدر',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: creditAlloc

                                          .map(

                                              _buildTransactionAllocationItem)

                                          .toList(),

                                    ),

                                  const SizedBox(height: 12),

                                  const Text(

                                    'المعاملات المدينة (عليك)',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (debitAlloc.isEmpty)

                                    const Text(

                                      'لا توجد معاملات مدينة لهذا المصدر',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: debitAlloc

                                          .map(

                                              _buildTransactionAllocationItem)

                                          .toList(),

                                    ),

                                  const SizedBox(height: 12),

                                  const Text(

                                    'المصروفات',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (expAlloc.isEmpty)

                                    const Text(

                                      'لا توجد مصروفات مخصصة لهذا المصدر',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: expAlloc

                                          .map(_buildExpenseAllocationItem)

                                          .toList(),

                                    ),

                                ],

                              ),

                            );

                          },

                        ),

                      ),

                    ),

                  ),

                  // Actions

                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        bottomLeft: Radius.circular(12),

                        bottomRight: Radius.circular(12),

                      ),

                    ),

                    child: Row(

                      children: [

                        Expanded(

                          child: TextButton(

                            onPressed: () =>

                                Navigator.of(dialogContext).pop(),

                            style: TextButton.styleFrom(

                              backgroundColor: Colors.grey.shade100,

                              foregroundColor: AppTheme.textSecondary,

                              padding: const EdgeInsets.symmetric(

                                vertical: 14,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(8),

                              ),

                            ),

                            child: const Text(

                              'إغلاق',

                              style: TextStyle(

                                fontSize: 14,

                                fontWeight: FontWeight.w500,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

          ),

        );

      },

    );

  }



  Widget _buildExpenseAllocationItem(Map<String, Object?> row) {

    final expenseName = (row['expenseName'] ?? '') as String;

    final balanceNameValue = row['balanceName'];

    final balanceName =

        balanceNameValue == null ? '' : balanceNameValue.toString();

    final allocated =

        (row['allocatedAmount'] as num?)?.toDouble() ?? 0.0;

    final expenseAmount =

        (row['expenseAmount'] as num?)?.toDouble() ?? 0.0;

    final dateMillis = row['expenseDate'] as int?;

    final dateText = _formatDateFromMillis(dateMillis);

    final detailValue = row['expenseDetail'];

    final detail = detailValue == null ? '' : detailValue.toString();



    return Container(

      margin: const EdgeInsets.symmetric(vertical: 4),

      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(

        color: Colors.grey.shade50,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(

          color: Colors.grey.shade300,

        ),

      ),

      child: Row(

        children: [

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  expenseName.isEmpty ? 'مصروف' : expenseName,

                  style: const TextStyle(

                    fontSize: 13,

                    color: AppTheme.textPrimary,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 2),

                if (dateText.isNotEmpty)

                  Text(

                    dateText,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textSecondary,

                    ),

                  ),

                if (detail.isNotEmpty) ...[

                  const SizedBox(height: 2),

                  Text(

                    detail,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textSecondary,

                    ),

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                  ),

                ],

              ],

            ),

          ),

          const SizedBox(width: 8),

          Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(

                _amountFormat.format(allocated),

                style: const TextStyle(

                  fontSize: 13,

                  color: AppTheme.textPrimary,

                  fontWeight: FontWeight.w600,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                'من إجمالي ${_amountFormat.format(expenseAmount)}',

                style: const TextStyle(

                  fontSize: 11,

                  color: AppTheme.textSecondary,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Future<void> _showBalanceDetailsDialog({

    required IncomeResourceModel resource,

    required IncomeBalanceModel balance,

  }) async {

    if (balance.id == null) return;



    await showDialog<void>(

      context: context,

      builder: (dialogContext) {

        return Dialog(

          insetPadding: const EdgeInsets.all(16),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(24),

          ),

          child: Directionality(

            textDirection: TextDirection.rtl,

            child: Container(

              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.05),

                    blurRadius: 10,

                    offset: const Offset(0, 2),

                  ),

                ],

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  // Header

                  Container(

                    padding: const EdgeInsets.symmetric(

                        horizontal: 20, vertical: 16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        topLeft: Radius.circular(24),

                        topRight: Radius.circular(24),

                      ),

                    ),

                    child: Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: AppTheme.primaryColor.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: const Icon(

                            Icons.account_balance_wallet_outlined,

                            color: AppTheme.primaryColor,

                            size: 18,

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                balance.name,

                                style: const TextStyle(

                                  fontSize: 16,

                                  color: AppTheme.textPrimary,

                                  fontWeight: FontWeight.bold,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                              const SizedBox(height: 2),

                              Text(

                                balance.currencyName,

                                style: const TextStyle(

                                  fontSize: 12,

                                  color: AppTheme.textSecondary,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                            ],

                          ),

                        ),

                        IconButton(

                          onPressed: () async {

                            HapticFeedback.lightImpact();

                            Navigator.of(dialogContext).pop();

                            await _showEditBalanceDialog(

                              resource: resource,

                              balance: balance,

                            );

                          },

                          icon: const Icon(

                            Icons.edit,

                            color: AppTheme.primaryColor,

                            size: 20,

                          ),

                          tooltip: 'تعديل الرصيد',

                        ),

                      ],

                    ),

                  ),

                  const Divider(height: 1, color: AppTheme.dividerColor),

                  // Content

                  Flexible(

                    child: Padding(

                      padding: const EdgeInsets.all(20),

                      child: SizedBox(

                        width: double.maxFinite,

                        child: FutureBuilder<

                            Map<String, List<Map<String, Object?>>>>(

                          future: _getBalanceAllocationsDetails(balance.id!),

                          builder: (context, snapshot) {

                            if (snapshot.connectionState ==

                                ConnectionState.waiting) {

                              return const Center(

                                child: CircularProgressIndicator(),

                              );

                            }

                            if (snapshot.hasError) {

                              return Text(

                                'حدث خطأ أثناء تحميل التفاصيل: ${snapshot.error}',

                                style: const TextStyle(

                                  fontSize: 13,

                                  color: AppTheme.errorColor,

                                ),

                              );

                            }



                            final data = snapshot.data ?? {

                              'transactions': <Map<String, Object?>>[],

                              'expenses': <Map<String, Object?>>[],

                            };



                            final txAlloc = List<Map<String, Object?>>.from(

                                data['transactions']!);

                            final expAlloc = List<Map<String, Object?>>.from(

                                data['expenses']!);



                            final creditAlloc = txAlloc

                                .where((row) =>

                                    row['transactionType'] == 'credit')

                                .toList();

                            final debitAlloc = txAlloc

                                .where(

                                    (row) => row['transactionType'] == 'debit')

                                .toList();



                            if (creditAlloc.isEmpty &&

                                debitAlloc.isEmpty &&

                                expAlloc.isEmpty) {

                              return const Text(

                                'لا توجد عمليات مرتبطة بهذا الرصيد حتى الآن',

                                style: TextStyle(

                                  fontSize: 13,

                                  color: AppTheme.textSecondary,

                                ),

                              );

                            }



                            return SingleChildScrollView(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                mainAxisSize: MainAxisSize.min,

                                children: [

                                  const Text(

                                    'المعاملات الدائنة (لك)',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (creditAlloc.isEmpty)

                                    const Text(

                                      'لا توجد معاملات دائنة لهذا الرصيد',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: creditAlloc

                                          .map(

                                              _buildTransactionAllocationItem)

                                          .toList(),

                                    ),

                                  const SizedBox(height: 12),

                                  const Text(

                                    'المعاملات المدينة (عليك)',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (debitAlloc.isEmpty)

                                    const Text(

                                      'لا توجد معاملات مدينة لهذا الرصيد',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: debitAlloc

                                          .map(

                                              _buildTransactionAllocationItem)

                                          .toList(),

                                    ),

                                  const SizedBox(height: 12),

                                  const Text(

                                    'المصروفات',

                                    style: TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  const SizedBox(height: 4),

                                  if (expAlloc.isEmpty)

                                    const Text(

                                      'لا توجد مصروفات مخصصة لهذا الرصيد',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                      ),

                                    )

                                  else

                                    Column(

                                      children: expAlloc

                                          .map(_buildExpenseAllocationItem)

                                          .toList(),

                                    ),

                                ],

                              ),

                            );

                          },

                        ),

                      ),

                    ),

                  ),

                  // Actions

                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        bottomLeft: Radius.circular(24),

                        bottomRight: Radius.circular(24),

                      ),

                    ),

                    child: Row(

                      children: [

                        Expanded(

                          child: TextButton(

                            onPressed: () {

                              HapticFeedback.lightImpact();

                              Navigator.of(dialogContext).pop();

                            },

                            style: TextButton.styleFrom(

                              backgroundColor: Colors.grey.shade100,

                              foregroundColor: AppTheme.textSecondary,

                              padding: const EdgeInsets.symmetric(

                                vertical: 14,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(14),

                              ),

                            ),

                            child: const Text(

                              'إغلاق',

                              style: TextStyle(

                                fontSize: 14,

                                fontWeight: FontWeight.bold,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

          ),

        );

      },

    );

  }



  Future<void> _showEditResourceDialog({IncomeResourceModel? resource}) async {

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: resource?.name ?? '');

    final descriptionController =

        TextEditingController(text: resource?.description ?? '');



    await showDialog<void>(

      context: context,

      builder: (dialogContext) {

        return Dialog(

          insetPadding: const EdgeInsets.all(16),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(24),

          ),

          child: Directionality(

            textDirection: TextDirection.rtl,

            child: Container(

              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.05),

                    blurRadius: 10,

                    offset: const Offset(0, 2),

                  ),

                ],

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  // Header

                  Container(

                    padding: const EdgeInsets.symmetric(

                        horizontal: 20, vertical: 16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        topLeft: Radius.circular(24),

                        topRight: Radius.circular(24),

                      ),

                    ),

                    child: Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: AppTheme.primaryColor.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: Icon(

                            resource == null

                                ? Icons.add

                                : Icons.edit_outlined,

                            color: AppTheme.primaryColor,

                            size: 18,

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Text(

                            resource == null

                                ? 'إضافة مصدر دخل جديد'

                                : 'تعديل مصدر الدخل',

                            style: const TextStyle(

                              color: AppTheme.textPrimary,

                              fontWeight: FontWeight.bold,

                              fontSize: 16,

                              fontFamily: 'ArbFONTSIBMPlexArabicText',

                            ),

                          ),

                        ),

                        IconButton(

                          onPressed: () {

                            HapticFeedback.lightImpact();

                            Navigator.of(dialogContext).pop();

                          },

                          icon: Icon(

                            Icons.close,

                            color: AppTheme.textSecondary,

                            size: 18,

                          ),

                        ),

                      ],

                    ),

                  ),

                  const Divider(height: 1, color: AppTheme.dividerColor),

                  // Content

                  Flexible(

                    child: SingleChildScrollView(

                      padding: const EdgeInsets.all(20),

                      child: Form(

                        key: formKey,

                        child: Column(

                          mainAxisSize: MainAxisSize.min,

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            TextFormField(

                              controller: nameController,

                              style: const TextStyle(

                                color: AppTheme.textPrimary,

                                fontSize: 14,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                              decoration: InputDecoration(

                                labelText: 'اسم المصدر *',

                                labelStyle: const TextStyle(

                                  color: AppTheme.textSecondary,

                                  fontSize: 13,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                                border: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: BorderSide(

                                    color: AppTheme.dividerColor.withOpacity(0.5),

                                  ),

                                ),

                                enabledBorder: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: BorderSide(

                                    color: AppTheme.dividerColor.withOpacity(0.5),

                                  ),

                                ),

                                focusedBorder: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: const BorderSide(

                                    color: AppTheme.primaryColor,

                                    width: 1.5,

                                  ),

                                ),

                                filled: true,

                                fillColor: AppTheme.surfaceColor,

                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                              ),

                              validator: (value) {

                                if (value == null || value.trim().isEmpty) {

                                  return 'يرجى إدخال اسم المصدر';

                                }

                                return null;

                              },

                            ),

                            const SizedBox(height: 16),

                            TextFormField(

                              controller: descriptionController,

                              maxLines: 2,

                              style: const TextStyle(

                                color: AppTheme.textPrimary,

                                fontSize: 14,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                              decoration: InputDecoration(

                                labelText: 'الوصف',

                                labelStyle: const TextStyle(

                                  color: AppTheme.textSecondary,

                                  fontSize: 13,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                                border: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: BorderSide(

                                    color: AppTheme.dividerColor.withOpacity(0.5),

                                  ),

                                ),

                                enabledBorder: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: BorderSide(

                                    color: AppTheme.dividerColor.withOpacity(0.5),

                                  ),

                                ),

                                focusedBorder: OutlineInputBorder(

                                  borderRadius: BorderRadius.circular(14),

                                  borderSide: const BorderSide(

                                    color: AppTheme.primaryColor,

                                    width: 1.5,

                                  ),

                                ),

                                filled: true,

                                fillColor: AppTheme.surfaceColor,

                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                  ),

                  // Actions

                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.only(

                        bottomLeft: Radius.circular(24),

                        bottomRight: Radius.circular(24),

                      ),

                    ),

                    child: Row(

                      children: [

                        Expanded(

                          child: TextButton(

                            onPressed: () {

                              HapticFeedback.lightImpact();

                              Navigator.of(dialogContext).pop();

                            },

                            style: TextButton.styleFrom(

                              backgroundColor: Colors.grey.shade100,

                              foregroundColor: AppTheme.textSecondary,

                              padding: const EdgeInsets.symmetric(

                                vertical: 14,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(14),

                              ),

                            ),

                            child: const Text(

                              'إلغاء',

                              style: TextStyle(

                                fontSize: 14,

                                fontWeight: FontWeight.bold,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                            ),

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: ElevatedButton(

                            onPressed: () async {

                              if (!formKey.currentState!.validate()) return;



                              final name = nameController.text.trim();

                              final desc =

                                  descriptionController.text.trim().isEmpty

                                      ? null

                                      : descriptionController.text.trim();



                              try {

                                if (resource == null) {

                                  final newResource = IncomeResourceModel(

                                    name: name,

                                    description: desc,

                                    createdDate: DateTime.now(),

                                  );

                                  await _db.insertIncomeResource(newResource);

                                } else {

                                  final updated = resource.copyWith(

                                    name: name,

                                    description: desc,

                                  );

                                  await _db.updateIncomeResource(updated);

                                }



                                if (mounted) {

                                  Navigator.of(dialogContext).pop();

                                  await _loadBalances();

                                  ScaffoldMessenger.of(context).showSnackBar(

                                    SnackBar(

                                      content: Text(resource == null

                                          ? 'تم إضافة المصدر بنجاح'

                                          : 'تم تحديث المصدر بنجاح'),

                                      backgroundColor: AppTheme.successColor,

                                    ),

                                  );

                                }

                              } catch (e) {

                                if (mounted) {

                                  ScaffoldMessenger.of(context)

                                      .showSnackBar(

                                    SnackBar(

                                      content: Text(

                                          'حدث خطأ أثناء حفظ المصدر: $e'),

                                      backgroundColor: AppTheme.errorColor,

                                    ),

                                  );

                                }

                              }

                            },

                            style: ElevatedButton.styleFrom(

                              backgroundColor: AppTheme.primaryColor,

                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(

                                vertical: 14,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(14),

                              ),

                              elevation: 0,

                            ),

                            child: const Text(

                              'حفظ',

                              style: TextStyle(

                                fontSize: 14,

                                fontWeight: FontWeight.bold,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

          ),

        );

      },

    );

  }



  Future<void> _confirmDeleteResource(IncomeResourceModel resource) async {

    final balances =

        resource.id != null ? _balancesByResource[resource.id!] ?? [] : [];

    if (balances.isNotEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('لا يمكن حذف المصدر لوجود أرصدة مرتبطة به'),

          backgroundColor: AppTheme.errorColor,

        ),

      );

      return;

    }



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => Directionality(

        textDirection: TextDirection.rtl,

        child: AlertDialog(

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(24),

          ),

          backgroundColor: Colors.white,

          title: const Text(

            'تأكيد الحذف',

            style: TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.bold,

              fontFamily: 'ArbFONTSIBMPlexArabicText',

              color: AppTheme.textPrimary,

            ),

          ),

          content: Text(

            'هل تريد حذف مصدر الدخل "${resource.name}"؟',

            style: const TextStyle(

              fontSize: 14,

              fontFamily: 'ArbFONTSIBMPlexArabicText',

              color: AppTheme.textSecondary,

            ),

          ),

          actions: [

            TextButton(

              onPressed: () {

                HapticFeedback.lightImpact();

                Navigator.of(context).pop(false);

              },

              style: TextButton.styleFrom(

                foregroundColor: AppTheme.textSecondary,

              ),

              child: const Text(

                'إلغاء',

                style: TextStyle(

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

            TextButton(

              onPressed: () {

                HapticFeedback.mediumImpact();

                Navigator.of(context).pop(true);

              },

              style: TextButton.styleFrom(

                foregroundColor: AppTheme.errorColor,

              ),

              child: const Text(

                'حذف',

                style: TextStyle(

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ],

        ),

      ),

    );



    if (confirmed == true && resource.id != null) {

      try {

        await _db.deleteIncomeResource(resource.id!);

        await _loadBalances();

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              content: Text('تم حذف المصدر بنجاح'),

              backgroundColor: AppTheme.successColor,

            ),

          );

        }

      } catch (e) {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text('تعذر حذف المصدر: $e'),

              backgroundColor: AppTheme.errorColor,

            ),

          );

        }

      }

    }

  }



  Future<void> _setDefaultBalance(int balanceId) async {

    try {

      final db = await _db.database;

      await db.update('income_balances', {'isDefault': 0});

      await db.update(

        'income_balances',

        {'isDefault': 1},

        where: 'id = ?',

        whereArgs: [balanceId],

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('خطأ في تعيين الرصيد الافتراضي: $e'),

          backgroundColor: AppTheme.errorColor,

        ),

      );

    }

  }



  Future<void> _showEditBalanceDialog({

    required IncomeResourceModel resource,

    IncomeBalanceModel? balance,

  }) async {

    try {

      if (resource.id == null) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('لا يمكن إنشاء رصيد لمصدر غير محفوظ'),

            backgroundColor: AppTheme.errorColor,

          ),

        );

        return;

      }

      // Favorites for quick selection in the picker

      final Set<String> favorites = await _db.getFavoriteCurrencies();



      final formKey = GlobalKey<FormState>();

      final nameController = TextEditingController(text: balance?.name ?? '');

      final amountController = TextEditingController(

        text: balance != null ? balance.initialAmount.toString() : '',

      );



      // Prefill currency: existing balance currency or global default for new

      String? selectedCurrency = balance?.currencyName;

      if (selectedCurrency == null) {

        selectedCurrency = await _db.getDefaultCurrencyName();

      }

      bool isDefault = balance?.isDefault ?? false;

      final int resourceId = balance?.resourceId ?? resource.id!;



      await showDialog<void>(

        context: context,

        builder: (dialogContext) {

          return Dialog(

            insetPadding: const EdgeInsets.all(16),

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(24),

            ),

            child: Directionality(

              textDirection: TextDirection.rtl,

              child: Container(

                constraints:

                    const BoxConstraints(maxWidth: 380, maxHeight: 520),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withOpacity(0.05),

                      blurRadius: 10,

                      offset: const Offset(0, 2),

                    ),

                  ],

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // Header

                    Container(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 20, vertical: 16),

                      decoration: const BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.only(

                          topLeft: Radius.circular(24),

                          topRight: Radius.circular(24),

                        ),

                      ),

                      child: Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.all(8),

                            decoration: BoxDecoration(

                              color: AppTheme.primaryColor.withOpacity(0.1),

                              borderRadius: BorderRadius.circular(12),

                            ),

                            child: Icon(

                              balance == null

                                  ? Icons.add

                                  : Icons.edit_outlined,

                              color: AppTheme.primaryColor,

                              size: 18,

                            ),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Text(

                              balance == null

                                  ? 'إضافة رصيد جديد لمصدر: ${resource.name}'

                                  : 'تعديل رصيد في مصدر: ${resource.name}',

                              style: const TextStyle(

                                color: AppTheme.textPrimary,

                                fontWeight: FontWeight.bold,

                                fontSize: 16,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                              ),

                            ),

                          ),

                          IconButton(

                            onPressed: () {

                              HapticFeedback.lightImpact();

                              Navigator.of(dialogContext).pop();

                            },

                            icon: Icon(

                              Icons.close,

                              color: AppTheme.textSecondary,

                              size: 18,

                            ),

                          ),

                        ],

                      ),

                    ),

                    const Divider(height: 1, color: AppTheme.dividerColor),

                    // Content

                    Flexible(

                      child: SingleChildScrollView(

                        padding: const EdgeInsets.all(20),

                        child: Form(

                          key: formKey,

                          child: Column(

                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              TextFormField(

                                controller: nameController,

                                style: const TextStyle(

                                  color: AppTheme.textPrimary,

                                  fontSize: 14,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                                decoration: InputDecoration(

                                  labelText: 'اسم الرصيد *',

                                  labelStyle: const TextStyle(

                                    color: AppTheme.textSecondary,

                                    fontSize: 13,

                                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                                  ),

                                  border: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: BorderSide(

                                      color: AppTheme.dividerColor.withOpacity(0.5),

                                    ),

                                  ),

                                  enabledBorder: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: BorderSide(

                                      color: AppTheme.dividerColor.withOpacity(0.5),

                                    ),

                                  ),

                                  focusedBorder: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(

                                      color: AppTheme.primaryColor,

                                      width: 1.5,

                                    ),

                                  ),

                                  filled: true,

                                  fillColor: AppTheme.surfaceColor,

                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                                ),

                                validator: (value) {

                                  if (value == null ||

                                      value.trim().isEmpty) {

                                    return 'يرجى إدخال اسم الرصيد';

                                  }

                                  return null;

                                },

                              ),

                              const SizedBox(height: 16),

                              TextFormField(

                                controller: amountController,

                                style: const TextStyle(

                                  color: AppTheme.textPrimary,

                                  fontSize: 14,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                                decoration: InputDecoration(

                                  labelText: 'الرصيد المبدئي',

                                  labelStyle: const TextStyle(

                                    color: AppTheme.textSecondary,

                                    fontSize: 13,

                                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                                  ),

                                  hintText: '0.00',

                                  hintStyle: const TextStyle(

                                    color: AppTheme.textSecondary,

                                    fontSize: 13,

                                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                                  ),

                                  border: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: BorderSide(

                                      color: AppTheme.dividerColor.withOpacity(0.5),

                                    ),

                                  ),

                                  enabledBorder: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: BorderSide(

                                      color: AppTheme.dividerColor.withOpacity(0.5),

                                    ),

                                  ),

                                  focusedBorder: OutlineInputBorder(

                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(

                                      color: AppTheme.primaryColor,

                                      width: 1.5,

                                    ),

                                  ),

                                  filled: true,

                                  fillColor: AppTheme.surfaceColor,

                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                                ),

                                keyboardType: const TextInputType

                                        .numberWithOptions(decimal: true),

                                validator: (value) {

                                  if (value == null ||

                                      value.trim().isEmpty) {

                                    return null; // اختياري، يعامل كـ 0

                                  }

                                  final parsed = double.tryParse(value);

                                  if (parsed == null || parsed < 0) {

                                    return 'يرجى إدخال رقم صحيح';

                                  }

                                  return null;

                                },

                              ),

                              const SizedBox(height: 16),

                              InkWell(

                                onTap: () async {

                                  try {

                                    final selected = await showLocalCurrencyPicker(

                                      context: context,

                                      showLocalOption: true,

                                    );

                                    if (selected != null) {

                                      selectedCurrency = selected;

                                      (dialogContext as Element).markNeedsBuild();

                                    }

                                  } catch (e) {

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context)

                                        .showSnackBar(

                                      SnackBar(

                                        content: Text(

                                            'خطأ في اختيار العملة: $e'),

                                        backgroundColor:

                                            AppTheme.errorColor,

                                      ),

                                    );

                                  }

                                },

                                child: InputDecorator(

                                  decoration: InputDecoration(

                                    labelText: 'العملة *',

                                    labelStyle:

                                        const TextStyle(fontSize: 14),

                                    border: OutlineInputBorder(

                                      borderRadius: BorderRadius.circular(8),

                                    ),

                                    focusedBorder: OutlineInputBorder(

                                      borderRadius: BorderRadius.circular(8),

                                      borderSide: const BorderSide(

                                        color: AppTheme.primaryColor,

                                      ),

                                    ),

                                  ),

                                  child: Text(

                                    selectedCurrency ?? 'العملة',

                                    style: TextStyle(

                                      fontSize: 14,

                                      color: selectedCurrency == null

                                          ? AppTheme.textSecondary

                                              .withOpacity(0.7)

                                          : AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              const SizedBox(height: 8),

                              CheckboxListTile(

                                value: isDefault,

                                onChanged: (value) {

                                  if (value != null) {

                                    isDefault = value;

                                    (dialogContext as Element)

                                        .markNeedsBuild();

                                  }

                                },

                                title: const Text(

                                  'تعيين كرصيد افتراضي',

                                  style: TextStyle(

                                    fontSize: 14,

                                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                                  ),

                                ),

                                controlAffinity:

                                    ListTileControlAffinity.leading,

                                contentPadding: EdgeInsets.zero,

                              ),

                            ],

                          ),

                        ),

                      ),

                    ),

                    // Actions

                    Container(

                      padding: const EdgeInsets.all(16),

                      decoration: const BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.only(

                          bottomLeft: Radius.circular(24),

                          bottomRight: Radius.circular(24),

                        ),

                      ),

                      child: Row(

                        children: [

                          Expanded(

                            child: TextButton(

                              onPressed: () {

                                HapticFeedback.lightImpact();

                                Navigator.of(dialogContext).pop();

                              },

                              style: TextButton.styleFrom(

                                backgroundColor: Colors.grey.shade100,

                                foregroundColor: AppTheme.textSecondary,

                                padding: const EdgeInsets.symmetric(

                                  vertical: 14,

                                ),

                                shape: RoundedRectangleBorder(

                                  borderRadius: BorderRadius.circular(14),

                                ),

                              ),

                              child: const Text(

                                'إلغاء',

                                style: TextStyle(

                                  fontSize: 14,

                                  fontWeight: FontWeight.bold,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                            ),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: ElevatedButton(

                              onPressed: () async {

                                if (!formKey.currentState!.validate()) return;



                                final name = nameController.text.trim();

                                final amountText = amountController.text.trim();

                                final initialAmount = amountText.isEmpty

                                    ? 0.0

                                    : double.parse(amountText);



                                if (selectedCurrency == null ||

                                    selectedCurrency!.isEmpty) {

                                  if (mounted) {

                                    ScaffoldMessenger.of(context).showSnackBar(

                                      const SnackBar(

                                        content: Text('يرجى اختيار العملة'),

                                        backgroundColor: AppTheme.errorColor,

                                      ),

                                    );

                                  }

                                  return;

                                }



                                try {

                                  int? affectId = balance?.id;

                                  if (balance == null) {

                                    final newBalance = IncomeBalanceModel(

                                      resourceId: resourceId,

                                      name: name,

                                      currencyName: selectedCurrency!,

                                      initialAmount: initialAmount,

                                      isDefault: isDefault,

                                      createdDate: DateTime.now(),

                                    );

                                    final newId = await _db

                                        .insertIncomeBalance(newBalance);

                                    affectId = newId;

                                  } else {

                                    final updated = balance.copyWith(

                                      name: name,

                                      currencyName: selectedCurrency!,

                                      initialAmount: initialAmount,

                                      isDefault: isDefault,

                                    );

                                    await _db.updateIncomeBalance(updated);

                                  }



                                  if (isDefault && affectId != null) {

                                    await _setDefaultBalance(affectId);

                                  }



                                  if (mounted) {

                                    Navigator.of(dialogContext).pop();

                                    await _loadBalances();

                                    ScaffoldMessenger.of(context)

                                        .showSnackBar(

                                      SnackBar(

                                        content: Text(balance == null

                                            ? 'تم إضافة الرصيد بنجاح'

                                            : 'تم تحديث الرصيد بنجاح'),

                                        backgroundColor:

                                            AppTheme.successColor,

                                      ),

                                    );

                                  }

                                } catch (e) {

                                  if (mounted) {

                                    ScaffoldMessenger.of(context)

                                        .showSnackBar(

                                      SnackBar(

                                        content: Text(

                                            'حدث خطأ أثناء حفظ الرصيد: $e'),

                                        backgroundColor:

                                            AppTheme.errorColor,

                                      ),

                                    );

                                  }

                                }

                              },

                              style: ElevatedButton.styleFrom(

                                backgroundColor: AppTheme.primaryColor,

                                foregroundColor: Colors.white,

                                padding: const EdgeInsets.symmetric(

                                  vertical: 14,

                                ),

                                shape: RoundedRectangleBorder(

                                  borderRadius: BorderRadius.circular(14),

                                ),

                                elevation: 0,

                              ),

                              child: const Text(

                                'حفظ',

                                style: TextStyle(

                                  fontSize: 14,

                                  fontWeight: FontWeight.bold,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            ),

          );

        },

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('حدث خطأ أثناء فتح شاشة الرصيد: $e'),

          backgroundColor: AppTheme.errorColor,

        ),

      );

    }

  }



  Future<void> _confirmDeleteBalance(IncomeBalanceModel balance) async {

    if (balance.id == null) return;



    // First, check if this balance is used in any transactions or expenses

    final usage = await _getBalanceAllocationsDetails(balance.id!);

    final bool hasTransactions = usage['transactions']?.isNotEmpty ?? false;

    final bool hasExpenses = usage['expenses']?.isNotEmpty ?? false;



    if (hasTransactions || hasExpenses) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('لا يمكن حذف الرصيد لوجود حركات أو مصروفات مرتبطة به'),

          backgroundColor: AppTheme.errorColor,

        ),

      );

      return;

    }



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => Directionality(

        textDirection: TextDirection.rtl,

        child: AlertDialog(

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(24),

          ),

          backgroundColor: Colors.white,

          title: const Text(

            'تأكيد الحذف',

            style: TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.bold,

              fontFamily: 'ArbFONTSIBMPlexArabicText',

              color: AppTheme.textPrimary,

            ),

          ),

          content: Text(

            'هل تريد حذف الرصيد "${balance.name}"؟',

            style: const TextStyle(

              fontSize: 14,

              fontFamily: 'ArbFONTSIBMPlexArabicText',

              color: AppTheme.textSecondary,

            ),

          ),

          actions: [

            TextButton(

              onPressed: () {

                HapticFeedback.lightImpact();

                Navigator.of(context).pop(false);

              },

              style: TextButton.styleFrom(

                foregroundColor: AppTheme.textSecondary,

              ),

              child: const Text(

                'إلغاء',

                style: TextStyle(

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

            TextButton(

              onPressed: () {

                HapticFeedback.mediumImpact();

                Navigator.of(context).pop(true);

              },

              style: TextButton.styleFrom(

                foregroundColor: AppTheme.errorColor,

              ),

              child: const Text(

                'حذف',

                style: TextStyle(

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ],

        ),

      ),

    );



    if (confirmed == true) {

      try {

        await _db.deleteIncomeBalance(balance.id!);

        await _loadBalances();

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              content: Text('تم حذف الرصيد بنجاح'),

              backgroundColor: AppTheme.successColor,

            ),

          );

        }

      } catch (e) {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text('تعذر حذف الرصيد: $e'),

              backgroundColor: AppTheme.errorColor,

            ),

          );

        }

      }

    }

  }



  Future<void> _generateAllIncomeResourcesReport() async {

    if (_resources.isEmpty) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('لا توجد مصادر دخل لعرض التقرير'),

        ),

      );

      return;

    }



    await AllIncomeResourcesReportGenerator.generate(

      resources: _resources,

      balancesByResource: _balancesByResource,

      currentBalanceAmounts: _currentBalanceAmounts,

    );

  }



  Future<void> _generateAllIncomeBalancesReport() async {

    if (_balances.isEmpty) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('لا توجد أرصدة دخل لعرض التقرير'),

        ),

      );

      return;

    }



    await AllIncomeBalancesReportGenerator.generate(

      balances: _balances,

      resources: _resources,

      currentBalanceAmounts: _currentBalanceAmounts,

    );

  }



  void _showReportOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull-to-dismiss bar indicator
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'تقرير جميع مصادر الدخل',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    await _generateAllIncomeResourcesReport();
                  },
                ),
                const Divider(height: 1, color: Colors.black12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'تقرير جميع أرصدة الدخل',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    await _generateAllIncomeBalancesReport();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlobalSummary(Map<String, double> totalsByCurrency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.04),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                size: 18,
                color: AppTheme.primaryColor.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              const Text(
                'إجمالي الأرصدة حسب العملة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: totalsByCurrency.entries.map((entry) {
                final symbol = CurrencyModel.symbolFor(entry.key);
                return Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_amountFormat.format(entry.value)} $symbol',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildBalancesList() {

    if (_balances.isEmpty) {

      return Center(

        child: Container(

          padding: const EdgeInsets.all(32),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(

                  color: AppTheme.primaryColor.withOpacity(0.1),

                  shape: BoxShape.circle,

                ),

                child: Icon(

                  Icons.account_balance_wallet_outlined,

                  size: 64,

                  color: AppTheme.primaryColor.withOpacity(0.6),

                ),

              ),

              const SizedBox(height: 24),

              const Text(

                'لا توجد أرصدة دخل متاحة',

                style: TextStyle(

                  fontSize: 15,

                  fontWeight: FontWeight.bold,

                  color: AppTheme.textPrimary,

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                ),

                textAlign: TextAlign.center,

              ),

              const SizedBox(height: 8),

              const Text(

                'يرجى إضافة رصيد مالي إلى مصادر الدخل أولاً',

                style: TextStyle(

                  fontSize: 13,

                  color: AppTheme.textSecondary,

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                ),

                textAlign: TextAlign.center,

              ),

            ],

          ),

        ),

      );

    }



    final Map<int, IncomeResourceModel> resourceById = {

      for (final r in _resources)

        if (r.id != null) r.id!: r,

    };



    // Calculate global totals
    final Map<String, double> totalsByCurrency = {};
    for (final balance in _balances) {
      if (balance.id == null) continue;
      final currentAmount =
          _currentBalanceAmounts[balance.id!] ?? balance.initialAmount;
      totalsByCurrency[balance.currencyName] =
          (totalsByCurrency[balance.currencyName] ?? 0.0) + currentAmount;
    }

    return Column(
      children: [
        if (totalsByCurrency.isNotEmpty)
          _buildGlobalSummary(totalsByCurrency),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 88),
            itemCount: _balances.length,
            itemBuilder: (context, index) {
              final balance = _balances[index];
              final resource = resourceById[balance.resourceId];

              final double currentAmount = balance.id != null
                  ? (_currentBalanceAmounts[balance.id!] ?? balance.initialAmount)
                  : balance.initialAmount;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: AppTheme.dividerColor.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource?.name ?? 'مصدر غير معروف',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      balance.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      balance.currencyName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _amountFormat.format(currentAmount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                  if (balance.isDefault) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'افتراضي',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildResourcesList() {

    return ListView.builder(

      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 88),

      itemCount: _resources.length,

      itemBuilder: (context, index) {

        final resource = _resources[index];

        final balances = resource.id != null

            ? _balancesByResource[resource.id!] ?? []

            : const <IncomeBalanceModel>[];



        final Map<String, double> totalsByCurrency = {};

        for (final balance in balances) {

          if (balance.id == null) continue;

          final currentAmount =

              _currentBalanceAmounts[balance.id!] ?? balance.initialAmount;

          totalsByCurrency[balance.currencyName] =

              (totalsByCurrency[balance.currencyName] ?? 0.0) + currentAmount;

        }



        return Container(

          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            boxShadow: AppTheme.cardShadow,

            border: Border.all(

              color: AppTheme.dividerColor.withOpacity(0.6),

              width: 1,

            ),

          ),

          child: ClipRRect(

            borderRadius: BorderRadius.circular(18),

            child: Container(

              decoration: const BoxDecoration(

                border: Border(

                  right: BorderSide(

                    color: AppTheme.primaryColor,

                    width: 5,

                  ),

                ),

              ),

              child: Padding(

                padding: const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Expanded(

                          child: InkWell(

                            onTap: resource.id == null

                                ? null

                                : () => _showResourceDetailsDialog(

                                      resource: resource,

                                    ),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  resource.name,

                                  style: const TextStyle(

                                    fontSize: 16,

                                    color: AppTheme.textPrimary,

                                    fontWeight: FontWeight.bold,

                                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                                  ),

                                ),

                                if (resource.description != null &&

                                    resource.description!.isNotEmpty)

                                  Padding(

                                    padding: const EdgeInsets.only(top: 4.0),

                                    child: Text(

                                      resource.description!,

                                      style: const TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textSecondary,

                                        fontFamily: 'ArbFONTSIBMPlexArabicText',

                                      ),

                                    ),

                                  ),

                                if (totalsByCurrency.isNotEmpty)

                                  Padding(

                                    padding: const EdgeInsets.only(top: 8.0),

                                    child: Wrap(

                                      spacing: 8,

                                      runSpacing: 4,

                                      children: totalsByCurrency.entries

                                          .map(

                                            (entry) => Container(

                                              padding: const EdgeInsets.symmetric(

                                                horizontal: 8,

                                                vertical: 4,

                                              ),

                                              decoration: BoxDecoration(

                                                color: AppTheme.primaryColor.withOpacity(0.08),

                                                borderRadius: BorderRadius.circular(12),

                                              ),

                                              child: Text(

                                                '${_amountFormat.format(entry.value)} ${entry.key}',

                                                style: const TextStyle(

                                                  fontSize: 11,

                                                  color: AppTheme.primaryColor,

                                                  fontWeight: FontWeight.w600,

                                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                                ),

                                              ),

                                            ),

                                          )

                                          .toList(),

                                    ),

                                  ),

                              ],

                            ),

                          ),

                        ),

                        PopupMenuButton<String>(

                          icon: const Icon(

                            Icons.more_vert_rounded,

                            color: AppTheme.textSecondary,

                          ),

                          onSelected: (value) async {

                            HapticFeedback.mediumImpact();

                            if (value == 'edit') {

                              await _showEditResourceDialog(resource: resource);

                            } else if (value == 'delete') {

                              await _confirmDeleteResource(resource);

                            }

                          },

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(12),

                          ),

                          itemBuilder: (context) => [

                            const PopupMenuItem<String>(

                              value: 'edit',

                              child: Text(

                                'تعديل المصدر',

                                style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),

                              ),

                            ),

                            PopupMenuItem<String>(

                              value: 'delete',

                              child: const Text(

                                'حذف المصدر',

                                style: TextStyle(

                                  color: AppTheme.errorColor,

                                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                                ),

                              ),

                            ),

                          ],

                        ),

                      ],

                    ),

                    const SizedBox(height: 12),

                    Align(

                      alignment: Alignment.centerRight,

                      child: TextButton.icon(

                        onPressed: resource.id == null

                            ? null

                            : () {

                                HapticFeedback.lightImpact();

                                _showEditBalanceDialog(resource: resource);

                              },

                        style: TextButton.styleFrom(

                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                          backgroundColor: AppTheme.primaryColor.withOpacity(0.06),

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(10),

                          ),

                        ),

                        icon: const Icon(

                          Icons.add_circle_outline_rounded,

                          size: 16,

                          color: AppTheme.primaryColor,

                        ),

                        label: const Text(

                          'إضافة رصيد لهذا المصدر',

                          style: TextStyle(

                            color: AppTheme.primaryColor,

                            fontSize: 12,

                            fontWeight: FontWeight.w600,

                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 8),

                    if (balances.isEmpty)

                      const Padding(

                        padding: EdgeInsets.symmetric(vertical: 4.0),

                        child: Text(

                          'لا توجد أرصدة لهذا المصدر',

                          style: TextStyle(

                            fontSize: 12,

                            color: AppTheme.textSecondary,

                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                          ),

                        ),

                      )

                    else

                      Column(

                        children: balances.map((balance) {

                          final double currentAmount = balance.id != null

                              ? (_currentBalanceAmounts[balance.id!] ??

                                  balance.initialAmount)

                              : balance.initialAmount;

                          return InkWell(

                            borderRadius: BorderRadius.circular(14),

                            onTap: () {

                              HapticFeedback.lightImpact();

                              _showBalanceDetailsDialog(resource: resource, balance: balance);

                            },

                            child: Container(

                              margin: const EdgeInsets.symmetric(vertical: 4),

                              padding: const EdgeInsets.all(12),

                              decoration: BoxDecoration(

                                color: balance.isDefault

                                    ? AppTheme.primaryColor.withOpacity(0.04)

                                    : AppTheme.dividerColor.withOpacity(0.15),

                                borderRadius: BorderRadius.circular(12),

                                border: Border.all(

                                  color: balance.isDefault

                                      ? AppTheme.primaryColor.withOpacity(0.15)

                                      : AppTheme.dividerColor.withOpacity(0.25),

                                  width: 1,

                                ),

                              ),

                              child: Row(

                                children: [

                                  Expanded(

                                    flex: 3,

                                    child: Column(

                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [

                                        Text(

                                          balance.name,

                                          style: const TextStyle(

                                            fontSize: 14,

                                            color: AppTheme.textPrimary,

                                            fontWeight: FontWeight.w600,

                                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                                          ),

                                        ),

                                        const SizedBox(height: 2),

                                        Text(

                                          balance.currencyName,

                                          style: const TextStyle(

                                            fontSize: 12,

                                            color: AppTheme.textSecondary,

                                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                  Expanded(

                                    flex: 2,

                                    child: Column(

                                      crossAxisAlignment: CrossAxisAlignment.end,

                                      children: [

                                        Text(

                                          _amountFormat.format(currentAmount),

                                          style: const TextStyle(

                                            fontSize: 14,

                                            color: AppTheme.textPrimary,

                                            fontWeight: FontWeight.w700,

                                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                                          ),

                                        ),

                                        if (balance.isDefault) ...[

                                          const SizedBox(height: 4),

                                          Container(

                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                                            decoration: BoxDecoration(

                                              color: AppTheme.primaryColor.withOpacity(0.1),

                                              borderRadius: BorderRadius.circular(6),

                                            ),

                                            child: const Text(

                                              'افتراضي',

                                              style: TextStyle(

                                                fontSize: 9,

                                                color: AppTheme.primaryColor,

                                                fontWeight: FontWeight.w600,

                                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                                              ),

                                            ),

                                          ),

                                        ],

                                      ],

                                    ),

                                  ),

                                  PopupMenuButton<String>(

                                    icon: const Icon(

                                      Icons.more_vert_rounded,

                                      color: AppTheme.textSecondary,

                                      size: 20,

                                    ),

                                    shape: RoundedRectangleBorder(

                                      borderRadius: BorderRadius.circular(12),

                                    ),

                                    onSelected: (value) async {

                                      HapticFeedback.mediumImpact();

                                      if (value == 'edit') {

                                        await _showEditBalanceDialog(

                                          resource: resource,

                                          balance: balance,

                                        );

                                      } else if (value == 'default' &&

                                          balance.id != null) {

                                        await _setDefaultBalance(balance.id!);

                                        await _loadBalances();

                                      } else if (value == 'delete') {

                                        await _confirmDeleteBalance(balance);

                                      }

                                    },

                                    itemBuilder: (context) => [

                                      const PopupMenuItem<String>(

                                        value: 'edit',

                                        child: Text(

                                          'تعديل الرصيد',

                                          style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),

                                        ),

                                      ),

                                      if (!balance.isDefault)

                                        const PopupMenuItem<String>(

                                          value: 'default',

                                          child: Text(

                                            'تعيين كرصيد افتراضي',

                                            style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),

                                          ),

                                        ),

                                      const PopupMenuItem<String>(

                                        value: 'delete',

                                        child: Text(

                                          'حذف الرصيد',

                                          style: TextStyle(

                                            color: AppTheme.errorColor,

                                            fontFamily: 'ArbFONTSIBMPlexArabicText',

                                          ),

                                        ),

                                      ),

                                    ],

                                  ),

                                ],

                              ),

                            ),

                          );

                        }).toList(),

                      ),

                  ],

                ),

              ),

            ),

          ),

        );

      },

    );

  }



  Widget _buildMainContent() {

    if (_isLoading) {

      return const Center(child: CircularProgressIndicator());

    }



    if (_resources.isEmpty) {

      return Center(

        child: Container(

          padding: const EdgeInsets.all(32),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(

                  color: AppTheme.primaryColor.withOpacity(0.1),

                  shape: BoxShape.circle,

                ),

                child: Icon(

                  Icons.account_balance_rounded,

                  size: 64,

                  color: AppTheme.primaryColor.withOpacity(0.6),

                ),

              ),

              const SizedBox(height: 24),

              const Text(

                'لا توجد مصادر دخل متاحة',

                style: TextStyle(

                  fontSize: 15,

                  fontWeight: FontWeight.bold,

                  color: AppTheme.textPrimary,

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                ),

                textAlign: TextAlign.center,

              ),

              const SizedBox(height: 8),

              const Text(

                'قم بإنشاء مصادر دخل لبدء إدارة أرصدتك الحالية',

                style: TextStyle(

                  fontSize: 13,

                  color: AppTheme.textSecondary,

                  fontFamily: 'ArbFONTSIBMPlexArabicText',

                ),

                textAlign: TextAlign.center,

              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(

                onPressed: () {

                  HapticFeedback.lightImpact();

                  _showEditResourceDialog();

                },

                style: ElevatedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

                  backgroundColor: AppTheme.primaryColor,

                  foregroundColor: Colors.white,

                  elevation: 2,

                  shadowColor: AppTheme.primaryColor.withOpacity(0.2),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(24),

                  ),

                ),

                icon: const Icon(Icons.add_rounded, size: 20),

                label: const Text(

                  'إضافة مصدر دخل',

                  style: TextStyle(

                    fontFamily: 'ArbFONTSIBMPlexArabicText',

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ],

          ),

        ),

      );

    }



    return PageView(

      controller: _pageController,

      onPageChanged: (index) {

        setState(() {

          _selectedSection = index == 0 ? IncomeSection.resources : IncomeSection.balances;

        });

      },

      children: [

        _buildResourcesList(),

        _buildBalancesList(),

      ],

    );

  }



  @override

  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'الأرصدة',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.primaryColor),
            actions: [
              IconButton(
                icon: const Icon(Icons.assessment_rounded),
                tooltip: 'تقرير مصادر وأرصدة الدخل',
                onPressed: _showReportOptions,
              ),
              const SizedBox(width: 4),
            ],
          ),

        floatingActionButton: FloatingActionButton(

          onPressed: () {

            HapticFeedback.lightImpact();

            _showEditResourceDialog();

          },

          backgroundColor: AppTheme.primaryColor,

          elevation: 4,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(16),

          ),

          tooltip: 'إضافة / تعديل مصدر دخل',

          child: const Icon(

            Icons.add,

            color: Colors.white,

            size: 24,

          ),

        ),

        body: Column(

          children: [

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

              child: Container(

                padding: const EdgeInsets.all(4),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: AppTheme.cardShadow,

                  border: Border.all(

                    color: AppTheme.dividerColor.withOpacity(0.4),

                    width: 1,

                  ),

                ),

                child: Row(

                  children: [

                    Expanded(

                      child: GestureDetector(

                        onTap: () {

                          HapticFeedback.lightImpact();

                          setState(() {

                            _selectedSection = IncomeSection.resources;

                          });

                          _pageController.animateToPage(

                            0,

                            duration: const Duration(milliseconds: 300),

                            curve: Curves.easeInOut,

                          );

                        },

                        child: AnimatedContainer(

                          duration: const Duration(milliseconds: 200),

                          padding: const EdgeInsets.symmetric(vertical: 10),

                          decoration: BoxDecoration(

                            gradient: _selectedSection == IncomeSection.resources

                                ? AppTheme.primaryGradient

                                : null,

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: Center(

                            child: Text(

                              'مصادر الدخل',

                              style: TextStyle(

                                fontSize: 13,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                                fontWeight: _selectedSection == IncomeSection.resources

                                    ? FontWeight.bold

                                    : FontWeight.w600,

                                color: _selectedSection == IncomeSection.resources

                                    ? Colors.white

                                    : AppTheme.textPrimary,

                              ),

                            ),

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(width: 4),

                    Expanded(

                      child: GestureDetector(

                        onTap: () {

                          HapticFeedback.lightImpact();

                          setState(() {

                            _selectedSection = IncomeSection.balances;

                          });

                          _pageController.animateToPage(

                            1,

                            duration: const Duration(milliseconds: 300),

                            curve: Curves.easeInOut,

                          );

                        },

                        child: AnimatedContainer(

                          duration: const Duration(milliseconds: 200),

                          padding: const EdgeInsets.symmetric(vertical: 10),

                          decoration: BoxDecoration(

                            gradient: _selectedSection == IncomeSection.balances

                                ? AppTheme.primaryGradient

                                : null,

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: Center(

                            child: Text(

                              'أرصدة الدخل',

                              style: TextStyle(

                                fontSize: 13,

                                fontFamily: 'ArbFONTSIBMPlexArabicText',

                                fontWeight: _selectedSection == IncomeSection.balances

                                    ? FontWeight.bold

                                    : FontWeight.w600,

                                color: _selectedSection == IncomeSection.balances

                                    ? Colors.white

                                    : AppTheme.textPrimary,

                              ),

                            ),

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

            Expanded(

              child: _buildMainContent(),

            ),

          ],
        ),
      ),
    ),
  );
}

}

