
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';
import '../services/ledger_storage_service.dart';
import 'accounts_screen.dart';
import 'add_journal_transaction_screen.dart';
import 'transactions_screen.dart';

class LedgerHomeScreen extends StatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  State<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends State<LedgerHomeScreen> {
  final LedgerStorageService _storage = LedgerStorageService();
  final LedgerService _ledgerService = LedgerService();

  List<LedgerAccount> _accounts = [];
  List<JournalTransaction> _transactions = [];
  bool _isLoading = true;

  static const Color background = Color(0xFF080D12);
  static const Color surface = Color(0xFF111B22);
  static const Color green = Color(0xFF00E676);
  static const Color muted = Color(0xFF9AA7B0);
  static const Color border = Color(0xFF263640);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _storage.initializeDefaultAccounts();
      final transactions = await _storage.loadTransactions();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load data: $error')),
      );
    }
  }

  Future<void> _openTransactionForm({
    JournalTransaction? transactionToEdit,
  }) async {
    final result = await Navigator.push<JournalTransaction>(
      context,
      MaterialPageRoute(
        builder: (_) => AddJournalTransactionScreen(
          accounts: _accounts,
          transactionToEdit: transactionToEdit,
        ),
      ),
    );

    if (result == null) return;

    if (!_ledgerService.validateTransaction(result)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or unbalanced transaction'),
        ),
      );
      return;
    }

    final updatedTransactions = [..._transactions];

    final existingIndex = updatedTransactions.indexWhere(
      (item) => item.id == result.id,
    );

    if (existingIndex >= 0) {
      updatedTransactions[existingIndex] = result;
    } else {
      updatedTransactions.add(result);
    }

    await _storage.saveTransactions(updatedTransactions);

    if (!mounted) return;

    setState(() {
      _transactions = updatedTransactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existingIndex >= 0
              ? 'Transaction updated successfully'
              : 'Transaction saved successfully',
        ),
      ),
    );
  }

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountsScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(
          accounts: _accounts,
          transactions: _transactions,
          onEdit: _openTransactionForm,
          onDelete: _deleteTransaction,
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _deleteTransaction(
    JournalTransaction transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Text('Delete Transaction?'),
          content: Text(
            'Are you sure you want to delete '
            '"${transaction.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final updatedTransactions = _transactions
        .where((item) => item.id != transaction.id)
        .toList();

    await _storage.saveTransactions(updatedTransactions);

    if (!mounted) return;

    setState(() {
      _transactions = updatedTransactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted successfully'),
      ),
    );
  }

  Future<void> _openTransactionDetails(
    JournalTransaction transaction,
  ) async {
    final debitEntries = transaction.entries
        .where((entry) => entry.side.name == 'debit')
        .toList();

    final creditEntries = transaction.entries
        .where((entry) => entry.side.name == 'credit')
        .toList();

    String accountName(String accountId) {
      final matches = _accounts.where(
        (account) => account.id == accountId,
      );

      return matches.isEmpty ? 'Unknown Account' : matches.first.name;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          title: Text(transaction.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Voucher: ${transaction.voucherNumber}'),
                Text(
                  'Date: ${transaction.date.day}/'
                  '${transaction.date.month}/'
                  '${transaction.date.year}',
                ),
                const Divider(),
                const Text(
                  'Debit Entries',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...debitEntries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(accountName(entry.accountId)),
                    trailing: Text(
                      '₹${entry.amount.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Credit Entries',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...creditEntries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(accountName(entry.accountId)),
                    trailing: Text(
                      '₹${entry.amount.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                if (transaction.referenceNumber != null)
                  Text('Reference: ${transaction.referenceNumber}'),
                if (transaction.notes != null)
                  Text('Notes: ${transaction.notes}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openTransactionForm(
                  transactionToEdit: transaction,
                );
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  double _totalAssets() {
    return _accounts
        .where(
          (account) =>
              account.type == AccountType.asset &&
              !account.isArchived,
        )
        .fold(
          0.0,
          (sum, account) =>
              sum +
              _ledgerService.getAccountBalance(
                account: account,
                transactions: _transactions,
              ),
        );
  }

  double _totalLiabilities() {
    return _accounts
        .where(
          (account) =>
              account.type == AccountType.liability &&
              !account.isArchived,
        )
        .fold(
          0.0,
          (sum, account) =>
              sum +
              _ledgerService.getAccountBalance(
                account: account,
                transactions: _transactions,
              ),
        );
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature screen will be added next'),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.19),
              surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 29),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatAmount(amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = green,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 29),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isReceipt(JournalTransaction transaction) {
    final debitEntries = transaction.entries.where(
      (entry) => entry.side.name == 'debit',
    );

    return debitEntries.any((entry) {
      return _accounts.any(
        (account) =>
            account.id == entry.accountId &&
            account.type == AccountType.asset,
      );
    });
  }

  Widget _buildTransactionTile(
    JournalTransaction transaction,
  ) {
    final receipt = _isReceipt(transaction);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        onTap: () => _openTransactionDetails(transaction),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 3,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: receipt
              ? green.withValues(alpha: 0.16)
              : Colors.redAccent.withValues(alpha: 0.14),
          child: Icon(
            receipt
                ? Icons.shopping_cart_outlined
                : Icons.receipt_long,
            color: receipt ? green : Colors.redAccent,
            size: 23,
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${transaction.date.day} '
          '${_monthName(transaction.date.month)} '
          '${transaction.date.year} • ${transaction.voucherNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: muted,
            fontSize: 10,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatAmount(transaction.totalDebit),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
              ),
              color: surface,
              onSelected: (value) {
                if (value == 'view') {
                  _openTransactionDetails(transaction);
                } else if (value == 'edit') {
                  _openTransactionForm(
                    transactionToEdit: transaction,
                  );
                } else if (value == 'delete') {
                  _deleteTransaction(transaction);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'view',
                  child: Text('View'),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions = [..._transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: green.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: green,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Andro',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Money',
                        style: TextStyle(color: green),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Double-Entry Accounting',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showComingSoon('Notifications'),
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () => _openTransactionForm(),
        backgroundColor: green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Transaction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: green),
            )
          : RefreshIndicator(
              color: green,
              backgroundColor: surface,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                children: [
                  Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Total Assets',
                        amount: _totalAssets(),
                        icon: Icons.account_balance_wallet_outlined,
                        accent: green,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: 'Total Liabilities',
                        amount: _totalLiabilities(),
                        icon: Icons.credit_card_outlined,
                        accent: const Color(0xFFFF647C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildShortcut(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transactions',
                        onTap: _openTransactions,
                      ),
                      const SizedBox(width: 9),
                      _buildShortcut(
                        icon: Icons.account_balance_outlined,
                        title: 'Manage Accounts',
                        onTap: _openAccounts,
                      ),
                      const SizedBox(width: 9),
                      _buildShortcut(
                        icon: Icons.bar_chart_rounded,
                        title: 'Reports',
                        onTap: () => _showComingSoon('Reports'),
                      ),
                      const SizedBox(width: 9),
                      _buildShortcut(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => _showComingSoon('Settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _openTransactions,
                        child: const Text(
                          'View All  ›',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (recentTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: muted,
                            size: 35,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Tap + Transaction to add your first entry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentTransactions
                        .take(10)
                        .map(_buildTransactionTile),
                ],
              ),
            ),
    );
  }
}
