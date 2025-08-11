import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AccountsHeaderRow extends StatelessWidget {
  const AccountsHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.5,
    );
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding:  EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border:  Border(
            bottom: BorderSide(
              color: AppTheme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text('الاسم', style: headerStyle),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text('العملة', style: headerStyle)),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text('عليه', style: headerStyle)),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text('له', style: headerStyle)),
            ),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
