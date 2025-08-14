import 'package:flutter/material.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';

class AccountsHeaderRow extends StatelessWidget {
  const AccountsHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Center(child: Text('عليك', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Center(child: Text('لك', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text('العملة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );  
  }
}
