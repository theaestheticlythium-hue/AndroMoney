
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ledger_account.dart';
import '../models/journal_transaction.dart';
import '../models/ledger_entry.dart';

class ReportsScreen extends StatelessWidget {
  final List<LedgerAccount> accounts;
  final List<JournalTransaction> transactions;

  const ReportsScreen({
    super.key,
    required this.accounts,
    required this.transactions,
  });

  static const Color backgroundColor = Color(0xFF080D12);
  static const Color cardColor = Color(0xFF111B22);
  static const Color accentColor = Color(0xFF00E676);
  static const Color mutedColor = Color(0xFF8A9AA5);
  static const Color redColor = Color(0xFFFF5252);

  String _currency(double amount) {
    final currencyCode = accounts.isNotEmpty
        ? accounts.first.currencyCode
        : 'INR';

    return NumberFormat.currency(
      locale: 'en_IN',
      name: currencyCode,
      symbol: currencyCode == 'INR' ? '₹' : '$currencyCode ',
      decimalDigits: 2,
    ).format(amount);
  }

  double _accountAmount(
    JournalTransaction transaction,
    LedgerAccount account,
  ) {
    double total = 0;

    for (final entry in transaction.entries) {
      if (entry.accountId != account.id) continue;

      if (account.type == AccountType.income) {
        total += entry.side == EntrySide.credit
            ? entry.amount
            : -entry.amount;
      } else if (account.type == AccountType.expense) {
        total += entry.side == EntrySide.debit
            ? entry.amount
            : -entry.amount;
      }
    }

    return total;
  }

  double _totalForType(AccountType type) {
    double total = 0;

    for (final transaction in transactions) {
      for (final account in accounts) {
        if (account.type == type) {
          total += _accountAmount(transaction, account);
        }
      }
    }

    return total;
  }

  Map<String, double> _expenseBreakdown() {
    final Map<String, double> result = {};

    for (final account in accounts) {
      if (account.type != AccountType.expense) continue;

      double amount = 0;

      for (final transaction in transactions) {
        amount += _accountAmount(transaction, account);
      }

      if (amount > 0) {
        result[account.name] = amount;
      }
    }

    return result;
  }

  List<DateTime> _lastSixMonths() {
    final now = DateTime.now();

    return List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index, 1),
    );
  }

  double _monthlyTotal(DateTime month, AccountType type) {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction.date.year != month.year ||
          transaction.date.month != month.month) {
        continue;
      }

      for (final account in accounts) {
        if (account.type == type) {
          total += _accountAmount(transaction, account);
        }
      }
    }

    return total;
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _monthlyChart() {
    final months = _lastSixMonths();

    final groups = List.generate(months.length, (index) {
      final income = _monthlyTotal(
        months[index],
        AccountType.income,
      );

      final expense = _monthlyTotal(
        months[index],
        AccountType.expense,
      );

      return BarChartGroupData(
        x: index,
        barsSpace: 5,
        barRods: [
          BarChartRodData(
            toY: income,
            color: accentColor,
            width: 9,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expense,
            color: redColor,
            width: 9,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final maxValue = groups.fold<double>(
      0,
      (maximum, group) {
        for (final rod in group.barRods) {
          if (rod.toY > maximum) maximum = rod.toY;
        }
        return maximum;
      },
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(accentColor, 'Income'),
              const SizedBox(width: 24),
              _legend(redColor, 'Expense'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxValue <= 0 ? 100 : maxValue * 1.25,
                minY: 0,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.07),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(
                            color: mutedColor,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM').format(months[index]),
                            style: const TextStyle(
                              color: mutedColor,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: mutedColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _expenseBreakdownSection() {
    final breakdown = _expenseBreakdown();
    final total = breakdown.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );

    if (breakdown.isEmpty) {
      return _emptyMessage('No expense records available yet.');
    }

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          final percentage = total == 0 ? 0.0 : entry.value / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _currency(entry.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0).toDouble(),
                    minHeight: 7,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(accentColor),
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: mutedColor,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = _totalForType(AccountType.income);
    final expense = _totalForType(AccountType.expense);
    final netBalance = income - expense;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(
                color: mutedColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Total Income',
                    amount: _currency(income),
                    color: accentColor,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Total Expense',
                    amount: _currency(expense),
                    color: redColor,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryCard(
              title: 'Net Income',
              amount: _currency(netBalance),
              color: netBalance >= 0 ? accentColor : redColor,
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 28),
            _sectionTitle('Monthly Income vs Expense'),
            if (transactions.isEmpty)
              _emptyMessage('Add transactions to view your monthly report.')
            else
              _monthlyChart(),
            const SizedBox(height: 28),
            _sectionTitle('Expense by Category'),
            _expenseBreakdownSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
