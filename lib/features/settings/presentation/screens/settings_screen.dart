import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:debit_credit_app/features/about/presentation/screens/about_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/privacy_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/security_settings_screen.dart';
import 'package:debit_credit_app/features/backup/presentation/screens/enhanced_backup_screen.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/features/home/application/reports/all_accounts_report_generator.dart';
import 'package:debit_credit_app/core/widgets/main_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _autoBackup = false;
  String _selectedLanguage = 'العربية';
  String _selectedCurrency = 'ريال سعودي';
  String _lastBackupText = 'جاري التحميل...';
  
  final List<String> _languages = ['العربية', 'English'];
  final List<String> _currencies = ['ريال سعودي', 'دولار أمريكي', 'ريال يمني'];

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final enabled = await AutoBackupManager.instance.isEnabled();
    final lastMs = await AutoBackupManager.instance.getLastBackupMs();
    String lastText;
    if (lastMs == null) {
      lastText = 'لم يُحفظ سحابياً بعد ☁️';
    } else {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
      lastText = 'آخر حفظ: ${DateFormat('yyyy/MM/dd HH:mm').format(lastDate)} ☁️';
    }
    if (!mounted) return;
    setState(() {
      _autoBackup = enabled;
      _lastBackupText = lastText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.textPrimary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return;
              }
  
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigation()),
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // User Profile Section
              _buildSectionCard(
                title: 'الملف الشخصي',
                icon: Icons.person_rounded,
                children: [
                  _buildSettingsTile(
                    icon: Icons.account_circle_rounded,
                    title: 'إدارة الملف الشخصي',
                    subtitle: 'تعديل المعلومات الشخصية والصورة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // App Preferences Section
              _buildSectionCard(
                title: 'تفضيلات التطبيق',
                icon: Icons.tune_rounded,
                children: [
                  _buildSwitchTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'الوضع المظلم',
                    subtitle: 'تفعيل المظهر المظلم للتطبيق',
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      // TODO: Implement theme switching
                    },
                  ),
                  _buildDropdownTile(
                    icon: Icons.language_rounded,
                    title: 'اللغة',
                    subtitle: 'اختيار لغة التطبيق',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      // TODO: Implement language switching
                    },
                  ),
                  _buildDropdownTile(
                    icon: Icons.monetization_on_rounded,
                    title: 'العملة الافتراضية',
                    subtitle: 'العملة المستخدمة في التطبيق',
                    value: _selectedCurrency,
                    items: _currencies,
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                      // TODO: Implement currency switching
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Notifications Section
              _buildSectionCard(
                title: 'الإشعارات',
                icon: Icons.notifications_rounded,
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'تفعيل الإشعارات',
                    subtitle: 'استقبال إشعارات التطبيق',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      // TODO: Implement notification settings
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'تذكيرات الدفع',
                    subtitle: 'إعداد تذكيرات المواعيد المالية',
                    onTap: () {
                      // TODO: Navigate to payment reminders settings
                      _showComingSoonDialog();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Backup & Security Section
              _buildSectionCard(
                title: 'النسخ الاحتياطية والأمان',
                icon: Icons.security_rounded,
                children: [
                  _buildSwitchTile(
                    icon: Icons.backup_rounded,
                    title: 'النسخ الاحتياطي التلقائي',
                    subtitle: 'إنشاء نسخة احتياطية تلقائياً',
                    value: _autoBackup,
                    onChanged: (value) {
                      setState(() {
                        _autoBackup = value;
                      });
                      AutoBackupManager.instance.setEnabled(value);
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.cloud_rounded,
                    title: 'Google Drive Backup',
                    subtitle: 'إدارة النسخ السحابية | $_lastBackupText',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedBackupScreen(initialTabIndex: 1),
                        ),
                      ).then((_) => _loadBackupSettings());
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.backup_table_rounded,
                    title: 'إدارة النسخ الاحتياطية',
                    subtitle: 'إنشاء واستعادة النسخ الاحتياطية',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedBackupScreen(initialTabIndex: 0),
                        ),
                      ).then((_) => _loadBackupSettings());
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.lock_rounded,
                    title: 'الحماية بكلمة مرور',
                    subtitle: 'حماية التطبيق بكلمة مرور أو بصمة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecuritySettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Data Management Section
              _buildSectionCard(
                title: 'إدارة البيانات',
                icon: Icons.storage_rounded,
                children: [
                  _buildSettingsTile(
                    icon: Icons.cleaning_services_rounded,
                    title: 'تنظيف البيانات',
                    subtitle: 'حذف البيانات المؤقتة والملفات غير المستخدمة',
                    onTap: () {
                      _showCleanDataDialog();
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.file_download_rounded,
                    title: 'تصدير البيانات',
                    subtitle: 'تصدير كشف حساب شامل بصيغة PDF 📄',
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      try {
                        final dbHelper = DatabaseHelper();
                        final accounts = await dbHelper.getAccountsWithStatsUsingAccountCurrencyAllCategories();
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close loading indicator
                        if (accounts.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('لا توجد حسابات أو معاملات للتصدير حالياً'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        await AllAccountsReportGenerator.generate(
                          allAccounts: accounts,
                          currencyFilterName: 'all',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تصدير كشف الحساب الشامل بنجاح 📄'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ أثناء التصدير: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'حذف جميع البيانات',
                    subtitle: 'حذف جميع البيانات نهائياً',
                    textColor: AppTheme.errorColor,
                    onTap: () {
                      _showDeleteAllDataDialog();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Support & Info Section
              _buildSectionCard(
                title: 'الدعم والمعلومات',
                icon: Icons.help_rounded,
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_rounded,
                    title: 'حول التطبيق',
                    subtitle: 'معلومات التطبيق والإصدار',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'سياسة الخصوصية',
                    subtitle: 'اطلع على سياسة الخصوصية',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.star_rate_rounded,
                    title: 'تقييم التطبيق',
                    subtitle: 'قيم التطبيق في المتجر',
                    onTap: () {
                      // TODO: Implement app rating
                      _showComingSoonDialog();
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.bug_report_rounded,
                    title: 'الإبلاغ عن مشكلة',
                    subtitle: 'أرسل تقرير عن مشكلة في التطبيق',
                    onTap: () {
                      // TODO: Implement bug reporting
                      _showComingSoonDialog();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // App Version
              Center(
                child: Text(
                  'إصدار التطبيق 1.0.0',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.dividerColor.withOpacity(0.5), height: 1, thickness: 1),
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.primaryColor.withOpacity(0.8),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textPrimary,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded, // Points to left in RTL for forward navigation
        size: 20,
        color: AppTheme.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor.withOpacity(0.8),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.2),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor.withOpacity(0.8),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'قريباً',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          content: const Text(
            'هذه الميزة ستكون متاحة في التحديث القادم.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCleanDataDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تنظيف البيانات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          content: const Text(
            'هل تريد حذف البيانات المؤقتة؟ هذا لن يؤثر على بياناتك الأساسية.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement data cleaning
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تنظيف البيانات المؤقتة بنجاح'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('تنظيف', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تحذير!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.errorColor,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          content: const Text(
            'هل أنت متأكد من حذف جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.\n\nننصح بإنشاء نسخة احتياطية أولاً.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete all data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف جميع البيانات'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}