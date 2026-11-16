
enum EntrySide {
  debit,
  credit,
}

class LedgerEntry {
  final String id;
  final String transactionId;
  final String accountId;
  final EntrySide side;
  final double amount;
  final String description;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.side,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'accountId': accountId,
      'side': side.name,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      accountId: json['accountId'] as String,
      side: EntrySide.values.firstWhere(
        (value) => value.name == json['side'],
        orElse: () => EntrySide.debit,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
