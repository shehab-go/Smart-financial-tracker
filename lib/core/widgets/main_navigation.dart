import 'dart:async';
import 'package:flutter/material.dart';
import 'package:debit_credit_app/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/features/expenses/presentation/screens/expense_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/services/region_service.dart';
import 'package:debit_credit_app/services/financial_tracker_service.dart';
import 'package:debit_credit_app/core/events/financial_events.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0; // Default to 0 (الرئيسية)
  bool _isDrawerOpen = false;
  StreamSubscription? _txSubscription;
  StreamSubscription<FinancialEvent>? _financialEventSubscription;
  final RegionService _regionService = RegionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startListeningToTransactions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay auto backup to avoid ANR on startup (Increased to 10s)
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          AutoBackupManager.instance.maybeRunAutoBackup(trigger: 'startup');
        }
      });
    });
  }

  void _startListeningToTransactions() {
    _txSubscription?.cancel();
    _txSubscription = FinancialTrackerService.transactionStream.listen((_) {});
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    _financialEventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AutoBackupManager.instance.maybeRunAutoBackup(trigger: 'resume');
    }
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  late final List<Widget> _screens = [
    MainDashboardScreen(
      onDrawerChanged: _onDrawerChanged,
    ),
    HomeScreen(
      onDrawerChanged: _onDrawerChanged,
    ),
    ExpenseScreen(
      onDrawerChanged: _onDrawerChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex >= _screens.length ? 0 : _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _isDrawerOpen
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildNavItem(
                          index: 0,
                          label: 'الرئيسية',
                          icon: Icons.grid_view_rounded,
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'الديون',
                          assetPath: 'assets/images/money-borrow.svg',
                        ),
                        _buildNavItem(
                          index: 2,
                          label: 'المصروفات',
                          assetPath: 'assets/images/trend-down-expense.svg',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    String? assetPath,
    IconData? icon,
    int badgeCount = 0,
  }) {
    final bool isSelected = _currentIndex == index;

    Widget iconWidget = assetPath != null
        ? SvgPicture.asset(
            assetPath,
            width: isSelected ? 25 : 23,
            height: isSelected ? 25 : 23,
            colorFilter: ColorFilter.mode(
              isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              BlendMode.srcIn,
            ),
          )
        : Icon(
            icon,
            size: isSelected ? 25 : 23,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ArbFONTSIBMPlexArabicText',
          ),
        ),
        backgroundColor: Colors.redAccent,
        offset: const Offset(6, -4),
        child: iconWidget,
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          FinancialEventBus().emit(FinancialEvent(type: FinancialEventType.transactionUpdated));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 14 : 13,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}