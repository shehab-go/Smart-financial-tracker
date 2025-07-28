import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/currencies_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'إدارة الحسابات المالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تطبيق شامل لإدارة أموالك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Theme.of(context).primaryColor),
            title: const Text('الرئيسية'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.category, color: Theme.of(context).primaryColor),
            title: const Text('إدارة الفئات'),
            subtitle: const Text('إضافة وتعديل فئات الحسابات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.monetization_on, color: Theme.of(context).primaryColor),
            title: const Text('إدارة العملات'),
            subtitle: const Text('إضافة وتعديل العملات المستخدمة'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrenciesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.share, color: Theme.of(context).primaryColor),
            title: const Text('مشاركة التطبيق'),
            subtitle: const Text('شارك التطبيق مع الأصدقاء'),
            onTap: () {
              Navigator.pop(context);
              _shareApp();
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info, color: Theme.of(context).primaryColor),
            title: const Text('حول التطبيق'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
            title: const Text('سياسة الخصوصية'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyScreen()),
              );
            },
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
