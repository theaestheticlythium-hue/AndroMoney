
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';
import '../services/ledger_storage_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
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

  String _accountTypeName(AccountType type) {
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

  IconData _accountIcon(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return Icons.account_balance_wallet_outlined;
      case AccountType.liability:
        return Icons.credit_card;
      case AccountType.equity:
        return Icons.account_balance;
      case AccountType.income:
        return Icons.trending_up;
      case AccountType.expense:
        return Icons.trending_down;
    }
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _buildAccountCard(LedgerAccount account) {
    final balance = _ledgerService.getAccountBalance(
      account: account,
      transactions: _transactions,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_accountIcon(account.type)),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_accountTypeName(account.type)),
        trailing: Text(
          _formatAmount(balance),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('No accounts found'))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Your Accounts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._accounts
                        .where((account) => !account.isArchived)
                        .map(_buildAccountCard),
                  ],
                ),
    );
  }
}
