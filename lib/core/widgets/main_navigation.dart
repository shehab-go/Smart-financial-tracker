import 'package:flutter/material.dart';
import 'package:debit_credit_app/features/home/presentation/screens/home_screen.dart';
import 'package:debit_credit_app/features/expenses/presentation/screens/expense_screen.dart';
import 'package:debit_credit_app/features/balances/presentation/screens/income_balances_screen.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;
  int _balancesTabVersion = 0;

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  List<Widget> get _screens => [
    HomeScreen(onDrawerChanged: _onDrawerChanged),
    ExpenseScreen(onDrawerChanged: _onDrawerChanged),
    IncomeBalancesScreen(
      key: ValueKey<int>(_balancesTabVersion),
      onDrawerChanged: _onDrawerChanged,
    ),
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
                        _buildNavItem(
                          index: 0,
                          label: 'ديون',
                          assetPath: 'assets/images/money-borrow.svg',
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'مصروف',
                          assetPath: 'assets/images/trend-down-expense.svg',
                        ),
                        _buildNavItem(
                          index: 2,
                          label: 'أرصدة',
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
    required String assetPath,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
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
              SvgPicture.asset(
                assetPath,
                width: isSelected ? 25 : 23,
                height: isSelected ? 25 : 23,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  BlendMode.srcIn,
                ),
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