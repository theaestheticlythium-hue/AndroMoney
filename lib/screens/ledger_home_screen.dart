
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

  Future<void> _addTransaction() async {
    final transaction = await Navigator.push<JournalTransaction>(
      context,
      MaterialPageRoute(
        builder: (_) => AddJournalTransactionScreen(
          accounts: _accounts,
        ),
      ),
    );

    if (transaction == null) return;

    if (!_ledgerService.validateTransaction(transaction)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or unbalanced transaction'),
        ),
      );
      return;
    }

    final updatedTransactions = [
      ..._transactions,
      transaction,
    ];

    await _storage.saveTransactions(updatedTransactions);

    if (!mounted) return;

    setState(() {
      _transactions = updatedTransactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction saved successfully'),
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

  double _totalAssets() {
    return _accounts
        .where((account) => account.type == AccountType.asset)
        .fold(
          0.0,
          (sum, account) => sum +
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
          (sum, account) => sum +
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
            CircleAvatar(
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
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

  Widget _buildTransactionTile(JournalTransaction transaction) {
    return ListTile(
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
      trailing: Text(
        _formatAmount(transaction.totalDebit),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
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
            tooltip: 'Accounts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                            'No transactions yet.\nTap + Transaction to add one.',
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
