import 'package:flutter/material.dart';

class AccountsHeaderRow extends StatelessWidget {
  const AccountsHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('الاسم', style: headerStyle)),
          Expanded(flex: 2, child: Center(child: Text('العملة', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('عليه', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('له', style: headerStyle))),
          Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}
