
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';

class AccountDetailsScreen extends StatefulWidget {
  final LedgerAccount account;
  final List<JournalTransaction> transactions;

  const AccountDetailsScreen({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  State<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final LedgerService _ledgerService = LedgerService();

  static const Color background = AppTheme.background;
  static const Color surface = AppTheme.surface;
  static const Color green = AppTheme.primary;
  static const Color muted = AppTheme.muted;
  static const Color border = AppTheme.border;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _typeName(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return 'Asset';
      case AccountType.liability:
        return 'Liability';
      case AccountType.equity:
        return 'Equity';
      case AccountType.income:
        return 'Income';
      case AccountType.expense:
        return 'Expense';
    }
  }

  Color _accountColor(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return green;
      case AccountType.liability:
        return const Color(0xFFFF647C);
      case AccountType.equity:
        return const Color(0xFFFFD740);
      case AccountType.income:
        return const Color(0xFF00C853);
      case AccountType.expense:
        return const Color(0xFFFF8A65);
    }
  }

  IconData _accountIcon(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return Icons.account_balance_wallet_outlined;
      case AccountType.liability:
        return Icons.credit_card_outlined;
      case AccountType.equity:
        return Icons.layers_outlined;
      case AccountType.income:
        return Icons.trending_up;
      case AccountType.expense:
        return Icons.restaurant_outlined;
    }
  }

  List<LedgerEntry> get _entries {
    return _ledgerService.getAccountEntries(
      accountId: widget.account.id,
      transactions: widget.transactions,
    );
  }

  double get _currentBalance {
    return _ledgerService.getAccountBalance(
      account: widget.account,
      transactions: widget.transactions,
    );
  }

  double get _totalDebit {
    return _entries
        .where((entry) => entry.side == EntrySide.debit)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get _totalCredit {
    return _entries
        .where((entry) => entry.side == EntrySide.credit)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildBalanceCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      tint: green,
      child: Column(
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatAmount(_currentBalance),
              style: const TextStyle(
                color: green,
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Row(
      children: [
        _summaryItem(
          'Opening Balance',
          _formatAmount(widget.account.openingBalance),
        ),
        _summaryItem(
          'Total Debit',
          _formatAmount(_totalDebit),
        ),
        _summaryItem(
          'Total Credit',
          _formatAmount(_totalCredit),
        ),
      ],
    );
  }

  Widget _summaryItem(String title, String amount) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerEntries() {
    final entries = _entries;

    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: muted,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'No ledger entries yet.',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];

        final transaction = widget.transactions.firstWhere(
          (item) => item.id == entry.transactionId,
          orElse: () => JournalTransaction(
            id: '',
            voucherNumber: '',
            title: 'Unknown Transaction',
            date: entry.createdAt,
            createdAt: entry.createdAt,
            entries: const [],
          ),
        );

        final isDebit = entry.side == EntrySide.debit;

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: GlassCard(
            padding: EdgeInsets.zero,
            radius: 16,
            child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 4,
            ),
            leading: Container(
              width: 43,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF202B34),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${transaction.date.day}\n'
                '${_monthName(transaction.date.month)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              transaction.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              transaction.voucherNumber,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isDebit ? 'Debit' : 'Credit',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAmount(entry.amount),
                  style: TextStyle(
                    color: isDebit
                        ? green
                        : const Color(0xFFFF647C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        GlassCard(
          child: Column(
            children: [
        _summaryRow('Account Name', widget.account.name),
        _summaryRow('Account Type', _typeName(widget.account.type)),
        _summaryRow(
          'Opening Balance',
          _formatAmount(widget.account.openingBalance),
        ),
        _summaryRow(
          'Total Debit',
          _formatAmount(_totalDebit),
        ),
        _summaryRow(
          'Total Credit',
          _formatAmount(_totalCredit),
        ),
        const Divider(color: border, height: 28),
        _summaryRow(
          'Current Balance',
          _formatAmount(_currentBalance),
          highlight: true,
        ),
        _summaryRow(
          'Total Ledger Entries',
          _entries.length.toString(),
        ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: highlight ? green : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _accountColor(widget.account.type);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.account.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LiquidGlassBackground(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(
                          _accountIcon(widget.account.type),
                          color: color,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.account.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_typeName(widget.account.type)} Account',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildAmountSummary(),
                  const SizedBox(height: 19),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: green,
              indicatorWeight: 3,
              labelColor: green,
              unselectedLabelColor: muted,
              tabs: const [
                Tab(text: 'Ledger Entries'),
                Tab(text: 'Summary'),
              ],
            ),
            const Divider(height: 1, color: border),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLedgerEntries(),
                  _buildSummaryTab(),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
