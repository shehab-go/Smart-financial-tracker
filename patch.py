import sys

file_path = r'e:\hemmah\debit_credit_app\lib\features\expenses\presentation\screens\expense_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.read().split('\n')

start = lines.index('        body: _state.isLoading')
end = lines.index('        floatingActionButton: FloatingActionButton(')

filters_lines = lines[lines.index('                  // Capsule Filters Scroll Row'):lines.index('                  // Accounts list Bento Slate Cards')]
filters_block = '\n'.join(filters_lines)

sliver_list = """
                  _filteredAccounts.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 60,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '?? ???? ?????? ???????',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '???? ??? ?? + ?????? ????? ???? ????? ????? ???? ????????.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.only(top: 8, bottom: 88),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final account = _filteredAccounts[index];
                                return _buildExpenseAccountCard(account);
                              },
                              childCount: _filteredAccounts.length,
                            ),
                          ),
                        ),
"""

new_body = """        body: _state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ExpenseStatsHeaderDelegate(
                      expenseCount: _filteredExpenses.length,
                      totalAmount: _filteredTotalExpenses,
                      currencyFormat: _currencyFormat,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: """ + filters_block + """
                  ),""" + sliver_list + """
                ],
              ),
"""

delegate_code = """
class _ExpenseStatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int expenseCount;
  final double totalAmount;
  final NumberFormat currencyFormat;

  _ExpenseStatsHeaderDelegate({
    required this.expenseCount,
    required this.totalAmount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final double scale = 1.0 - (progress * 0.05);

    return Container(
      color: AppTheme.backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.dividerColor.withOpacity(0.6), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '?????? ?????????',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expenseCount > 0 ? currencyFormat.format(totalAmount) : '0',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    f'{expenseCount} ?????',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                      fontFamily: 'ArbFONTSIBMPlexArabicText',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 110.0;

  @override
  double get minExtent => 110.0;

  @override
  bool shouldRebuild(covariant _ExpenseStatsHeaderDelegate oldDelegate) {
    return expenseCount != oldDelegate.expenseCount ||
        totalAmount != oldDelegate.totalAmount;
  }
}
"""

delegate_code = delegate_code.replace("f'{expenseCount} ?????'", "'${expenseCount} ?????'")

final_content = '\n'.join(lines[:start]) + '\n' + new_body + '\n'.join(lines[end:])

if '_ExpenseStatsHeaderDelegate' not in final_content:
    final_content += '\n' + delegate_code

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(final_content)

print('Done.')
