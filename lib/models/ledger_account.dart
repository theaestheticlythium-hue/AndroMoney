
enum AccountType {
  asset,
  liability,
  equity,
  income,
  expense,
}

enum BalanceSide {
  debit,
  credit,
}

class LedgerAccount {
  final String id;
  final String name;
  final AccountType type;
  final double openingBalance;
  final String currencyCode;
  final bool isSystem;
  final bool isArchived;
  final DateTime createdAt;

  const LedgerAccount({
    required this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.currencyCode = 'INR',
    this.isSystem = false,
    this.isArchived = false,
    required this.createdAt,
  });

  // Assets and expenses normally carry debit balances.
  // Liabilities, equity and income normally carry credit balances.
  BalanceSide get normalBalance {
    switch (type) {
      case AccountType.asset:
      case AccountType.expense:
        return BalanceSide.debit;

      case AccountType.liability:
      case AccountType.equity:
      case AccountType.income:
        return BalanceSide.credit;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'openingBalance': openingBalance,
      'currencyCode': currencyCode,
      'isSystem': isSystem,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerAccount.fromJson(Map<String, dynamic> json) {
    return LedgerAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AccountType.asset,
      ),
      openingBalance:
          (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      isSystem: json['isSystem'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  LedgerAccount copyWith({
    String? name,
    AccountType? type,
    double? openingBalance,
    String? currencyCode,
    bool? isArchived,
  }) {
    return LedgerAccount(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currencyCode: currencyCode ?? this.currencyCode,
      isSystem: isSystem,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }
}
