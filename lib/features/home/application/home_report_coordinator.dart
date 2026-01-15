import 'package:debit_credit_app/core/models/account.dart';
import 'package:debit_credit_app/core/models/category.dart';
import 'package:debit_credit_app/features/home/application/reports/all_accounts_report_generator.dart';
import 'package:debit_credit_app/features/home/application/reports/category_report_generator.dart';
import 'package:debit_credit_app/features/home/application/reports/selected_accounts_report_generator.dart';

class HomeReportCoordinator {
  static Future<void> generateCategoryReport({
    required CategoryModel category,
    required List<AccountModel> accounts,
  }) async {
    await CategoryReportGenerator.generate(
      category: category,
      accounts: accounts,
    );
  }

  static Future<void> generateAllAccountsReport({
    required List<AccountModel> allAccounts,
  }) async {
    await AllAccountsReportGenerator.generate(
      allAccounts: allAccounts,
    );
  }

  static Future<void> generateSelectedAccountsReport({
    required List<AccountModel> selected,
  }) async {
    await SelectedAccountsReportGenerator.generate(
      selected: selected,
    );
  }
}

