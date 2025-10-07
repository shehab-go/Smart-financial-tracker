import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:in_app_update/in_app_update.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/features/expenses/presentation/screens/expense_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    // Check for updates only on Android
    if (!kIsWeb && Platform.isAndroid) {
      checkForUpdate();
    }
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  Future<void> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        
        // Listen for update download completion
        _listenForUpdateStatus();
      }
    } catch (e) {
      // Handle update check errors silently
      debugPrint('Update check failed: $e');
    }
  }

  void _listenForUpdateStatus() {
    // Check update status periodically
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final updateInfo = await InAppUpdate.checkForUpdate();
        if (updateInfo.installStatus == InstallStatus.downloaded) {
          timer.cancel();
          _showUpdateReadySnackBar();
        }
      } catch (e) {
        timer.cancel();
        debugPrint('Update status check failed: $e');
      }
    });
  }

  void _showUpdateReadySnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تحديث جديد جاهز للتثبيت!'),
        duration: const Duration(days: 1), // Make it persistent
        action: SnackBarAction(
          label: 'إعادة التشغيل',
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              debugPrint('Failed to complete update: $e');
            }
          },
        ),
      ),
    );
  }

  List<Widget> get _screens => [
    HomeScreen(onDrawerChanged: _onDrawerChanged),
    ExpenseScreen(onDrawerChanged: _onDrawerChanged),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _isDrawerOpen ? null : Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'الديون',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'المصروفات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}