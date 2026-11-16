
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
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

  double _balance(LedgerAccount account) {
    return _ledgerService.getAccountBalance(
      account: account,
      transactions: _transactions,
    );
  }

  Future<void> _showAccountForm({
    LedgerAccount? accountToEdit,
  }) async {
    final isEditing = accountToEdit != null;

    final nameController = TextEditingController(
      text: accountToEdit?.name ?? '',
    );

    final openingController = TextEditingController(
      text: (accountToEdit?.openingBalance ?? 0).toString(),
    );

    AccountType selectedType =
        accountToEdit?.type ?? AccountType.asset;

    final result = await showDialog<LedgerAccount>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Account' : 'Add Account',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        border: OutlineInputBorder(),
                      ),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_typeName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: openingController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Opening Balance (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final openingBalance = double.tryParse(
                      openingController.text.trim(),
                    );

                    if (name.isEmpty ||
                        openingBalance == null ||
                        !openingBalance.isFinite ||
                        openingBalance < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid name and opening balance',
                          ),
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now();

                    final newAccount = isEditing
                        ? accountToEdit.copyWith(
                            name: name,
                            type: selectedType,
                            openingBalance: openingBalance,
                          )
                        : LedgerAccount(
                            id: now.microsecondsSinceEpoch.toString(),
                            name: name,
                            type: selectedType,
                            openingBalance: openingBalance,
                            createdAt: now,
                          );

                    Navigator.pop(dialogContext, newAccount);
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    openingController.dispose();

    if (result == null) return;

    final updatedAccounts = [..._accounts];

    if (isEditing) {
      final index = updatedAccounts.indexWhere(
        (item) => item.id == result.id,
      );

      if (index >= 0) {
        updatedAccounts[index] = result;
      }
    } else {
      updatedAccounts.add(result);
    }

    await _storage.saveAccounts(updatedAccounts);

    if (!mounted) return;

    setState(() {
      _accounts = updatedAccounts;
    });
  }

  Future<void> _deleteAccount(LedgerAccount account) async {
    final isUsed = _transactions.any(
      (transaction) => transaction.entries.any(
        (entry) => entry.accountId == account.id,
      ),
    );

    if (isUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account has transactions. '
            'It cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Text(
            'Delete "${account.name}" permanently?',
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

    final updatedAccounts = _accounts
        .where((item) => item.id != account.id)
        .toList();

    await _storage.saveAccounts(updatedAccounts);

    if (!mounted) return;

    setState(() {
      _accounts = updatedAccounts;
    });
  }

  void _viewAccount(LedgerAccount account) {
    final entries = _ledgerService.getAccountEntries(
      accountId: account.id,
      transactions: _transactions,
    );

    final debitTotal = entries
        .where((entry) => entry.side == EntrySide.debit)
        .fold(0.0, (sum, entry) => sum + entry.amount);

    final creditTotal = entries
        .where((entry) => entry.side == EntrySide.credit)
        .fold(0.0, (sum, entry) => sum + entry.amount);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(account.name),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${_typeName(account.type)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Current Balance: ${_formatAmount(_balance(account))}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Divider(height: 24),
                  Text('Opening Balance: ${_formatAmount(account.openingBalance)}'),
                  Text('Total Debit: ${_formatAmount(debitTotal)}'),
                  Text('Total Credit: ${_formatAmount(creditTotal)}'),
                  const Divider(height: 24),
                  const Text(
                    'Ledger Entries',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    const Text('No ledger entries yet.')
                  else
                    ...entries.reversed.map((entry) {
                      final transaction = _transactions.firstWhere(
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

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(transaction.title),
                        subtitle: Text(
                          '${entry.side.name.toUpperCase()} • '
                          '${transaction.voucherNumber}',
                        ),
                        trailing: Text(
                          _formatAmount(entry.amount),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountCard(LedgerAccount account) {
    return Card(
      child: ListTile(
        onTap: () => _viewAccount(account),
        leading: CircleAvatar(
          child: Icon(_accountIcon(account.type)),
        ),
        title: Text(
          account.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(_typeName(account.type)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatAmount(_balance(account)),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') {
                  _viewAccount(account);
                } else if (value == 'edit') {
                  _showAccountForm(accountToEdit: account);
                } else if (value == 'delete') {
                  _deleteAccount(account);
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
                  child: Text('Delete'),
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
    final visibleAccounts = _accounts
        .where((account) => !account.isArchived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        actions: [
          IconButton(
            onPressed: () => _showAccountForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : visibleAccounts.isEmpty
              ? const Center(child: Text('No accounts found'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  children: [
                    Text(
                      '${visibleAccounts.length} Accounts',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...visibleAccounts.map(_buildAccountCard),
                  ],
                ),
    );
  }
}
