double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

class GiftCardProduct {
  const GiftCardProduct({
    required this.id,
    required this.name,
    required this.currency,
    required this.minAmount,
    required this.maxAmount,
  });

  factory GiftCardProduct.fromJson(Map<String, dynamic> json) =>
      GiftCardProduct(
        id: json['id'].toString(),
        name: json['name'].toString(),
        currency: json['currency'].toString(),
        minAmount: _asDouble(json['minAmount']),
        maxAmount: _asDouble(json['maxAmount']),
      );

  final String id;
  final String name;
  final String currency;
  final double minAmount;
  final double maxAmount;
}

class GiftCardQuote {
  const GiftCardQuote({
    required this.quoteId,
    required this.giftCardId,
    required this.giftCardName,
    required this.amount,
    required this.currency,
    required this.totalNgnDebit,
    required this.fee,
    required this.expiresAt,
  });

  factory GiftCardQuote.fromJson(Map<String, dynamic> json) => GiftCardQuote(
    quoteId: json['quoteId'].toString(),
    giftCardId: json['giftCardId'].toString(),
    giftCardName: json['giftCardName'].toString(),
    amount: _asDouble(json['amount']),
    currency: json['currency'].toString(),
    totalNgnDebit: _asDouble(json['totalNgnDebit']),
    fee: _asDouble(json['fee']),
    expiresAt: DateTime.parse(json['expiresAt'].toString()),
  );

  final String quoteId;
  final String giftCardId;
  final String giftCardName;
  final double amount;
  final String currency;
  final double totalNgnDebit;
  final double fee;
  final DateTime expiresAt;
}

class GiftCardPurchase {
  const GiftCardPurchase({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    this.productImageUrl,
    this.totalNgnDebit,
    this.fee,
    this.createdAt,
    this.deliveredAt,
    this.expiresAt,
    this.redemptionCode,
    this.redemptionCodeMasked,
    this.redemptionInstructions,
  });

  factory GiftCardPurchase.fromJson(Map<String, dynamic> json) =>
      GiftCardPurchase(
        id: (json['purchaseId'] ?? json['id'] ?? json['transactionId'])
            .toString(),
        transactionId: json['transactionId']?.toString(),
        name: (json['giftCardName'] ?? '').toString(),
        amount: _asDouble(json['amount']),
        currency: json['currency'].toString(),
        status: json['status'].toString(),
        productImageUrl: json['productImageUrl']?.toString(),
        totalNgnDebit: _asNullableDouble(json['totalNgnDebit']),
        fee: _asNullableDouble(json['fee']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        deliveredAt: DateTime.tryParse(json['deliveredAt']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
        redemptionCode: json['redemptionCode']?.toString(),
        redemptionCodeMasked: json['redemptionCodeMasked']?.toString(),
        redemptionInstructions: json['redemptionInstructions']?.toString(),
      );

  final String id;
  final String name;
  final double amount;
  final String currency;
  final String status;
  final String? transactionId;
  final String? productImageUrl;
  final double? totalNgnDebit;
  final double? fee;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? expiresAt;
  final String? redemptionCode;
  final String? redemptionCodeMasked;
  final String? redemptionInstructions;
}

double? _asNullableDouble(Object? value) =>
    value == null ? null : _asDouble(value);
