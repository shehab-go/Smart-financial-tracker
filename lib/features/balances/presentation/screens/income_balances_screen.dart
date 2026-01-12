import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/app_drawer.dart';

class IncomeBalancesScreen extends StatefulWidget {
  final Function(bool)? onDrawerChanged;

  const IncomeBalancesScreen({super.key, this.onDrawerChanged});

  @override
  State<IncomeBalancesScreen> createState() => _IncomeBalancesScreenState();
}

class _IncomeBalancesScreenState extends State<IncomeBalancesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'ar');
  List<IncomeBalanceModel> _balances = [];
  bool _isLoading = true;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      final balances = await _db.getIncomeBalances();
      if (!mounted) return;
      setState(() {
        _balances = balances;
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _balances.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أرصدة متاحة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _balances.length,
                    itemBuilder: (context, index) {
                      final balance = _balances[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
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
                            color: balance.isDefault
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: 1.5,
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
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                                    _amountFormat.format(balance.initialAmount),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (balance.isDefault)
                                    const SizedBox(height: 4),
                                  if (balance.isDefault)
                                    const Text(
                                      'افتراضي',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
