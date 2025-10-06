import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_navigation.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حول التطبيق'),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'إدارة الحسابات المالية',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'الإصدار 1.0.0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                'وصف التطبيق',
                'تطبيق شامل لإدارة أموالك الشخصية بطريقة منظمة وآمنة. يمكنك من خلاله تتبع جميع معاملاتك المالية، تنظيم حساباتك حسب الفئات المختلفة، ومراقبة أرصدتك بسهولة.',
                Icons.description,
              ),
              _buildSection(
                context,
                'المميزات الرئيسية',
                '• إدارة الحسابات والمعاملات المالية\n'
                    '• تنظيم الحسابات حسب الفئات (عام، مورد، عميل، طعام، إلخ)\n'
                    '• تتبع المدفوعات والمقبوضات\n'
                    '• عرض الأرصدة والإجماليات\n'
                    '• دعم عملات متعددة (ريال سعودي، دولار، ريال يمني)\n'
                    '• واجهة باللغة العربية بالكامل\n'
                    '• يعمل بدون إنترنت (حفظ محلي)\n'
                    '• حماية كاملة لخصوصية البيانات',
                Icons.star,
              ),
              _buildSection(
                context,
                'الخصوصية والأمان',
                'جميع بياناتك محفوظة محلياً على جهازك فقط. لا يتم إرسال أي معلومات إلى خوادم خارجية أو الإنترنت. بياناتك المالية آمنة ومحمية بالكامل.',
                Icons.security,
              ),
              _buildSection(
                context,
                'التواصل والدعم',
                'إذا كان لديك أي استفسارات أو اقتراحات لتطوير التطبيق، يمكنك التواصل معنا. نحن نقدر ملاحظاتك ونسعى لتحسين التطبيق باستمرار.',
                Icons.support_agent,
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.copyright,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2024 تطبيق إدارة الحسابات المالية',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جميع الحقوق محفوظة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
