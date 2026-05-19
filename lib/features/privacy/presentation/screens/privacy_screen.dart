import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/main_navigation.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'سياسة الخصوصية',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.primaryColor,
            iconSize: 20,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigation()),
                (route) => false,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final scaffoldState = Scaffold.of(context);
                if (scaffoldState.hasEndDrawer) {
                  scaffoldState.openEndDrawer();
                }
              });
            },
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.privacy_tip_rounded,
                          color: AppTheme.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'نحن نحترم خصوصيتك ونحمي بياناتك بالكامل',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                _buildSection(
                  context,
                  'جمع البيانات',
                  'تطبيق حسابات يومية لا يجمع أي بيانات شخصية أو مالية من المستخدمين. جميع المعلومات التي تدخلها في التطبيق تبقى محفوظة محلياً على جهازك فقط.',
                  Icons.data_usage_rounded,
                ),
                _buildSection(
                  context,
                  'التخزين المحلي',
                  'يستخدم التطبيق قاعدة بيانات محلية (SQLite) لحفظ معلوماتك المالية على جهازك مباشرة. هذا يعني أن:\n\n• بياناتك لا تغادر جهازك أبداً\n• لا توجد خوادم خارجية تحتفظ بمعلوماتك\n• أنت المتحكم الوحيد في بياناتك\n• يمكنك استخدام التطبيق بدون إنترنت',
                  Icons.storage_rounded,
                ),
                _buildSection(
                  context,
                  'عدم الاتصال بالإنترنت',
                  'التطبيق مصمم للعمل بدون إنترنت بالكامل. لا يقوم بإرسال أي معلومات إلى الإنترنت أو استقبال أي بيانات من مصادر خارجية. هذا يضمن الحماية الكاملة لخصوصيتك.',
                  Icons.wifi_off_rounded,
                ),
                _buildSection(
                  context,
                  'أمان البيانات',
                  'نتخذ الإجراءات التالية لضمان أمان بياناتك:\n\n• التخزين المحلي الآمن باستخدام SQLite\n• عدم مشاركة البيانات مع أطراف ثالثة\n• عدم وجود اتصال بخوادم خارجية\n• حماية البيانات من خلال نظام تشغيل الجهاز\n• إمكانية النسخ الاحتياطي المحلي',
                  Icons.security_rounded,
                ),
                _buildSection(
                  context,
                  'حقوق المستخدم',
                  'كمستخدم للتطبيق، لديك الحقوق التالية:\n\n• الوصول الكامل لجميع بياناتك\n• تعديل أو حذف أي معلومات\n• تصدير بياناتك في أي وقت\n• حذف التطبيق وجميع البيانات نهائياً\n• استخدام التطبيق بدون قيود',
                  Icons.person_outline_rounded,
                ),
                _buildSection(
                  context,
                  'التواصل والاستفسار',
                  'إذا كان لديك أي أسئلة حول سياسة الخصوصية أو كيفية التعامل مع بياناتك، يمكنك التواصل معنا. نحن ملتزمون بالشفافية الكاملة حول استخدام بياناتك.',
                  Icons.contact_support_rounded,
                ),
                _buildSection(
                  context,
                  'تحديثات السياسة',
                  'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. أي تغييرات ستكون واضحة ومعلنة في التطبيق. استمرار استخدامك للتطبيق يعني موافقتك على السياسة المحدثة.',
                  Icons.update_rounded,
                ),
                
                // Security Guarantee Bento Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.successColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'بياناتك المالية آمنة ومحمية محلياً 100%',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Center(
                  child: Text(
                    'آخر تحديث: مايو 2026',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
