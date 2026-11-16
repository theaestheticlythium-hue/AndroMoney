
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';
import '../services/ledger_storage_service.dart';
import 'accounts_screen.dart';
import 'add_journal_transaction_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await _storage.initializeDefaultAccounts();
    final transactions = await _storage.loadTransactions();

    if (!mounted) return;

    setState(() {
      _accounts = accounts;
      _transactions = transactions;
      _isLoading = false;
    });
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

  Future<void> _deleteTransaction(
    JournalTransaction transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: Text(
            'Are you sure you want to delete '
            '"${transaction.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
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
      final account = _accounts.where(
        (item) => item.id == accountId,
      );

      return account.isEmpty ? 'Unknown Account' : account.first.name;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountsScreen(),
      ),
    );

    await _loadData();
  }

  double _totalAssets() {
    return _accounts
        .where((account) => account.type == AccountType.asset)
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
        .where((account) => account.type == AccountType.liability)
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

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatAmount(amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTransactionTile(
    JournalTransaction transaction,
  ) {
    return Card(
      child: ListTile(
        onTap: () => _openTransactionDetails(transaction),
        leading: const CircleAvatar(
          child: Icon(Icons.receipt_long),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${transaction.voucherNumber} • '
          '${transaction.date.day}/'
          '${transaction.date.month}/'
          '${transaction.date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatAmount(transaction.totalDebit),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton<String>(
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
                  child: ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('View'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text('Delete'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions = [..._transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AndroMoney'),
        actions: [
          IconButton(
            onPressed: _openAccounts,
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Manage Accounts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () => _openTransactionForm(),
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 90,
                ),
                children: [
                  _buildSummaryCard(
                    'Total Assets',
                    _totalAssets(),
                    Icons.account_balance,
                  ),
                  _buildSummaryCard(
                    'Total Liabilities',
                    _totalLiabilities(),
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.wallet),
                      title: const Text('Manage Accounts'),
                      subtitle: Text(
                        '${_accounts.where((a) => !a.isArchived).length} accounts',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openAccounts,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recentTransactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No transactions yet.\n'
                            'Tap + Transaction to add one.',
                            textAlign: TextAlign.center,
                          ),
                        ),
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
