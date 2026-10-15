enum TxType { credit, debit }

enum TxStatus { pending, success, failed }

enum TxCurrency { ngn, usd, cny }

TxType _txType(Object? value) {
  final normalized = value.toString().toLowerCase();
  if (normalized == 'credit' ||
      normalized == 'wallet_funding' ||
      normalized == 'refund') {
    return TxType.credit;
  }
  return TxType.debit;
}

TxStatus _txStatus(Object? value) {
  final normalized = value.toString().toLowerCase();
  if (normalized == 'success' ||
      normalized == 'successful' ||
      normalized == 'completed') {
    return TxStatus.success;
  }
  if (normalized == 'failed' ||
      normalized == 'reversed' ||
      normalized == 'cancelled') {
    return TxStatus.failed;
  }
  return TxStatus.pending;
}

TxCurrency _txCurrency(Object? value) =>
    TxCurrency.values.byName(value.toString().toLowerCase());
double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

class AppTransaction {
  final String id;
  final TxType type;
  final TxStatus status;
  final TxCurrency currency;
  final double amount;
  final double fee;
  final double totalDebit;
  final String? reference;
  final double? ngnAmount;
  final String counterpartyName;
  final String? counterpartyAccount;
  final String? bankName;
  final String? memo;
  final DateTime createdAt;

  const AppTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.currency,
    required this.amount,
    required this.counterpartyName,
    required this.createdAt,
    this.ngnAmount,
    this.fee = 0,
    this.totalDebit = 0,
    this.reference,
    this.counterpartyAccount,
    this.bankName,
    this.memo,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
    id: json['id'].toString(),
    type: _txType(json['type']),
    status: _txStatus(json['status']),
    currency: _txCurrency(json['currency']),
    amount: _asDouble(json['amount']),
    fee: _optionalDouble(json['fee']),
    totalDebit: _optionalDouble(
      json['totalDebit'] ?? json['total_debit'] ?? json['amount'],
    ),
    reference: json['reference']?.toString(),
    ngnAmount: json['ngn_amount'] == null && json['ngnAmount'] == null
        ? null
        : _asDouble(json['ngn_amount'] ?? json['ngnAmount']),
    counterpartyName:
        (json['counterparty_name'] ??
                json['counterpartyName'] ??
                json['recipientName'] ??
                json['description'] ??
                'Transaction')
            .toString(),
    counterpartyAccount:
        (json['counterparty_account'] ?? json['counterpartyAccount'])
            ?.toString(),
    bankName: (json['bank_name'] ?? json['bankName'])?.toString(),
    memo: (json['memo'] ?? json['narration'])?.toString(),
    createdAt:
        DateTime.tryParse(
          (json['created_at'] ?? json['createdAt'] ?? '').toString(),
        ) ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'currency': currency.name.toUpperCase(),
    'amount': amount,
    'fee': fee,
    'totalDebit': totalDebit,
    if (reference != null) 'reference': reference,
    if (ngnAmount != null) 'ngn_amount': ngnAmount,
    'counterparty_name': counterpartyName,
    if (counterpartyAccount != null)
      'counterparty_account': counterpartyAccount,
    if (bankName != null) 'bank_name': bankName,
    if (memo != null) 'memo': memo,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class TransferQuote {
  final String quoteId;
  final TxCurrency currency;
  final double amount;
  final double ngnAmount;
  final double fee;
  final double total;
  final double? fxRate;
  final DateTime expiresAt;

  const TransferQuote({
    required this.quoteId,
    required this.currency,
    required this.amount,
    required this.ngnAmount,
    required this.fee,
    required this.total,
    required this.expiresAt,
    this.fxRate,
  });

  factory TransferQuote.fromJson(Map<String, dynamic> json) => TransferQuote(
    quoteId: (json['quote_id'] ?? json['quoteId']).toString(),
    currency: _txCurrency(json['currency'] ?? json['payoutCurrency'] ?? 'NGN'),
    amount: _asDouble(json['amount'] ?? json['payoutAmount']),
    ngnAmount: _asDouble(
      json['ngn_amount'] ??
          json['ngnAmount'] ??
          json['totalNgnDebit'] ??
          json['totalDebit'],
    ),
    fee: _asDouble(
      json['fee'] ??
          (_optionalDouble(json['providerFee']) +
              _optionalDouble(json['tfFee'])),
    ),
    total: _asDouble(
      json['total'] ?? json['totalDebit'] ?? json['totalNgnDebit'],
    ),
    fxRate: json['fx_rate'] == null && json['fxRate'] == null
        ? null
        : _asDouble(json['fx_rate'] ?? json['fxRate']),
    expiresAt: DateTime.parse(
      (json['expires_at'] ?? json['expiresAt']).toString(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'quote_id': quoteId,
    'currency': currency.name.toUpperCase(),
    'amount': amount,
    'ngn_amount': ngnAmount,
    'fee': fee,
    'total': total,
    if (fxRate != null) 'fx_rate': fxRate,
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}

double _optionalDouble(Object? value) => value == null ? 0 : _asDouble(value);
