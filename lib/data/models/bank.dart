class Bank {
  const Bank({required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) =>
      Bank(code: json['code'].toString(), name: json['name'].toString());

  final String code;
  final String name;
}

class ResolvedBankAccount {
  const ResolvedBankAccount({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    required this.bankName,
  });

  factory ResolvedBankAccount.fromJson(Map<String, dynamic> json) =>
      ResolvedBankAccount(
        accountName: json['accountName'].toString(),
        accountNumber: json['accountNumber'].toString(),
        bankCode: json['bankCode'].toString(),
        bankName: json['bankName'].toString(),
      );

  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String bankName;
}

class BankSuggestion extends ResolvedBankAccount {
  const BankSuggestion({
    required super.accountName,
    required super.accountNumber,
    required super.bankCode,
    required super.bankName,
    required this.confidence,
  });

  factory BankSuggestion.fromJson(Map<String, dynamic> json) => BankSuggestion(
    accountName: json['accountName'].toString(),
    accountNumber: json['accountNumber'].toString(),
    bankCode: json['bankCode'].toString(),
    bankName: json['bankName'].toString(),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
  );

  final double confidence;
}

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.type,
    required this.displayName,
    required this.bankName,
    required this.accountNumber,
    this.bankCode,
    this.accountName,
    this.lastUsedAt,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
    id: (json['beneficiaryId'] ?? json['id']).toString(),
    type: (json['type'] ?? 'ngn_transfer').toString(),
    displayName: (json['displayName'] ?? json['accountName'] ?? '').toString(),
    bankName: (json['bankName'] ?? '').toString(),
    bankCode: json['bankCode']?.toString(),
    accountNumber: (json['accountNumber'] ?? '').toString(),
    accountName: json['accountName']?.toString(),
    lastUsedAt: DateTime.tryParse(json['lastUsedAt']?.toString() ?? ''),
  );

  final String id;
  final String type;
  final String displayName;
  final String bankName;
  final String? bankCode;
  final String accountNumber;
  final String? accountName;
  final DateTime? lastUsedAt;
}
