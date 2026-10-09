import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction.dart';

/// State shared across the transfer flow (Transfer → Details → Confirm → Status).
/// Kept simple — a single in-memory object the screens read & write.
class TransferDraft {
  final TxCurrency currency;
  final double? amount;
  final String? recipientName;
  final String? recipientAccount;
  final String? bankName;
  final String? bankCode;
  final String? swiftCode;
  final String? routingNumber;
  final String? recipientCountry;
  final String? memo;
  final TransferQuote? quote;

  const TransferDraft({
    this.currency = TxCurrency.ngn,
    this.amount,
    this.recipientName,
    this.recipientAccount,
    this.bankName,
    this.bankCode,
    this.swiftCode,
    this.routingNumber,
    this.recipientCountry,
    this.memo,
    this.quote,
  });

  TransferDraft copyWith({
    TxCurrency? currency,
    double? amount,
    String? recipientName,
    String? recipientAccount,
    String? bankName,
    String? bankCode,
    String? swiftCode,
    String? routingNumber,
    String? recipientCountry,
    String? memo,
    TransferQuote? quote,
  }) => TransferDraft(
    currency: currency ?? this.currency,
    amount: amount ?? this.amount,
    recipientName: recipientName ?? this.recipientName,
    recipientAccount: recipientAccount ?? this.recipientAccount,
    bankName: bankName ?? this.bankName,
    bankCode: bankCode ?? this.bankCode,
    swiftCode: swiftCode ?? this.swiftCode,
    routingNumber: routingNumber ?? this.routingNumber,
    recipientCountry: recipientCountry ?? this.recipientCountry,
    memo: memo ?? this.memo,
    quote: quote ?? this.quote,
  );
}

final transferDraftProvider = StateProvider<TransferDraft>(
  (_) => const TransferDraft(),
);
