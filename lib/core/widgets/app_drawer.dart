import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/about/presentation/screens/about_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/privacy_screen.dart';
import 'package:debit_credit_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:debit_credit_app/features/currencies/presentation/screens/currencies_screen.dart';
import 'package:debit_credit_app/features/backup/presentation/screens/enhanced_backup_screen.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:debit_credit_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:debit_credit_app/core/models/user_profile.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final dbHelper = DatabaseHelper();
      final profile = await dbHelper.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
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
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Drawer(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              collapsedHeight: 60,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.grey.shade50,
              title: null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false, // Allow bottom content to extend
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                   children: [
                                     Container(
                                       width: 50,
                                       height: 50,
                                       decoration: BoxDecoration(
                                         color: Colors.grey.shade100,
                                         border: Border.all(
                                           color: Colors.grey.shade300,
                                           width: 1,
                                         ),
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                       child: _userProfile?.logoPath != null
                                            ? Image.file(
                                                  File(_userProfile!.logoPath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.person_rounded,
                                                      size: 24,
                                                      color: Colors.grey.shade600,
                                                    );
                                                  },
                                                )
                                            : Icon(
                                                Icons.person_rounded,
                                                size: 24,
                                                color: Colors.grey.shade600,
                                              ),
                                     ),
                                     const SizedBox(width: 12),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                              _userProfile?.fullName?.isNotEmpty == true
                                                  ? _userProfile!.fullName!
                                                  : _userProfile?.businessName?.isNotEmpty == true
                                                      ? _userProfile!.businessName!
                                                      : 'إدارة الحسابات المالية',
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                           const SizedBox(height: 4),
                                           if (_userProfile?.tradingActivity?.isNotEmpty == true)
                                             Text(
                                               _userProfile!.tradingActivity!,
                                               style: TextStyle(
                                                 color: Colors.grey.shade600,
                                                 fontSize: 13,
                                                 fontWeight: FontWeight.w400,
                                               ),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             )
                                           else
                                             Text(
                                               'تطبيق شامل لإدارة أموالك بذكاء',
                                               style: TextStyle(
                                                 color: Colors.grey.shade600,
                                                 fontSize: 13,
                                                 fontWeight: FontWeight.w400,
                                               ),
                                             ),
                                         ],
                                       ),
                                     ),
                                     // Edit Profile Button
                                     Container(
                                       margin: const EdgeInsets.only(left: 8),
                                       child: Material(
                                         color: Colors.grey.shade200,
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(6),
                                         ),
                                         child: InkWell(
                                           borderRadius: BorderRadius.circular(6),
                                           onTap: () async {
                                             final result = await Navigator.push(
                                               context,
                                               MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                                             );
                                             // Refresh profile data when returning from profile screen
                                             if (result == true) {
                                               _loadUserProfile();
                                             }
                                           },
                                           child: Container(
                                             padding: const EdgeInsets.all(6),
                                             child: Icon(
                                               Icons.edit_rounded,
                                               color: Colors.grey.shade600,
                                               size: 18,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                if (_userProfile?.phone?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  if (_userProfile?.phone?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _userProfile!.phone!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
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
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  onTap: () => Navigator.pop(context),
                ),
                _buildSectionDivider('إدارة البيانات'),
                _buildDrawerItem(
                  context,
                  icon: Icons.backup_rounded,
                  title: 'النسخ الاحتياطية',
                  subtitle: 'إنشاء أو استعادة قاعدة البيانات مع الحماية المتقدمة',
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
                  icon: Icons.category_rounded,
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
                  icon: Icons.monetization_on_rounded,
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
                _buildSectionDivider('أخرى'),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'الإعدادات',
                  subtitle: 'إعدادات التطبيق والتفضيلات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.share_rounded,
                  title: 'مشاركة التطبيق',
                  subtitle: 'شارك التطبيق مع الأصدقاء',
                  onTap: () {
                    Navigator.pop(context);
                    _shareApp();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_rounded,
                  title: 'حول التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  title: 'سياسة الخصوصية',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ],
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.grey.withOpacity(0.1),
          highlightColor: Colors.grey.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
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
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.4),
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'تطبيق إدارة الحسابات المالية - تطبيق رائع لإدارة أموالك بسهولة وأمان!\n\n'
      'يمكنك تتبع جميع معاملاتك المالية، تنظيم حساباتك حسب الفئات، وإدارة أموالك بشكل فعال.\n\n'
      'التطبيق يعمل بدون إنترنت ويحافظ على خصوصية بياناتك المالية.',
      subject: 'تطبيق إدارة الحسابات المالية',
    );
  }
}
