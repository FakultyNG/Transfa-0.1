class Wallet {
  final String id;
  final double ngnBalance;
  final double usdEquivalent;
  final String currency;

  const Wallet({
    required this.id,
    required this.ngnBalance,
    required this.usdEquivalent,
    this.currency = 'NGN',
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: (json['id'] ?? 'primary_wallet').toString(),
    ngnBalance: _asDouble(
      json['balance'] ?? json['ngn_balance'] ?? json['ngnBalance'],
    ),
    usdEquivalent:
        json['usd_equivalent'] == null && json['usdEquivalent'] == null
        ? 0
        : _asDouble(json['usd_equivalent'] ?? json['usdEquivalent']),
    currency: (json['currency'] ?? 'NGN').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ngn_balance': ngnBalance,
    'usd_equivalent': usdEquivalent,
    'currency': currency,
  };
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.currency,
    required this.totalInflow,
    required this.totalOutflow,
    required this.pendingTransactions,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
    balance: _asDouble(json['balance']),
    currency: (json['currency'] ?? 'NGN').toString(),
    totalInflow: _asDouble(json['totalInflow']),
    totalOutflow: _asDouble(json['totalOutflow']),
    pendingTransactions: (json['pendingTransactions'] as num?)?.toInt() ?? 0,
  );

  final double balance;
  final String currency;
  final double totalInflow;
  final double totalOutflow;
  final int pendingTransactions;
}

class DedicatedVirtualAccount {
  final String accountNumber;
  final String accountName;
  final String bankName;

  const DedicatedVirtualAccount({
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
  });

  factory DedicatedVirtualAccount.fromJson(Map<String, dynamic> json) =>
      DedicatedVirtualAccount(
        accountNumber: (json['account_number'] ?? json['accountNumber'] ?? '')
            .toString(),
        accountName: (json['account_name'] ?? json['accountName'] ?? '')
            .toString(),
        bankName: (json['bank_name'] ?? json['bankName'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'account_number': accountNumber,
    'account_name': accountName,
    'bank_name': bankName,
  };
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}
