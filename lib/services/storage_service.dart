
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

class StorageService {
  static const String _storageKey = 'andromoney_transactions';

  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final storedData = prefs.getString(_storageKey);

    if (storedData == null || storedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(storedData);

      return decodedData.map((item) {
        return Transaction.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } catch (error) {
      return [];
    }
  }

  Future<void> saveTransactions(
    List<Transaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      transactions.map((item) => item.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> clearTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
