import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debit_credit_app/features/about/presentation/screens/about_screen.dart';
import 'package:debit_credit_app/features/privacy/presentation/screens/privacy_screen.dart';
import 'package:debit_credit_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:debit_credit_app/features/currencies/presentation/screens/currencies_screen.dart';
import 'package:debit_credit_app/features/backup/presentation/screens/backup_screen.dart';
import 'package:debit_credit_app/features/profile/presentation/screens/user_profile_screen.dart';
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
      child: Drawer(
        backgroundColor: Colors.grey.shade50,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false, // Allow bottom content to extend
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                       width: 60,
                                       height: 60,
                                       decoration: BoxDecoration(
                                         color: Colors.white.withOpacity(0.2),
                                         border: Border.all(
                                           color: Colors.white.withOpacity(0.3),
                                           width: 2,
                                         ),
                                       ),
                                       child: _userProfile?.logoPath != null
                                            ? Image.file(
                                                  File(_userProfile!.logoPath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.person_rounded,
                                                      size: 30,
                                                      color: Colors.white,
                                                    );
                                                  },
                                                )
                                            : const Icon(
                                                Icons.person_rounded,
                                                size: 30,
                                                color: Colors.white,
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
                                                      : 'إدارة الحسابات المالية',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                           const SizedBox(height: 4),
                                           if (_userProfile?.tradingActivity?.isNotEmpty == true)
                                             Text(
                                               _userProfile!.tradingActivity!,
                                               style: TextStyle(
                                                 color: Colors.white.withOpacity(0.9),
                                                 fontSize: 14,
                                                 fontWeight: FontWeight.w500,
                                               ),
                                               maxLines: 2,
                                               overflow: TextOverflow.ellipsis,
                                             )
                                           else
                                             Text(
                                               'تطبيق شامل لإدارة أموالك بذكاء',
                                               style: TextStyle(
                                                 color: Colors.white.withOpacity(0.9),
                                                 fontSize: 14,
                                                 fontWeight: FontWeight.w500,
                                               ),
                                             ),
                                         ],
                                       ),
                                     ),
                                     // Edit Profile Button
                                     Container(
                                       margin: const EdgeInsets.only(left: 8),
                                       child: Material(
                                         color: Colors.white.withOpacity(0.2),
                                         shape: const RoundedRectangleBorder(
                                           borderRadius: BorderRadius.zero,
                                         ),
                                         child: InkWell(
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
                                             padding: const EdgeInsets.all(8),
                                             child: const Icon(
                                               Icons.edit_rounded,
                                               color: Colors.white,
                                               size: 20,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                if (_userProfile?.phone?.isNotEmpty == true) ...[
                                  const SizedBox(height: 16),
                                  if (_userProfile?.phone?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            size: 16,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _userProfile!.phone!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
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
                const SizedBox(height: 8),
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
                  subtitle: 'إنشاء أو استعادة قاعدة البيانات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BackupScreen()),
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
                const SizedBox(height: 8),
              ]),
            ),
          ],
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textSecondary.withOpacity(0.6),
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
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
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
