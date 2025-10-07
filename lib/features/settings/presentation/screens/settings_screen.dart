import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/features/about/presentation/screens/about_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/privacy_screen.dart';
import 'package:debit_credit_app/features/backup/presentation/screens/enhanced_backup_screen.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
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
  
  final List<String> _languages = ['العربية', 'English'];
  final List<String> _currencies = ['ريال سعودي', 'دولار أمريكي', 'ريال يمني'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: AppTheme.primaryColor,
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                    // TODO: Implement auto backup
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
                        builder: (context) => const EnhancedBackupScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.lock_rounded,
                  title: 'الحماية بكلمة مرور',
                  subtitle: 'حماية التطبيق بكلمة مرور أو بصمة',
                  onTap: () {
                    // TODO: Navigate to security settings
                    _showComingSoonDialog();
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
                  subtitle: 'تصدير البيانات بصيغة Excel أو PDF',
                  onTap: () {
                    // TODO: Implement data export
                    _showComingSoonDialog();
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
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppTheme.primaryColor).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Directionality(
        textDirection: TextDirection.rtl,
        child: DropdownButton<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          underline: Container(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قريباً'),
        content: const Text('هذه الميزة ستكون متاحة في التحديث القادم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showCleanDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنظيف البيانات'),
        content: const Text('هل تريد حذف البيانات المؤقتة؟ هذا لن يؤثر على بياناتك الأساسية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
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
            ),
            child: const Text('تنظيف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تحذير!',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.\n\nننصح بإنشاء نسخة احتياطية أولاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
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
            ),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}