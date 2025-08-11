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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Text('الاسم', style: headerStyle),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Center(child: Text('عليه', style: headerStyle)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Center(child: Text('له', style: headerStyle)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text('العملة', style: headerStyle),
            ),
          ],
        ),
      ),
      Container(
        height: 1,
        color: AppTheme.dividerColor,
      ),
    ],
  ),
);
  }
}
