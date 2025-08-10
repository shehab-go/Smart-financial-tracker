import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.privacy_tip, size: 64, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    Text('سياسة الخصوصية', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 8),
                    Text('نحن نحترم خصوصيتك ونحمي بياناتك', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('بياناتك آمنة ومحمية 100%', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('آخر تحديث: يناير 2024', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}
