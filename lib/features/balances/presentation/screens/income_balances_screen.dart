import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/models/income_resource.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';
import 'package:world_countries/world_countries.dart';
import 'package:debit_credit_app/features/balances/application/reports/all_income_balances_report_generator.dart';
import 'package:debit_credit_app/features/balances/application/reports/all_income_resources_report_generator.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBalances();
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
                      ? 'معاملة دائنة (له)'
                      : 'معاملة مدينة (عليه)',
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
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
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
                                    'المعاملات الدائنة (له)',
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
                                    'المعاملات المدينة (عليه)',
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
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
                                  fontSize: 18,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                balance.currencyName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
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
                                    'المعاملات الدائنة (له)',
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
                                    'المعاملات المدينة (عليه)',
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
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
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
                              decoration: InputDecoration(
                                labelText: 'اسم المصدر *',
                                labelStyle: const TextStyle(fontSize: 14),
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
                              style: const TextStyle(fontSize: 14),
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
                              decoration: InputDecoration(
                                labelText: 'الوصف',
                                labelStyle: const TextStyle(fontSize: 14),
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
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14),
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
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'حفظ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontSize: 16),
          ),
          content: Text(
            'هل تريد حذف مصدر الدخل "${resource.name}"؟',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('حذف'),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 380, maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
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
                                decoration: InputDecoration(
                                  labelText: 'اسم الرصيد *',
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
                                style: const TextStyle(fontSize: 14),
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
                                decoration: InputDecoration(
                                  labelText: 'الرصيد المبدئي',
                                  labelStyle:
                                      const TextStyle(fontSize: 14),
                                  hintText: '0.00',
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
                                keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 14),
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
                                    FiatCurrency? chosen;

                                    await showDialog(
                                      context: dialogContext,
                                      barrierDismissible: true,
                                      builder: (pickerContext) {
                                        return Dialog(
                                          insetPadding:
                                              const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Container(
                                              constraints:
                                                  const BoxConstraints(
                                                maxWidth: 380,
                                                maxHeight: 520,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  // Header
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 20,
                                                      vertical: 16,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                12),
                                                        topRight:
                                                            Radius.circular(
                                                                12),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppTheme
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .payments_outlined,
                                                            color: AppTheme
                                                                .primaryColor,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        const Expanded(
                                                          child: Text(
                                                            'اختيار العملة',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      pickerContext)
                                                                  .pop(),
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: AppTheme
                                                                .textSecondary,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Divider(
                                                    height: 1,
                                                    color:
                                                        AppTheme.dividerColor,
                                                  ),
                                                  // Favorites strip (quick selection)
                                                  if (favorites.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      child: SizedBox(
                                                        height: 32,
                                                        child: ListView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          children: favorites
                                                              .map(
                                                                (name) =>
                                                                    Padding(
                                                                  padding:
                                                                      const EdgeInsetsDirectional
                                                                          .only(
                                                                    start: 4,
                                                                    end: 4,
                                                                  ),
                                                                  child:
                                                                      ActionChip(
                                                                    label:
                                                                        Text(
                                                                      name,
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      selectedCurrency =
                                                                          name;
                                                                      (dialogContext
                                                                              as Element)
                                                                          .markNeedsBuild();
                                                                      Navigator.of(
                                                                              pickerContext)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  // Content
                                                  Flexible(
                                                    child: CurrencyPicker(
                                                      onSelect:
                                                          (FiatCurrency c) {
                                                        chosen = c;
                                                        Navigator.of(
                                                                pickerContext)
                                                            .pop();
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    if (chosen != null) {
                                      final typedLocale =
                                          dialogContext.maybeLocale;
                                      String displayName;
                                      if (typedLocale != null) {
                                        displayName = chosen!
                                                .maybeCommonNameFor(
                                                    typedLocale) ??
                                            chosen!.internationalName;
                                      } else {
                                        displayName =
                                            chosen!.internationalName;
                                      }
                                      selectedCurrency = displayName;
                                      (dialogContext as Element)
                                          .markNeedsBuild();
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
                                  style: TextStyle(fontSize: 14),
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
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'حفظ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontSize: 16),
          ),
          content: Text(
            'هل تريد حذف الرصيد "${balance.name}"؟',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('حذف'),
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
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('تقرير جميع مصادر الدخل'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _generateAllIncomeResourcesReport();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('تقرير جميع أرصدة الدخل'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _generateAllIncomeBalancesReport();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalancesList() {
    if (_balances.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أرصدة دخل متاحة',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    final Map<int, IncomeResourceModel> resourceById = {
      for (final r in _resources)
        if (r.id != null) r.id!: r,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _balances.length,
      itemBuilder: (context, index) {
        final balance = _balances[index];
        final resource = resourceById[balance.resourceId];

        final double currentAmount = balance.id != null
            ? (_currentBalanceAmounts[balance.id!] ?? balance.initialAmount)
            : balance.initialAmount;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource?.name ?? 'مصدر غير معروف',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          balance.currencyName,
                          style: const TextStyle(
                            fontSize: 12,
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
                        _amountFormat.format(currentAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (balance.isDefault) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'افتراضي',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لا توجد مصادر دخل متاحة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showEditResourceDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مصدر دخل'),
            ),
          ],
        ),
      );
    }

    if (_selectedSection == IncomeSection.balances) {
      return _buildBalancesList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
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
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
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
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
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
                                ),
                              ),
                            ),
                          if (totalsByCurrency.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
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
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.04),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_amountFormat.format(entry.value)} ${entry.key}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
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
                      Icons.more_vert,
                      color: AppTheme.textSecondary,
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showEditResourceDialog(resource: resource);
                      } else if (value == 'delete') {
                        await _confirmDeleteResource(resource);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('تعديل المصدر'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'حذف المصدر',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: resource.id == null
                      ? null
                      : () => _showEditBalanceDialog(
                            resource: resource,
                          ),
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  label: const Text(
                    'إضافة رصيد لهذا المصدر',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (balances.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'لا توجد أرصدة لهذا المصدر',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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
                      onTap: () => _showBalanceDetailsDialog(
                          resource: resource, balance: balance),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: balance.isDefault
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
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
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    balance.currencyName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
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
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (balance.isDefault)
                                    const SizedBox(height: 2),
                                  if (balance.isDefault)
                                    const Text(
                                      'افتراضي',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textSecondary,
                              ),
                              onSelected: (value) async {
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
                                  child: Text('تعديل الرصيد'),
                                ),
                                if (!balance.isDefault)
                                  const PopupMenuItem<String>(
                                    value: 'default',
                                    child: Text('تعيين كرصيد افتراضي'),
                                  ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(
                                    'حذف الرصيد',
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'أرصدة الدخل',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: null,
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/report_icons/pdf_report.svg',
                width: 24,
                height: 24,
              ),
              tooltip: 'تقرير مصادر وأرصدة الدخل',
              onPressed: _showReportOptions,
            ),
            if (!_isDrawerOpen)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'القائمة',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
          ],
        ),
        endDrawer: const AppDrawer(),
        onEndDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
          widget.onDrawerChanged?.call(isOpened);
        },
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEditResourceDialog(),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 3,
          shape: CircleBorder(
            side: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.6),
              width: 1.4,
            ),
          ),
          tooltip: 'إضافة / تعديل مصدر دخل',
          child: const Icon(
            Icons.add,
            size: 24,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('مصادر الدخل'),
                    selected: _selectedSection == IncomeSection.resources,
                    onSelected: (selected) {
                      if (selected &&
                          _selectedSection != IncomeSection.resources) {
                        setState(() {
                          _selectedSection = IncomeSection.resources;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('أرصدة الدخل'),
                    selected: _selectedSection == IncomeSection.balances,
                    onSelected: (selected) {
                      if (selected &&
                          _selectedSection != IncomeSection.balances) {
                        setState(() {
                          _selectedSection = IncomeSection.balances;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }
}
