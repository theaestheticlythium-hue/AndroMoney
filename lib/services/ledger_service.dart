
import '../models/ledger_account.dart';
import '../models/ledger_entry.dart';
import '../models/journal_transaction.dart';

class LedgerService {
  static const double _tolerance = 0.005;

  bool validateTransaction(JournalTransaction transaction) {
    if (transaction.entries.length < 2) {
      return false;
    }

    if (transaction.entries.any(
      (entry) => !entry.amount.isFinite || entry.amount <= 0,
    )) {
      return false;
    }

    if (transaction.entries.any(
      (entry) => entry.transactionId != transaction.id,
    )) {
      return false;
    }

    return (transaction.totalDebit - transaction.totalCredit)
            .abs() <
        _tolerance;
  }

  double getAccountBalance({
    required LedgerAccount account,
    required List<JournalTransaction> transactions,
  }) {
    double debit = 0;
    double credit = 0;

    for (final transaction in transactions) {
      for (final entry in transaction.entries) {
        if (entry.accountId != account.id) continue;

        if (entry.side == EntrySide.debit) {
          debit += entry.amount;
        } else {
          credit += entry.amount;
        }
      }
    }

    final movement = account.normalBalance == BalanceSide.debit
        ? debit - credit
        : credit - debit;

    return account.openingBalance + movement;
  }

  List<LedgerEntry> getAccountEntries({
    required String accountId,
    required List<JournalTransaction> transactions,
  }) {
    final entries = transactions
        .expand((transaction) => transaction.entries)
        .where((entry) => entry.accountId == accountId)
        .toList();

    entries.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    return entries;
  }

  double getTotalDebits(List<JournalTransaction> transactions) {
    return transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.totalDebit,
    );
  }

  double getTotalCredits(List<JournalTransaction> transactions) {
    return transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.totalCredit,
    );
  }

  bool isLedgerBalanced(List<JournalTransaction> transactions) {
    return transactions.every(validateTransaction) &&
        (getTotalDebits(transactions) -
                    getTotalCredits(transactions))
                .abs() <
            _tolerance;
  }
}
