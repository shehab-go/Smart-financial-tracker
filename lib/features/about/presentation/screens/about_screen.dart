import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'حول التطبيق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Header Bento Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 36,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'حسابات يومية',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontFamily: 'ArbFONTSIBMPlexArabicText',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'الإصدار 1.3.10',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontFamily: 'ArbFONTSIBMPlexArabicText',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Developer Contact Bento Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.support_agent,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'معلومات التواصل مع المطورين',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Developer 1: Ramzi Hydan
                      const Text(
                        'المطور: رمزي حيدان',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '+967 776776287',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 105,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final Uri telUri = Uri(scheme: 'tel', path: '+967776776287');
                                if (await canLaunchUrl(telUri)) {
                                  await launchUrl(telUri, mode: LaunchMode.externalApplication);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.call, size: 16, color: Colors.white),
                              label: const Text(
                                'اتصال',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/whatsapp.svg',
                            colorFilter: const ColorFilter.mode(
                              AppTheme.primaryColor,
                              BlendMode.srcIn,
                            ),
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'رسالة واتساب',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 105,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final Uri waWebUri = Uri.parse('https://wa.me/message/6D7NMPO3S7R2N1');
                                await launchUrl(waWebUri, mode: LaunchMode.externalApplication);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: SvgPicture.asset(
                                'assets/images/whatsapp.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 16,
                                height: 16,
                              ),
                              label: const Text(
                                'واتساب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      
                      // Developer 2: Shihab Al-Din Al-Shumairi
                      const Text(
                        'المطور: شهاب الدين الشميري',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '+967 775428416',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 105,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final Uri telUri = Uri(scheme: 'tel', path: '+967775428416');
                                if (await canLaunchUrl(telUri)) {
                                  await launchUrl(telUri, mode: LaunchMode.externalApplication);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.call, size: 16, color: Colors.white),
                              label: const Text(
                                'اتصال',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/whatsapp.svg',
                            colorFilter: const ColorFilter.mode(
                              AppTheme.primaryColor,
                              BlendMode.srcIn,
                            ),
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'رسالة واتساب',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ArbFONTSIBMPlexArabicText',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 105,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final Uri waWebUri = Uri.parse('https://wa.me/967775428416');
                                await launchUrl(waWebUri, mode: LaunchMode.externalApplication);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: SvgPicture.asset(
                                'assets/images/whatsapp.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 16,
                                height: 16,
                              ),
                              label: const Text(
                                'واتساب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  context,
                  'وصف التطبيق',
                  'تطبيق «حسابات يومية» هو حل مالي متكامل ومصمم خصيصاً لإدارة ومتابعة المعاملات المالية، الديون، والمدفوعات اليومية للأفراد والمؤسسات الصغيرة والمتوسطة بدقة وسهولة فائقة. يهدف التطبيق إلى تبسيط العمليات المحاسبية اليومية عبر تسجيل فوري للقيود الحسابية (لك / عليك)، وتصنيف المعاملات بمرونة تحت فئات مخصصة (عملاء، موردين، حسابات شخصية)، مع تقديم كشوفات حساب تفصيلية بصيغة PDF قابلة للمشاركة. كما يتيح التطبيق تحليلاً ذكياً لتدفقاتك المالية عبر رسومات بيانية متقدمة وإحصائيات فورية لمراقبة الأرباح والخسائر والسيولة النقدية، كل ذلك مع ضمان السرية التامة لبياناتك بفضل التخزين المحلي الآمن ونظام النسخ الاحتياطي السحابي والمحلي المتطور.',
                  Icons.description_outlined,
                ),
                _buildSection(
                  context,
                  'المميزات الرئيسية',
                  '• إدارة الديون والالتزامات: تسجيل وتتبع معاملات (لك / عليك) للعملاء والموردين بدقة متناهية.\n'
                      '• تنظيم وتصنيف الفئات: تصنيف الحسابات بشكل مرن وفصل حسابات العملاء عن الموردين والحسابات العامة.\n'
                      '• نظام نسخ احتياطي متطور: دعم النسخ الاحتياطي الداخلي وحفظه على الجهاز، أو السحابي عبر ربط التطبيق بحساب Google Drive بأمان تام لضمان عدم فقدان البيانات.\n'
                      '• دعم العملات المتعددة: إدارة الحسابات والمعاملات بعملات مختلفة (ريال سعودي، دولار أمريكي، ريال يمني) لتسهيل التعاملات المتنوعة.\n'
                      '• تقارير تفصيلية ورسوم بيانية: إصدار كشوفات حساب تفصيلية وتصديرها بصيغة PDF ومشاركتها مع إحصائيات بصرية ومخططات متقدمة لتدفقاتك المالية.\n'
                      '• حماية الأمان والخصوصية: إمكانية قفل التطبيق عبر البصمة الحيوية (Biometrics) أو رمز المرور، مع الحفاظ على سرية بياناتك محلياً 100% دون الحاجة للاتصال بالإنترنت.\n'
                      '• واجهة مستخدم Bento Premium: تصميم Fintech عصري ومذهل بنظام ألوان Teal ناعم ومريح للعين مع تجربة تفاعلية لمسية (Haptic Feedback) متميزة.',
                  Icons.star_outline_rounded,
                ),
                _buildSection(
                  context,
                  'الخصوصية والأمان',
                  'جميع بياناتك المالية والشخصية يتم تشفيرها وحفظها محلياً على جهازك مباشرة باستخدام قاعدة بيانات SQLite. لا يتم مشاركة أو نقل أي معلومات إلى خوادم خارجية، مما يمنحك السيطرة والخصوصية المطلقة بنسبة 100% دون الحاجة إلى اتصال بالإنترنت.',
                  Icons.security_outlined,
                ),
                _buildSection(
                  context,
                  'التواصل والدعم',
                  'فريق التطوير يرحب بكافة الاقتراحات والاستفسارات لتحسين وتطوير التطبيق باستمرار. يمكنك التواصل معنا مباشرة عبر وسائل الاتصال المتاحة أعلاه لمشاركتنا ملاحظاتك أو للإبلاغ عن أي مشكلة.',
                  Icons.chat_bubble_outline_rounded,
                ),
                
                // Copyright Bento Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.copyright_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '© 2026 تطبيق حسابات يومية',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'جميع الحقوق محفوظة',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'ArbFONTSIBMPlexArabicText',
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
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w500,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
        ],
      ),
    );
  }
}
