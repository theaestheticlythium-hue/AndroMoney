
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger_account.dart';
import '../models/journal_transaction.dart';

class LedgerStorageService {
  static const String _accountsKey = 'andromoney_ledger_accounts_v1';
  static const String _transactionsKey =
      'andromoney_journal_transactions_v1';

  Future<List<LedgerAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_accountsKey);

    if (storedData == null || storedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(storedData);

      return decodedData.map((item) {
        return LedgerAccount.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAccounts(List<LedgerAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      accounts.map((account) => account.toJson()).toList(),
    );

    await prefs.setString(_accountsKey, encodedData);
  }

  Future<List<JournalTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_transactionsKey);

    if (storedData == null || storedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(storedData);

      return decodedData.map((item) {
        return JournalTransaction.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(
    List<JournalTransaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );

    await prefs.setString(_transactionsKey, encodedData);
  }

  Future<List<LedgerAccount>> initializeDefaultAccounts() async {
    final existingAccounts = await loadAccounts();

    // Existing accounts undenkil default accounts veendum create cheyyilla.
    if (existingAccounts.isNotEmpty) {
      return existingAccounts;
    }

    final now = DateTime.now();

    final defaultAccounts = <LedgerAccount>[
      LedgerAccount(
        id: 'cash',
        name: 'Cash',
        type: AccountType.asset,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'bank',
        name: 'Bank',
        type: AccountType.asset,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'upi',
        name: 'UPI Wallet',
        type: AccountType.asset,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'credit_card',
        name: 'Credit Card',
        type: AccountType.liability,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'capital',
        name: "Owner's Capital",
        type: AccountType.equity,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'salary',
        name: 'Salary',
        type: AccountType.income,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'other_income',
        name: 'Other Income',
        type: AccountType.income,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'food',
        name: 'Food',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'travel',
        name: 'Travel',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'shopping',
        name: 'Shopping',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'bills',
        name: 'Bills',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'health',
        name: 'Health',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'education',
        name: 'Education',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
      LedgerAccount(
        id: 'other_expense',
        name: 'Other Expenses',
        type: AccountType.expense,
        isSystem: true,
        createdAt: now,
      ),
    ];

    await saveAccounts(defaultAccounts);

    return defaultAccounts;
  }
}
