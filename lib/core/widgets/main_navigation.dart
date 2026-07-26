import 'package:flutter/material.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/features/expenses/presentation/screens/expense_screen.dart';
import 'package:debit_credit_app/features/balances/presentation/screens/income_balances_screen.dart';
import 'package:debit_credit_app/features/home/presentation/screens/smart_dashboard_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:debit_credit_app/core/services/region_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;
  int _balancesTabVersion = 0;
  final RegionService _regionService = RegionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure index is valid if Radar is disabled
    if (!_regionService.isRadarEnabled && _currentIndex == 0) {
      // Default to "Debts" (which becomes index 0)
      _currentIndex = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay auto backup to avoid ANR on startup (Increased to 10s)
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          AutoBackupManager.instance.maybeRunAutoBackup(trigger: 'startup');
        }
      });
    });
  }

  @override
  void dispose() {
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

  List<Widget> get _screens {
    final List<Widget> screens = [];
    
    if (_regionService.isRadarEnabled) {
      screens.add(SmartDashboardScreen(onDrawerChanged: _onDrawerChanged));
    }

    screens.add(HomeScreen(onDrawerChanged: _onDrawerChanged));
    screens.add(ExpenseScreen(onDrawerChanged: _onDrawerChanged));

    screens.add(
      IncomeBalancesScreen(
        key: ValueKey<int>(_balancesTabVersion),
        onDrawerChanged: _onDrawerChanged,
      ),
    );

    return screens;
  }

  @override
  Widget build(BuildContext context) {
    final bool radarEnabled = _regionService.isRadarEnabled;
    
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
                      color: Colors.grey.withOpacity(0.08),
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
                        if (radarEnabled)
                          _buildNavItem(
                            index: 0,
                            label: 'الراصد',
                            icon: Icons.radar,
                          ),
                        _buildNavItem(
                          index: radarEnabled ? 1 : 0,
                          label: 'الديون',
                          assetPath: 'assets/images/money-borrow.svg',
                        ),
                        _buildNavItem(
                          index: radarEnabled ? 2 : 1,
                          label: 'المصروفات',
                          assetPath: 'assets/images/trend-down-expense.svg',
                        ),
                        _buildNavItem(
                          index: radarEnabled ? 3 : 2,
                          label: 'الأرصدة',
                          assetPath: 'assets/images/trend-up-income.svg',
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
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
            // The index of Balances tab depends on whether Radar is enabled
            final int balancesIndex = _regionService.isRadarEnabled ? 3 : 2;
            if (index == balancesIndex) {
              // Force IncomeBalancesScreen to rebuild and reload balances
              _balancesTabVersion++;
            }
          });
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
              if (assetPath != null)
                SvgPicture.asset(
                  assetPath,
                  width: isSelected ? 25 : 23,
                  height: isSelected ? 25 : 23,
                  colorFilter: ColorFilter.mode(
                    isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    BlendMode.srcIn,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: isSelected ? 25 : 23,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
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