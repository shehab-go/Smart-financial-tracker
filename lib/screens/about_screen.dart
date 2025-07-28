import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إدارة الحسابات المالية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الإصدار 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            _buildSection(
              context,
              'وصف التطبيق',
              'تطبيق شامل لإدارة أموالك الشخصية بطريقة منظمة وآمنة. يمكنك من خلاله تتبع جميع معاملاتك المالية، تنظيم حساباتك حسب الفئات المختلفة، ومراقبة أرصدتك بسهولة.',
              Icons.description,
            ),

            // Features
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

            // Privacy & Security
            _buildSection(
              context,
              'الخصوصية والأمان',
              'جميع بياناتك محفوظة محلياً على جهازك فقط. لا يتم إرسال أي معلومات إلى خوادم خارجية أو الإنترنت. بياناتك المالية آمنة ومحمية بالكامل.',
              Icons.security,
            ),

            // Contact
            _buildSection(
              context,
              'التواصل والدعم',
              'إذا كان لديك أي استفسارات أو اقتراحات لتطوير التطبيق، يمكنك التواصل معنا. نحن نقدر ملاحظاتك ونسعى لتحسين التطبيق باستمرار.',
              Icons.support_agent,
            ),

            const SizedBox(height: 32),

            // Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2024 تطبيق إدارة الحسابات المالية',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جميع الحقوق محفوظة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
