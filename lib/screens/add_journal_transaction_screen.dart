
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';

enum VoucherType { receipt, payment }

class AddJournalTransactionScreen extends StatefulWidget {
  final List<LedgerAccount> accounts;
  final JournalTransaction? transactionToEdit;

  const AddJournalTransactionScreen({
    super.key,
    required this.accounts,
    this.transactionToEdit,
  });

  @override
  State<AddJournalTransactionScreen> createState() =>
      _AddJournalTransactionScreenState();
}

class _AddJournalTransactionScreenState
    extends State<AddJournalTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  final LedgerService _ledgerService = LedgerService();

  VoucherType _voucherType = VoucherType.receipt;

  String? _cashAccountId;
  String? _ledgerAccountId;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.transactionToEdit != null;

  List<LedgerAccount> get _activeAccounts =>
      widget.accounts.where((account) => !account.isArchived).toList();

  List<LedgerAccount> get _cashAccounts =>
      _activeAccounts.where(
        (account) => account.type == AccountType.asset,
      ).toList();

  List<LedgerAccount> get _ledgerAccounts =>
      _activeAccounts.where(
        (account) =>
            account.id != _cashAccountId &&
            account.type != AccountType.asset,
      ).toList();

  @override
  void initState() {
    super.initState();

    _amountController.addListener(_updateAmount);

    final transaction = widget.transactionToEdit;

    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = _getInitialAmount(transaction);
      _notesController.text = transaction.notes ?? '';
      _referenceController.text =
          transaction.referenceNumber ?? '';
      _selectedDate = transaction.date;

      final debitEntries = transaction.entries
          .where((entry) => entry.side == EntrySide.debit)
          .toList();

      final creditEntries = transaction.entries
          .where((entry) => entry.side == EntrySide.credit)
          .toList();

      if (debitEntries.length == 1 &&
          creditEntries.length == 1) {
        final debitAccount = _findAccount(
          debitEntries.first.accountId,
        );

        if (debitAccount?.type == AccountType.asset) {
          _voucherType = VoucherType.receipt;
          _cashAccountId = debitEntries.first.accountId;
          _ledgerAccountId = creditEntries.first.accountId;
        } else if (_findAccount(
              creditEntries.first.accountId,
            )?.type ==
            AccountType.asset) {
          _voucherType = VoucherType.payment;
          _cashAccountId = creditEntries.first.accountId;
          _ledgerAccountId = debitEntries.first.accountId;
        }
      }
    }

    if (_cashAccountId == null && _cashAccounts.isNotEmpty) {
      _cashAccountId = _cashAccounts.first.id;
    }

    if (_ledgerAccountId == null) {
      final available = _ledgerAccounts;
      if (available.isNotEmpty) {
        _ledgerAccountId = available.first.id;
      }
    }
  }

  String _getInitialAmount(JournalTransaction transaction) {
    if (transaction.entries.isEmpty) return '';

    return transaction.entries.first.amount.toStringAsFixed(2);
  }

  LedgerAccount? _findAccount(String id) {
    for (final account in widget.accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  void _updateAmount() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmount);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cashAccountId == null || _ledgerAccountId == null) {
      _showMessage('Select both accounts');
      return;
    }

    if (_cashAccountId == _ledgerAccountId) {
      _showMessage('Select two different accounts');
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || !amount.isFinite || amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final oldTransaction = widget.transactionToEdit;

    final transactionId = oldTransaction?.id ??
        now.microsecondsSinceEpoch.toString();

    // Receipt: Cash/Bank/UPI Debit, Ledger Credit.
    // Payment: Ledger Debit, Cash/Bank/UPI Credit.
    final debitAccountId =
        _voucherType == VoucherType.receipt
            ? _cashAccountId!
            : _ledgerAccountId!;

    final creditAccountId =
        _voucherType == VoucherType.receipt
            ? _ledgerAccountId!
            : _cashAccountId!;

    final purpose = _titleController.text.trim();

    final transaction = JournalTransaction(
      id: transactionId,
      voucherNumber: oldTransaction?.voucherNumber ??
          'JV-$transactionId',
      title: purpose,
      referenceNumber: _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: _selectedDate,
      createdAt: oldTransaction?.createdAt ?? now,
      entries: [
        LedgerEntry(
          id: '${transactionId}_D',
          transactionId: transactionId,
          accountId: debitAccountId,
          side: EntrySide.debit,
          amount: amount,
          description: purpose,
          createdAt: now,
        ),
        LedgerEntry(
          id: '${transactionId}_C',
          transactionId: transactionId,
          accountId: creditAccountId,
          side: EntrySide.credit,
          amount: amount,
          description: purpose,
          createdAt: now,
        ),
      ],
    );

    if (!_ledgerService.validateTransaction(transaction)) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Transaction is not balanced');
      return;
    }

    if (!mounted) return;

    Navigator.pop(context, transaction);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<LedgerAccount> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = accounts.any(
      (account) => account.id == value,
    )
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(account.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Please select $label' : null,
    );
  }

  Widget _buildVoucherSelector() {
    return SegmentedButton<VoucherType>(
      segments: const [
        ButtonSegment(
          value: VoucherType.receipt,
          label: Text('Receipt'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: VoucherType.payment,
          label: Text('Payment'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {_voucherType},
      onSelectionChanged: (selection) {
        setState(() {
          _voucherType = selection.first;
        });
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF00E676)
              : const Color(0xFF141C24),
        ),
      ),
    );
  }

  Widget _buildTotalAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF123D2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL AMOUNT',
            style: TextStyle(
              color: Color(0xFF9FFFC4),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Entry' : 'New Entry',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'VOUCHER TYPE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            _buildVoucherSelector(),
            const SizedBox(height: 24),

            _buildDropdown(
              label: 'Cash / Bank / UPI Account',
              value: _cashAccountId,
              accounts: _cashAccounts,
              onChanged: (value) {
                setState(() {
                  _cashAccountId = value;
                  if (_ledgerAccountId == value) {
                    _ledgerAccountId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 18),

            _buildDropdown(
              label: 'Ledger Name',
              value: _ledgerAccountId,
              accounts: _ledgerAccounts,
              onChanged: (value) {
                setState(() {
                  _ledgerAccountId = value;
                });
              },
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                hintText: 'Enter transaction purpose',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter purpose';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null ||
                    !parsed.isFinite ||
                    parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildTotalAmount(),
            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Date: ${_selectedDate.day}/'
                '${_selectedDate.month}/'
                '${_selectedDate.year}',
              ),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference Number (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                icon: const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                          ? 'Update Entry'
                          : 'Save Entry',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
