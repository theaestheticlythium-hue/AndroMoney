
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';
import '../services/ledger_storage_service.dart';
import 'account_details_screen.dart';

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
  String _selectedFilter = 'All';

  static const Color background = Color(0xFF080D12);
  static const Color surface = Color(0xFF111B22);
  static const Color green = Color(0xFF00E676);
  static const Color muted = Color(0xFF9AA7B0);
  static const Color border = Color(0xFF263640);

  final List<String> _filters = [
    'All',
    'Asset',
    'Liability',
    'Equity',
    'Income',
    'Expense',
  ];

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
        SnackBar(content: Text('Unable to load accounts: $error')),
      );
    }
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
        return const Color(0xFF00E676);
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

  double _balance(LedgerAccount account) {
    return _ledgerService.getAccountBalance(
      account: account,
      transactions: _transactions,
    );
  }

  List<LedgerAccount> get _visibleAccounts {
    return _accounts.where((account) {
      if (account.isArchived) return false;

      if (_selectedFilter == 'All') return true;

      return _typeName(account.type) == _selectedFilter;
    }).toList();
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
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: border),
              ),
              title: Text(
                isEditing ? 'Edit Account' : 'Add Account',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      dropdownColor: surface,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(Icons.category_outlined),
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
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Opening Balance (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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
                        ? accountToEdit!.copyWith(
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
    if (account.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System accounts cannot be deleted.'),
        ),
      );
      return;
    }

    final isUsed = _transactions.any(
      (transaction) => transaction.entries.any(
        (entry) => entry.accountId == account.id,
      ),
    );

    if (isUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account has transactions. It cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Text('Delete Account?'),
          content: Text(
            'Delete "${account.name}" permanently?',
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

    final updatedAccounts = _accounts
        .where((item) => item.id != account.id)
        .toList();

    await _storage.saveAccounts(updatedAccounts);

    if (!mounted) return;

    setState(() {
      _accounts = updatedAccounts;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deleted successfully'),
      ),
    );
  }

  // Opens the full-screen Account Details page.
  Future<void> _viewAccount(LedgerAccount account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailsScreen(
          account: account,
          transactions: _transactions,
        ),
      ),
    );
  }

  Widget _liquidBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF080D12), Color(0xFF101B24), Color(0xFF080D12)],
              ),
            ),
          ),
          _glowOrb(const Color(0xFF00E676), const Alignment(-1.1, -0.85), 230),
          _glowOrb(const Color(0xFF168B9A), const Alignment(1.0, 0.15), 210),
          _glowOrb(const Color(0xFF64748B), const Alignment(-0.3, 1.0), 190),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, Alignment alignment, double size) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 75, sigmaY: 75),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _glassSurface({required Widget child, EdgeInsets padding = EdgeInsets.zero}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.13),
                Colors.white.withValues(alpha: 0.045),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFilter(String filter) {
    final selected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? green : Colors.white.withValues(alpha: 0.13),
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(LedgerAccount account) {
    final color = _accountColor(account.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _glassSurface(
        child: ListTile(
        onTap: () => _viewAccount(account),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 3,
        ),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(
            _accountIcon(account.type),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _typeName(account.type),
          style: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatAmount(_balance(account)),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              color: surface,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
              ),
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
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('View'),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleAccounts = _visibleAccounts;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Manage Accounts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAccountForm(),
            icon: const Icon(
              Icons.add,
              color: green,
              size: 27,
            ),
            tooltip: 'Add Account',
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountForm(),
        backgroundColor: green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _liquidBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: green))
                : RefreshIndicator(
                    color: green,
                    backgroundColor: surface,
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                      children: [
                        SizedBox(
                          height: 43,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _filters.map(_buildFilter).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${visibleAccounts.length} Accounts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _selectedFilter == 'All' ? 'All Accounts' : _selectedFilter,
                              style: const TextStyle(color: green, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (visibleAccounts.isEmpty)
                          _glassSurface(
                            padding: const EdgeInsets.all(28),
                            child: const Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 38, color: muted),
                                SizedBox(height: 12),
                                Text('No accounts found', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          )
                        else
                          ...visibleAccounts.map(_buildAccountCard),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
