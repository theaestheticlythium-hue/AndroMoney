
import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';
import '../services/ledger_service.dart';

class AddJournalTransactionScreen extends StatefulWidget {
  final List<LedgerAccount> accounts;

  const AddJournalTransactionScreen({
    super.key,
    required this.accounts,
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

  String? _debitAccountId;
  String? _creditAccountId;
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  @override
  void dispose() {
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

    if (_debitAccountId == null || _creditAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select both Debit and Credit accounts'),
        ),
      );
      return;
    }

    if (_debitAccountId == _creditAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debit and Credit accounts must be different'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || !amount.isFinite || amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final transactionId = now.microsecondsSinceEpoch.toString();

    final transaction = JournalTransaction(
      id: transactionId,
      voucherNumber: 'JV-$transactionId',
      title: _titleController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: _selectedDate,
      createdAt: now,
      entries: [
        LedgerEntry(
          id: '${transactionId}_D',
          transactionId: transactionId,
          accountId: _debitAccountId!,
          side: EntrySide.debit,
          amount: amount,
          description: _titleController.text.trim(),
          createdAt: now,
        ),
        LedgerEntry(
          id: '${transactionId}_C',
          transactionId: transactionId,
          accountId: _creditAccountId!,
          side: EntrySide.credit,
          amount: amount,
          description: _titleController.text.trim(),
          createdAt: now,
        ),
      ],
    );

    if (!_ledgerService.validateTransaction(transaction)) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction is not balanced'),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pop(context, transaction);
  }

  Widget _buildAccountDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: widget.accounts
          .where((account) => !account.isArchived)
          .map((account) {
        return DropdownMenuItem<String>(
          value: account.id,
          child: Text(
            '${account.name} (${account.type.name})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) return 'Please select an account';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Transaction Title',
                hintText: 'Example: Grocery purchase',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter transaction title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter a valid amount';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildAccountDropdown(
              label: 'Debit Account',
              value: _debitAccountId,
              onChanged: (value) {
                setState(() {
                  _debitAccountId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            _buildAccountDropdown(
              label: 'Credit Account',
              value: _creditAccountId,
              onChanged: (value) {
                setState(() {
                  _creditAccountId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Date: ${_selectedDate.day}/'
                '${_selectedDate.month}/'
                '${_selectedDate.year}',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference Number (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

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
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                icon: const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Transaction',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
