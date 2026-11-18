import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';

class FundTransferScreen extends StatefulWidget {
  final List<LedgerAccount> accounts;

  const FundTransferScreen({
    super.key,
    required this.accounts,
  });

  @override
  State<FundTransferScreen> createState() => _FundTransferScreenState();
}

class _FundTransferScreenState extends State<FundTransferScreen> {
  static const Color background = Color(0xFF080D12);
  static const Color green = Color(0xFF00E676);
  static const Color muted = Color(0xFF9AA7B0);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Fund Transfer');
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  List<LedgerAccount> get _assetAccounts => widget.accounts
      .where((account) =>
          account.type == AccountType.asset && !account.isArchived)
      .toList();

  @override
  void initState() {
    super.initState();
    final assets = _assetAccounts;
    if (assets.isNotEmpty) _fromAccountId = assets.first.id;
    if (assets.length > 1) _toAccountId = assets[1].id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    final amount = double.tryParse(value);
    return amount == null || amount <= 0
        ? '₹0.00'
        : '₹${amount.toStringAsFixed(2)}';
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _selectedDate = selected);
  }

  void _saveTransfer() {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccountId == null || _toAccountId == null) {
      _showMessage('Select both accounts');
      return;
    }
    if (_fromAccountId == _toAccountId) {
      _showMessage('From and To accounts must be different');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final title = _titleController.text.trim();

    final transaction = JournalTransaction(
      id: id,
      voucherNumber: 'TR-$id',
      title: title,
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
          id: '${id}_D',
          transactionId: id,
          accountId: _toAccountId!,
          side: EntrySide.debit,
          amount: amount,
          description: title,
          createdAt: now,
        ),
        LedgerEntry(
          id: '${id}_C',
          transactionId: id,
          accountId: _fromAccountId!,
          side: EntrySide.credit,
          amount: amount,
          description: title,
          createdAt: now,
        ),
      ],
    );

    Navigator.pop(context, transaction);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _glassCard({required Widget child}) {
    final radius = BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.13),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _assetAccounts.any((account) => account.id == value)
          ? value
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      items: _assetAccounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Text(account.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Please select an account' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Fund Transfer'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07111D),
                    Color(0xFF101C2A),
                    Color(0xFF080D14),
                  ],
                ),
              ),
            ),
          ),
          if (_assetAccounts.length < 2)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'At least two active Asset accounts are required to make a transfer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            )
          else
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                color: green, size: 25),
                            SizedBox(width: 9),
                            Text(
                              'Move money between accounts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Transfers affect asset balances only. They are not recorded as income or expense.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 22),
                        _accountDropdown(
                          label: 'From Account',
                          value: _fromAccountId,
                          onChanged: (value) =>
                              setState(() => _fromAccountId = value),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: green.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _accountDropdown(
                          label: 'To Account',
                          value: _toAccountId,
                          onChanged: (value) =>
                              setState(() => _toAccountId = value),
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
                          ),
                          validator: (value) {
                            final amount = double.tryParse(value?.trim() ?? '');
                            if (amount == null ||
                                !amount.isFinite ||
                                amount <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Purpose',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter transfer purpose'
                                  : null,
                        ),
                        const SizedBox(height: 15),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Transfer Date',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _referenceController,
                          decoration: const InputDecoration(
                            labelText: 'Reference (Optional)',
                            prefixIcon: Icon(Icons.tag),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _glassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transfer Amount',
                          style: TextStyle(color: muted),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _amountController,
                          builder: (context, value, child) => Text(
                            _formatAmount(value.text),
                            style: const TextStyle(
                              color: green,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransfer,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_isSaving ? 'Saving...' : 'Save Transfer'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
