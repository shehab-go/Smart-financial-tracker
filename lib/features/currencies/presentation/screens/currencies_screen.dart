import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/models/currency.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  List<CurrencyModel> _currencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currencies = await DatabaseHelper().getCurrencies();
      setState(() {
        _currencies = currencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل العملات: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملات'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCurrencies),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      Icon(Icons.monetization_on, size: 48, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 8),
                      Text('إدارة العملات المستخدمة',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              )),
                      const SizedBox(height: 4),
                      Text('يمكنك إضافة وتعديل وحذف العملات وتحديد العملة الافتراضية',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Expanded(
                  child: _currencies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('لا توجد عملات', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('اضغط على زر + لإضافة عملة جديدة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _currencies.length,
                          itemBuilder: (context, index) {
                            final currency = _currencies[index];
                            final isDefault = currency.isDefault;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: isDefault ? 4 : 1,
                              color: isDefault ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDefault ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Text(
                                    currency.symbol,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDefault ? Colors.white : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(currency.nameArabic, style: TextStyle(fontWeight: FontWeight.bold, color: isDefault ? Theme.of(context).primaryColor : null)),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
                                        child: const Text('افتراضي', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text('${currency.name} (${currency.code})', style: TextStyle(color: Colors.grey[600])),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isDefault)
                                      IconButton(
                                        icon: const Icon(Icons.star_border, color: Colors.orange),
                                        onPressed: () => _setDefaultCurrency(currency),
                                        tooltip: 'تعيين كافتراضي',
                                      ),
                                    IconButton(icon: Icon(Icons.edit, color: Theme.of(context).primaryColor), onPressed: () => _editCurrency(currency)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: isDefault ? null : () => _deleteCurrency(currency)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(onPressed: _addCurrency, child: const Icon(Icons.add)),
    );
  }

  void _addCurrency() => _showCurrencyDialog();
  void _editCurrency(CurrencyModel currency) => _showCurrencyDialog(currency: currency);

  void _showCurrencyDialog({CurrencyModel? currency}) {
    final isEditing = currency != null;
    final nameController = TextEditingController(text: currency?.name ?? '');
    final nameArabicController = TextEditingController(text: currency?.nameArabic ?? '');
    final symbolController = TextEditingController(text: currency?.symbol ?? '');
    final codeController = TextEditingController(text: currency?.code ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل العملة' : 'إضافة عملة جديدة'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArabicController,
                  decoration: const InputDecoration(labelText: 'اسم العملة بالعربية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.translate), hintText: 'ريال سعودي'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم العملة بالعربية' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم العملة بالإنجليزية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.abc), hintText: 'Saudi Riyal'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم العملة بالإنجليزية' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: symbolController,
                  decoration: const InputDecoration(labelText: 'رمز العملة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_exchange), hintText: 'ر.س'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال رمز العملة' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'كود العملة (ISO)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.code), hintText: 'SAR'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'يرجى إدخال كود العملة';
                    if (value.trim().length != 3) return 'كود العملة يجب أن يكون 3 أحرف';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final newCurrency = CurrencyModel(
                    id: currency?.id,
                    name: nameController.text.trim(),
                    nameArabic: nameArabicController.text.trim(),
                    symbol: symbolController.text.trim(),
                    code: codeController.text.trim().toUpperCase(),
                    isDefault: currency?.isDefault ?? false,
                  );
                  if (isEditing) {
                    await DatabaseHelper().updateCurrency(newCurrency);
                  } else {
                    await DatabaseHelper().insertCurrency(newCurrency);
                  }
                  Navigator.pop(context);
                  _loadCurrencies();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'تم تعديل العملة بنجاح' : 'تم إضافة العملة بنجاح'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'تعديل' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _setDefaultCurrency(CurrencyModel currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعيين العملة الافتراضية'),
        content: Text('هل تريد تعيين "${currency.nameArabic}" كعملة افتراضية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper().setDefaultCurrency(currency.id!);
                Navigator.pop(context);
                _loadCurrencies();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعيين العملة الافتراضية بنجاح'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('تعيين'),
          ),
        ],
      ),
    );
  }

  void _deleteCurrency(CurrencyModel currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملة'),
        content: Text('هل أنت متأكد من حذف عملة "${currency.nameArabic}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await DatabaseHelper().deleteCurrency(currency.id!);
                Navigator.pop(context);
                _loadCurrencies();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف العملة بنجاح'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في حذف العملة: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
