import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/installment_plan.dart';
import 'package:debit_credit_app/core/services/installment_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/installments/presentation/dialogs/add_installment_dialog.dart';
import 'package:debit_credit_app/core/events/financial_events.dart';
import 'dart:async';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final InstallmentService _service = InstallmentService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'ar');

  List<InstallmentPlanModel> _plans = [];
  bool _isLoading = true;
  StreamSubscription<FinancialEvent>? _financialSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _financialSubscription = FinancialEventBus().events.listen((_) {
      _loadPlans();
    });
  }

  @override
  void dispose() {
    _financialSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _db.getInstallmentPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddDialog({InstallmentPlanModel? plan}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddInstallmentDialog(plan: plan),
    );
    if (result == true) {
      _loadPlans();
    }
  }

  Future<void> _payInstallment(InstallmentPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد تسديد الدفعة 💳', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          content: Text(
            'هل تريد تسديد دفعة "${plan.title}" بمبلغ ${_currencyFormat.format(plan.installmentAmount)} ${plan.currencyName}؟\nسيتم تسجيل المعاملة وتعديل الاستحقاق تلقائياً.',
            style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('تأكيد التسديد 💳', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      final success = await _service.payInstallment(plan);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تسديد دفعة "${plan.title}" بنجاح! 🎉'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadPlans();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء السداد'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deletePlan(InstallmentPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف القسط 🗑️'),
          content: Text('هل أنت أربك من حذف "${plan.title}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _service.deletePlan(plan.id!);
      _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePlans = _plans.where((p) => p.status == 'active').toList();
    final overduePlans = activePlans.where((p) => p.isOverdue).toList();
    final dueSoonPlans = activePlans.where((p) => p.isDueToday || p.isDueSoon).toList();
    final completedPlans = _plans.where((p) => p.status == 'completed').toList();

    double totalMonthlyDue = 0.0;
    for (var p in activePlans) {
      totalMonthlyDue += p.installmentAmount;
    }

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
            title: const Text(
              'الأقساط والالتزامات المجدولة 📅',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
                color: AppTheme.textPrimary,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddDialog(),
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'إضافة قسط / التزام',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Executive Summary Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'ملخص الالتزامات الشهرية',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_currencyFormat.format(totalMonthlyDue)} ر.ي',
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Flexible(
                                    child: _buildBannerStat(
                                      label: 'نشطة',
                                      count: '${activePlans.length}',
                                      icon: Icons.check_circle_outline_rounded,
                                    ),
                                  ),
                                  Container(height: 24, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 10)),
                                  Flexible(
                                    child: _buildBannerStat(
                                      label: 'قريباً',
                                      count: '${dueSoonPlans.length}',
                                      icon: Icons.notifications_active_rounded,
                                    ),
                                  ),
                                  Container(height: 24, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 10)),
                                  Flexible(
                                    child: _buildBannerStat(
                                      label: 'متأخرة',
                                      count: '${overduePlans.length}',
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section Title
                        const Text(
                          'قائمة الالتزامات والأقساط النشطة',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),

                        if (activePlans.isEmpty && completedPlans.isEmpty) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.calendar_month_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد أقساط أو التزامات مجدولة',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'اضغط على زر "+ إضافة قسط / التزام" لبدء جدولة التزاماتك المكررة وسدادها بنقرة واحدة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activePlans.length,
                            itemBuilder: (context, index) {
                              final plan = activePlans[index];
                              return _buildInstallmentCard(plan);
                            },
                          ),

                          if (completedPlans.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'الأقساط المكتملة 📁',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: completedPlans.length,
                              itemBuilder: (context, index) {
                                final plan = completedPlans[index];
                                return _buildInstallmentCard(plan);
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBannerStat({required String label, required String count, required IconData icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label: $count',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentCard(InstallmentPlanModel plan) {
    final days = plan.daysUntilDue;
    Color statusColor;
    String statusText;

    if (plan.status == 'completed') {
      statusColor = AppTheme.successColor;
      statusText = 'مكتمل المسار 🎉';
    } else if (plan.isOverdue) {
      statusColor = AppTheme.errorColor;
      statusText = 'متأخر منذ ${days.abs()} يوم ⚠️';
    } else if (plan.isDueToday) {
      statusColor = AppTheme.warningColor;
      statusText = 'مستحق اليوم 🔔';
    } else if (plan.isDueSoon) {
      statusColor = AppTheme.warningColor;
      statusText = 'مستحق خلال $days أيام ⏳';
    } else {
      statusColor = AppTheme.primaryColor;
      statusText = 'متبقي $days يوم';
    }

    final double progress = (plan.totalCount != null && plan.totalCount! > 0)
        ? (plan.paidCount / plan.totalCount!).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  plan.planType == 'installment' ? Icons.phone_android_rounded : Icons.home_work_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الدفعة: ${_currencyFormat.format(plan.installmentAmount)} ${plan.currencyName}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openAddDialog(plan: plan);
                  if (v == 'delete') _deletePlan(plan);
                },
                itemBuilder: (c) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar for Installments
          if (plan.planType == 'installment' && plan.totalCount != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('نسبة السداد: ${plan.paidCount} من ${plan.totalCount}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Quick Pay Button
          if (plan.status == 'active') ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _payInstallment(plan),
                icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'تسديد الدفعة الآن 💳',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
