import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:debit_credit_app/features/about/presentation/screens/about_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/privacy_screen.dart';
import 'package:debit_credit_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:debit_credit_app/features/currencies/presentation/screens/currencies_screen.dart';
import 'package:debit_credit_app/features/backup/presentation/screens/enhanced_backup_screen.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/smart_dashboard_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/smart_radar_screen.dart';
import 'package:debit_credit_app/features/balances/presentation/screens/income_balances_screen.dart';
import 'package:debit_credit_app/features/installments/presentation/screens/installments_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/user_profile.dart';
import 'package:debit_credit_app/core/services/google_drive_backup_service.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:debit_credit_app/core/services/region_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserProfile? _userProfile;
  String? _googlePhotoUrl;
  String? _googleEmail;
  bool _isLoading = true;
  final RegionService _regionService = RegionService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final dbHelper = DatabaseHelper();
      final profile = await dbHelper.getUserProfile();
      String? googlePhoto;
      String? googleEmail;
      try {
        if (await GoogleDriveBackupService.instance.isSignedIn()) {
          googlePhoto = await GoogleDriveBackupService.instance.currentPhotoUrl();
          googleEmail = await GoogleDriveBackupService.instance.currentEmail();
          if (googleEmail != null) {
            await dbHelper.setMetaValue(AutoBackupManager.metaAccountEmail, googleEmail);
          }
        }
      } catch (_) {}

      if (googleEmail == null) {
        googleEmail = await dbHelper.getMetaValue(AutoBackupManager.metaAccountEmail);
        if (googleEmail != null && googleEmail.isEmpty) {
          googleEmail = null;
        }
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _googlePhotoUrl = googlePhoto;
          _googleEmail = googleEmail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: const Color(0xFFF1F5F9), // Light background
        elevation: 0,
        width: MediaQuery.of(context).size.width * 0.82,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.only(
            topEnd: Radius.circular(24),
            bottomEnd: Radius.circular(24),
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadiusDirectional.only(
              topEnd: Radius.circular(24),
              bottomEnd: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header (Premium Gradient Card with Wave effect)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 48, bottom: 20),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadiusDirectional.only(
                        bottomEnd: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Premium Profile Circle
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: _userProfile?.logoPath != null
                                            ? Image.file(
                                                File(_userProfile!.logoPath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  if (_googlePhotoUrl != null && _googlePhotoUrl!.isNotEmpty) {
                                                    return CachedNetworkImage(
                                                      imageUrl: _googlePhotoUrl!,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) {
                                                        return const Icon(
                                                          Icons.person_rounded,
                                                          size: 32,
                                                          color: Colors.white,
                                                        );
                                                      },
                                                    );
                                                  }
                                                  return const Icon(
                                                    Icons.person_rounded,
                                                    size: 32,
                                                    color: Colors.white,
                                                  );
                                                },
                                              )
                                            : (_googlePhotoUrl != null && _googlePhotoUrl!.isNotEmpty)
                                                ? CachedNetworkImage(
                                                    imageUrl: _googlePhotoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, url, error) {
                                                      return const Icon(
                                                        Icons.person_rounded,
                                                        size: 32,
                                                        color: Colors.white,
                                                      );
                                                    },
                                                  )
                                                : const Icon(
                                                    Icons.person_rounded,
                                                    size: 32,
                                                    color: Colors.white,
                                                  ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _userProfile?.fullName?.isNotEmpty == true
                                                ? _userProfile!.fullName!
                                                : _userProfile?.businessName?.isNotEmpty == true
                                                    ? _userProfile!.businessName!
                                                    : 'حسابات يومية',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _userProfile?.tradingActivity?.isNotEmpty == true
                                                ? _userProfile!.tradingActivity!
                                                : 'تطبيق شامل لإدارة أموالك بذكاء',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.85),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (_googleEmail != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.cloud_done_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _googleEmail!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            GestureDetector(
                                              onTap: () async {
                                                try {
                                                  final account = await GoogleDriveBackupService.instance.signIn();
                                                  if (account != null) {
                                                    final photo = await GoogleDriveBackupService.instance.currentPhotoUrl();
                                                    final email = await GoogleDriveBackupService.instance.currentEmail();
                                                    if (email != null) {
                                                      await DatabaseHelper().setMetaValue(AutoBackupManager.metaAccountEmail, email);
                                                    }
                                                    setState(() {
                                                      _googlePhotoUrl = photo;
                                                      _googleEmail = email;
                                                    });
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('تم ربط جوجل درايف بنجاح!'),
                                                          backgroundColor: AppTheme.primaryColor,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(e.toString()),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.add_to_drive_rounded,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'ربط جوجل درايف',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_userProfile?.phone?.isNotEmpty == true) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phone_android_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _userProfile!.phone!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
                
                // Drawer Items list
                SliverList(
                  delegate: SliverChildListDelegate([
                    if (_regionService.isRadarEnabled) ...[
                      _buildSectionDivider('الراصد والذكاء المالي 📡'),
                      _buildDrawerItem(
                        context,
                        icon: Icons.radar_rounded,
                        title: 'الراصد والذكاء المالي',
                        subtitle: 'مراقبة الإشعارات البنكية والتنبهات الذكية',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SmartRadarScreen()),
                          );
                        },
                      ),
                    ],
                    _buildSectionDivider('الالتزامات والتنبيهات 📅'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calendar_month_rounded,
                      title: 'الأقساط والالتزامات المجدولة',
                      subtitle: 'إدارة وتنبيهات الأقساط الشهرية والفواتير',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InstallmentsScreen()),
                        );
                      },
                    ),
                    _buildSectionDivider('إدارة البيانات'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.account_balance_rounded,
                      title: 'الأرصدة والسيولة',
                      subtitle: 'إدارة وتتبع أرصدة الخزن والصناديق',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const IncomeBalancesScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.backup_table_rounded,
                      title: 'النسخ الاحتياطي',
                      subtitle: 'إدارة النسخ الاحتياطية سحابياً ومحلياً',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EnhancedBackupScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.grid_view_rounded,
                      title: 'إدارة الفئات',
                      subtitle: 'إضافة وتعديل فئات الحسابات',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.currency_exchange_rounded,
                      title: 'إدارة العملات',
                      subtitle: 'إضافة وتعديل العملات المستخدمة',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CurrenciesScreen()),
                        );
                      },
                    ),
                    _buildSectionDivider('خيارات وأمان'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.security_rounded,
                      title: 'سياسة الخصوصية والأمان',
                      subtitle: 'خيارات الأمان وحماية خصوصية بياناتك',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                        );
                      },
                    ),

                    _buildSectionDivider('تواصل وتحديث'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.new_releases_rounded,
                      title: 'تحديث التطبيق',
                      subtitle: 'احصل على آخر التحديثات الرسمية',
                      onTap: () {
                        Navigator.pop(context);
                        _openAppInPlayStore();
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.share_location_rounded,
                      title: 'مشاركة التطبيق',
                      subtitle: 'شارك الأداة المالية مع شبكتك التجارية',
                      onTap: () {
                        Navigator.pop(context);
                        _shareApp();
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.workspace_premium_rounded,
                      title: 'حول التطبيق',
                      subtitle: 'معلومات إصدار الأداة وفريق العمل',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryColor.withOpacity(0.04),
          highlightColor: AppTheme.primaryColor.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon wrapper
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: AppTheme.textTertiary,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.dividerColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'تطبيق حسابات يومية - تطبيق رائع لإدارة أموالك بسهولة وأمان!\n\n'
      'يمكنك تتبع جميع معاملاتك المالية، تنظيم حساباتك حسب الفئات، وإدارة أموالك بشكل فعال.\n\n'
      'التطبيق يعمل بدون إنترنت ويحافظ على خصوصية بياناتك المالية.\n\n'
      'حمل التطبيق الآن:\nhttps://play.google.com/store/apps/details?id=com.ramzi.debit_credit_app',
      subject: 'تطبيق حسابات يومية',
    );
  }

  Future<void> _openAppInPlayStore() async {
    const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.ramzi.debit_credit_app';
    final Uri uri = Uri.parse(playStoreUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح متجر التطبيقات'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء فتح متجر التطبيقات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
