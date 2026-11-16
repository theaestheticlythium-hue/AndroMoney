
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';

class TransactionsScreen extends StatefulWidget {
  final List<LedgerAccount> accounts;
  final List<JournalTransaction> transactions;
  final Future<void> Function(JournalTransaction) onEdit;
  final Future<void> Function(JournalTransaction) onDelete;

  const TransactionsScreen({
    super.key,
    required this.accounts,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const Color background = Color(0xFF080D12);
  static const Color surface = Color(0xFF111B22);
  static const Color green = Color(0xFF00E676);
  static const Color muted = Color(0xFF9AA7B0);
  static const Color border = Color(0xFF263640);
  static const Color red = Color(0xFFFF647C);

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'Income',
    'Expense',
    'Transfer',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  LedgerAccount? _findAccount(String accountId) {
    for (final account in widget.accounts) {
      if (account.id == accountId) return account;
    }
    return null;
  }

  String _accountName(String accountId) {
    return _findAccount(accountId)?.name ?? 'Unknown Account';
  }

  String _transactionType(JournalTransaction transaction) {
    final debitAccounts = transaction.entries
        .where((entry) => entry.side == EntrySide.debit)
        .map((entry) => _findAccount(entry.accountId))
        .whereType<LedgerAccount>()
        .toList();

    final creditAccounts = transaction.entries
        .where((entry) => entry.side == EntrySide.credit)
        .map((entry) => _findAccount(entry.accountId))
        .whereType<LedgerAccount>()
        .toList();

    if (debitAccounts.isNotEmpty &&
        debitAccounts.every(
          (account) => account.type == AccountType.asset,
        ) &&
        creditAccounts.any(
          (account) => account.type == AccountType.income,
        )) {
      return 'Income';
    }

    if (debitAccounts.any(
      (account) => account.type == AccountType.expense,
    )) {
      return 'Expense';
    }

    final allAccounts = [
      ...debitAccounts,
      ...creditAccounts,
    ];

    if (allAccounts.isNotEmpty &&
        allAccounts.every(
          (account) => account.type == AccountType.asset,
        )) {
      return 'Transfer';
    }

    if (debitAccounts.any(
      (account) => account.type == AccountType.asset,
    )) {
      return 'Income';
    }

    return 'Expense';
  }

  List<JournalTransaction> get _filteredTransactions {
    final result = widget.transactions.where((transaction) {
      final type = _transactionType(transaction);

      if (_selectedFilter != 'All' &&
          type != _selectedFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();

        final matchesTitle =
            transaction.title.toLowerCase().contains(query);

        final matchesVoucher =
            transaction.voucherNumber.toLowerCase().contains(query);

        final matchesReference =
            (transaction.referenceNumber ?? '')
                .toLowerCase()
                .contains(query);

        final matchesAccount = transaction.entries.any(
          (entry) => _accountName(entry.accountId)
              .toLowerCase()
              .contains(query),
        );

        if (!matchesTitle &&
            !matchesVoucher &&
            !matchesReference &&
            !matchesAccount) {
          return false;
        }
      }

      return true;
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Income':
        return green;
      case 'Expense':
        return red;
      case 'Transfer':
        return const Color(0xFF40C4FF);
      default:
        return muted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Income':
        return Icons.account_balance_wallet_outlined;
      case 'Expense':
        return Icons.receipt_long_outlined;
      case 'Transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
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
          color: selected ? green : surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? green : border,
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

  void _showTransactionDetails(
    JournalTransaction transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        final debitEntries = transaction.entries
            .where((entry) => entry.side == EntrySide.debit)
            .toList();

        final creditEntries = transaction.entries
            .where((entry) => entry.side == EntrySide.credit)
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    transaction.voucherNumber,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${transaction.date.day} '
                    '${_monthName(transaction.date.month)} '
                    '${transaction.date.year}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(color: border, height: 28),
                  const Text(
                    'Debit Entries',
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...debitEntries.map(
                    (entry) => _buildDetailEntry(entry),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Credit Entries',
                    style: TextStyle(
                      color: red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...creditEntries.map(
                    (entry) => _buildDetailEntry(entry),
                  ),
                  const Divider(color: border, height: 28),
                  _detailRow(
                    'Total Debit',
                    _formatAmount(transaction.totalDebit),
                  ),
                  _detailRow(
                    'Total Credit',
                    _formatAmount(transaction.totalCredit),
                  ),
                  if (transaction.referenceNumber != null &&
                      transaction.referenceNumber!.isNotEmpty)
                    _detailRow(
                      'Reference',
                      transaction.referenceNumber!,
                    ),
                  if (transaction.notes != null &&
                      transaction.notes!.isNotEmpty)
                    _detailRow(
                      'Notes',
                      transaction.notes!,
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEdit(transaction);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Transaction'),
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

  Widget _buildDetailEntry(LedgerEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _accountName(entry.accountId),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _formatAmount(entry.amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: muted),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    JournalTransaction transaction,
  ) {
    final type = _transactionType(transaction);
    final color = _typeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetails(transaction),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 3,
        ),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            _typeIcon(type),
            color: color,
            size: 23,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              transaction.voucherNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${transaction.date.day} '
              '${_monthName(transaction.date.month)} '
              '${transaction.date.year}',
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(transaction.totalDebit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              color: surface,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
              ),
              onSelected: (value) {
                if (value == 'view') {
                  _showTransactionDetails(transaction);
                } else if (value == 'edit') {
                  widget.onEdit(transaction);
                } else if (value == 'delete') {
                  _confirmDelete(transaction);
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
                      color: red,
                    ),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    JournalTransaction transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Text(
            'Delete Transaction?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "${transaction.title}" permanently?',
            style: const TextStyle(color: muted),
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
                style: TextStyle(color: red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await widget.onDelete(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: const TextStyle(color: muted),
                prefixIcon: const Icon(
                  Icons.search,
                  color: muted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: muted,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: green),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: _filters.map(_buildFilter).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactions.length} Transactions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedFilter,
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: muted,
                            size: 45,
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'No transactions found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try another search.'
                                : 'Add a transaction to see it here.',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      14, 4, 14, 25,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(
                        transactions[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
