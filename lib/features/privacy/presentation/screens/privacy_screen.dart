import 'package:flutter/material.dart';
import '../../../../core/widgets/main_navigation.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigation()),
                (route) => false,
              );
              // Open drawer after navigation
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.privacy_tip,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'سياسة الخصوصية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'نحن نحترم خصوصيتك ونحمي بياناتك',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildSection(
                context,
                'جمع البيانات',
                'تطبيق إدارة الحسابات المالية لا يجمع أي بيانات شخصية أو مالية من المستخدمين. جميع المعلومات التي تدخلها في التطبيق تبقى محفوظة محلياً على جهازك فقط.',
                Icons.data_usage,
              ),
              _buildSection(
                context,
                'التخزين المحلي',
                'يستخدم التطبيق قاعدة بيانات محلية (SQLite) لحفظ معلوماتك المالية على جهازك مباشرة. هذا يعني أن:\n\n• بياناتك لا تغادر جهازك أبداً\n• لا توجد خوادم خارجية تحتفظ بمعلوماتك\n• أنت المتحكم الوحيد في بياناتك\n• يمكنك استخدام التطبيق بدون إنترنت',
                Icons.storage,
              ),
              _buildSection(
                context,
                'عدم الاتصال بالإنترنت',
                'التطبيق مصمم للعمل بدون إنترنت بالكامل. لا يقوم بإرسال أي معلومات إلى الإنترنت أو استقبال أي بيانات من مصادر خارجية. هذا يضمن الحماية الكاملة لخصوصيتك.',
                Icons.wifi_off,
              ),
              _buildSection(
                context,
                'أمان البيانات',
                'نتخذ الإجراءات التالية لضمان أمان بياناتك:\n\n• التخزين المحلي الآمن باستخدام SQLite\n• عدم مشاركة البيانات مع أطراف ثالثة\n• عدم وجود اتصال بخوادم خارجية\n• حماية البيانات من خلال نظام تشغيل الجهاز\n• إمكانية النسخ الاحتياطي المحلي',
                Icons.security,
              ),
              _buildSection(
                context,
                'حقوق المستخدم',
                'كمستخدم للتطبيق، لديك الحقوق التالية:\n\n• الوصول الكامل لجميع بياناتك\n• تعديل أو حذف أي معلومات\n• تصدير بياناتك في أي وقت\n• حذف التطبيق وجميع البيانات نهائياً\n• استخدام التطبيق بدون قيود',
                Icons.person_outline,
              ),
              _buildSection(
                context,
                'التواصل',
                'إذا كان لديك أي أسئلة حول سياسة الخصوصية أو كيفية التعامل مع بياناتك، يمكنك التواصل معنا. نحن ملتزمون بالشفافية الكاملة حول استخدام بياناتك.',
                Icons.contact_support,
              ),
              _buildSection(
                context,
                'تحديثات السياسة',
                'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. أي تغييرات ستكون واضحة ومعلنة في التطبيق. استمرار استخدامك للتطبيق يعني موافقتك على السياسة المحدثة.',
                Icons.update,
              ),
              const SizedBox(height: 8),
              // Security Guarantee Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'بياناتك آمنة ومحمية 100%',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'آخر تحديث: يناير 2024',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
