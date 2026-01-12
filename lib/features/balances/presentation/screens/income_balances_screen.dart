import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/income_balance.dart';
import 'package:debit_credit_app/core/models/income_resource.dart';
import 'package:debit_credit_app/core/models/currency.dart';
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
  List<IncomeResourceModel> _resources = [];
  List<IncomeBalanceModel> _balances = [];
  Map<int, List<IncomeBalanceModel>> _balancesByResource = {};
  bool _isLoading = true;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      final resources = await _db.getIncomeResources();
      final balances = await _db.getIncomeBalances();
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

  Future<void> _showEditResourceDialog({IncomeResourceModel? resource}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: resource?.name ?? '');
    final descriptionController =
        TextEditingController(text: resource?.description ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              resource == null ? 'إضافة مصدر دخل جديد' : 'تعديل مصدر الدخل',
              style: const TextStyle(fontSize: 14),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                          borderSide:
                              const BorderSide(color: AppTheme.primaryColor),
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
                          borderSide:
                              const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final name = nameController.text.trim();
                  final desc = descriptionController.text.trim().isEmpty
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('حدث خطأ أثناء حفظ المصدر: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
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

      final List<CurrencyModel> dbCurrencies = await _db.getCurrencies();
      final allCurrencies = dbCurrencies.isEmpty
          ? CurrencyModel.getDefaultCurrencies()
          : dbCurrencies;

      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: balance?.name ?? '');
      final amountController = TextEditingController(
        text: balance != null ? balance.initialAmount.toString() : '',
      );

      String selectedCurrency = balance?.currencyName ??
          (allCurrencies.isNotEmpty ? allCurrencies.first.name : 'محلي');
      bool isDefault = balance?.isDefault ?? false;
      final int resourceId = balance?.resourceId ?? resource.id!;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                balance == null
                    ? 'إضافة رصيد جديد لمصدر: ${resource.name}'
                    : 'تعديل رصيد في مصدر: ${resource.name}',
                style: const TextStyle(fontSize: 14),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الرصيد *',
                          labelStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                          labelStyle: const TextStyle(fontSize: 14),
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                      DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'العملة *',
                          labelStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        items: allCurrencies
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c.name,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedCurrency = value;
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: isDefault,
                        onChanged: (value) {
                          if (value != null) {
                            isDefault = value;
                            (dialogContext as Element).markNeedsBuild();
                          }
                        },
                        title: const Text(
                          'تعيين كرصيد افتراضي',
                          style: TextStyle(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final name = nameController.text.trim();
                    final amountText = amountController.text.trim();
                    final initialAmount =
                        amountText.isEmpty ? 0.0 : double.parse(amountText);

                    try {
                      int? affectId = balance?.id;
                      if (balance == null) {
                        final newBalance = IncomeBalanceModel(
                          resourceId: resourceId,
                          name: name,
                          currencyName: selectedCurrency,
                          initialAmount: initialAmount,
                          isDefault: isDefault,
                          createdDate: DateTime.now(),
                        );
                        final newId =
                            await _db.insertIncomeBalance(newBalance);
                        affectId = newId;
                      } else {
                        final updated = balance.copyWith(
                          name: name,
                          currencyName: selectedCurrency,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(balance == null
                                ? 'تم إضافة الرصيد بنجاح'
                                : 'تم تحديث الرصيد بنجاح'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('حدث خطأ أثناء حفظ الرصيد: $e'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
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

    if (confirmed == true && balance.id != null) {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEditResourceDialog(),
          backgroundColor: AppTheme.primaryColor,
          elevation: 2,
          tooltip: 'إضافة مصدر دخل جديد',
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _resources.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) {
                      final resource = _resources[index];
                      final balances = resource.id != null
                          ? _balancesByResource[resource.id!] ?? []
                          : const <IncomeBalanceModel>[];

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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
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
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _showEditResourceDialog(
                                          resource: resource);
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
                                  return InkWell(
                                    onTap: () => _showEditBalanceDialog(
                                        resource: resource,
                                        balance: balance),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  balance.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textPrimary,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  balance.currencyName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _amountFormat.format(
                                                      balance
                                                          .initialAmount),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme
                                                        .textPrimary,
                                                  ),
                                                ),
                                                if (balance.isDefault)
                                                  const SizedBox(height: 2),
                                                if (balance.isDefault)
                                                  const Text(
                                                    'افتراضي',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color:
                                                  AppTheme.textSecondary,
                                            ),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                await _showEditBalanceDialog(
                                                  resource: resource,
                                                  balance: balance,
                                                );
                                              } else if (value ==
                                                      'default' &&
                                                  balance.id != null) {
                                                await _setDefaultBalance(
                                                    balance.id!);
                                                await _loadBalances();
                                              } else if (value ==
                                                  'delete') {
                                                await _confirmDeleteBalance(
                                                    balance);
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
                                                  child: Text(
                                                      'تعيين كرصيد افتراضي'),
                                                ),
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text(
                                                  'حذف الرصيد',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.errorColor,
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
                  ),
      ),
    );
  }
}
