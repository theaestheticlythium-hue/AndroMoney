
import 'ledger_entry.dart';

class JournalTransaction {
  final String id;
  final String voucherNumber;
  final String title;
  final String? referenceNumber;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;
  final List<LedgerEntry> entries;

  const JournalTransaction({
    required this.id,
    required this.voucherNumber,
    required this.title,
    this.referenceNumber,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.entries,
  });

  double get totalDebit {
    return entries
        .where((entry) => entry.side == EntrySide.debit)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get totalCredit {
    return entries
        .where((entry) => entry.side == EntrySide.credit)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  bool get isBalanced {
    return entries.length >= 2 &&
        totalDebit > 0 &&
        (totalDebit - totalCredit).abs() < 0.005;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voucherNumber': voucherNumber,
      'title': title,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory JournalTransaction.fromJson(Map<String, dynamic> json) {
    return JournalTransaction(
      id: json['id'] as String,
      voucherNumber: json['voucherNumber'] as String,
      title: json['title'] as String,
      referenceNumber: json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map(
            (item) => LedgerEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
