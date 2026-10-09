import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/core/config/app_config.dart';
import 'package:transfa/data/api/api_exception.dart';
import 'package:transfa/data/models/bank.dart';
import 'package:transfa/data/models/gift_card.dart';
import 'package:transfa/data/models/support.dart';
import 'package:transfa/data/models/transaction.dart';
import 'package:transfa/data/models/user.dart';
import 'package:transfa/data/models/wallet.dart';

void main() {
  group('API model serialization', () {
    test('parses a user response', () {
      final user = AppUser.fromJson({
        'id': 'usr_1',
        'full_name': 'Adaeze Okafor',
        'email': 'adaeze@example.com',
        'phone': '+2348012345678',
        'is_verified': true,
      });

      expect(user.fullName, 'Adaeze Okafor');
      expect(user.isVerified, isTrue);
      expect(user.toJson()['full_name'], 'Adaeze Okafor');
    });

    test('parses the backend profile response shape', () {
      final user = AppUser.fromJson({
        'id': 'usr_2',
        'firstName': 'Adaeze',
        'lastName': 'Okafor',
        'phoneNumber': '2348012345678',
        'kycStatus': 'verified',
        'walletStatus': 'active',
      });

      expect(user.fullName, 'Adaeze Okafor');
      expect(user.phone, '2348012345678');
      expect(user.isVerified, isTrue);
    });

    test('parses wallet decimals from numbers or strings', () {
      final wallet = Wallet.fromJson({
        'id': 'wal_1',
        'ngn_balance': '25000.50',
        'usd_equivalent': 16.78,
        'currency': 'NGN',
      });

      expect(wallet.ngnBalance, 25000.50);
      expect(wallet.usdEquivalent, 16.78);
    });

    test('parses the backend wallet balance shape', () {
      final wallet = Wallet.fromJson({
        'balance': 250000,
        'currency': 'NGN',
        'status': 'active',
      });

      expect(wallet.id, 'primary_wallet');
      expect(wallet.ngnBalance, 250000);
      expect(wallet.usdEquivalent, 0);
    });

    test('maps backend transaction types and statuses', () {
      final transaction = AppTransaction.fromJson({
        'id': 'txn_001',
        'type': 'wallet_funding',
        'amount': 50000,
        'currency': 'NGN',
        'status': 'successful',
        'description': 'Wallet funding',
        'createdAt': '2026-05-25T10:30:00Z',
      });

      expect(transaction.type, TxType.credit);
      expect(transaction.status, TxStatus.success);
      expect(transaction.counterpartyName, 'Wallet funding');
    });

    test('round-trips a transfer quote', () {
      final quote = TransferQuote.fromJson({
        'quote_id': 'qte_1',
        'currency': 'USD',
        'amount': 10,
        'ngn_amount': 14900,
        'fee': 178.8,
        'total': 15078.8,
        'fx_rate': 1490,
        'expires_at': '2026-10-08T12:00:00Z',
      });

      expect(quote.currency, TxCurrency.usd);
      expect(quote.toJson()['currency'], 'USD');
      expect(quote.expiresAt.isUtc, isTrue);
    });

    test('parses a wallet summary', () {
      final summary = WalletSummary.fromJson({
        'balance': '250000.25',
        'currency': 'NGN',
        'totalInflow': 400000,
        'totalOutflow': 149999.75,
        'pendingTransactions': 2,
      });

      expect(summary.balance, 250000.25);
      expect(summary.pendingTransactions, 2);
    });

    test('parses a gift card quote', () {
      final quote = GiftCardQuote.fromJson({
        'quoteId': 'quote_gift_1',
        'giftCardId': 'gift_1',
        'giftCardName': 'Reeplay Gift Card',
        'amount': 50,
        'currency': 'USD',
        'totalNgnDebit': 85000,
        'fee': 1000,
        'expiresAt': '2026-10-08T12:00:00Z',
      });

      expect(quote.giftCardName, 'Reeplay Gift Card');
      expect(quote.totalNgnDebit, 85000);
    });

    test('separates gift card purchase and transaction identifiers', () {
      final purchase = GiftCardPurchase.fromJson({
        'purchaseId': 'gift_purchase_1',
        'transactionId': 'txn_gift_1',
        'giftCardName': 'Reeplay Gift Card',
        'amount': 50,
        'currency': 'USD',
        'status': 'delivered',
        'totalNgnDebit': 85000,
        'fee': 1000,
        'redemptionCodeMasked': '****-****-4821',
        'createdAt': '2026-10-08T12:00:00Z',
      });

      expect(purchase.id, 'gift_purchase_1');
      expect(purchase.transactionId, 'txn_gift_1');
      expect(purchase.redemptionCodeMasked, '****-****-4821');
    });

    test('parses a recent beneficiary', () {
      final beneficiary = Beneficiary.fromJson({
        'beneficiaryId': 'beneficiary_1',
        'type': 'ngn_transfer',
        'displayName': 'Adaeze Okafor',
        'bankName': 'Access Bank',
        'bankCode': '044',
        'accountNumber': '0123456789',
        'lastUsedAt': '2026-10-08T12:00:00Z',
      });

      expect(beneficiary.id, 'beneficiary_1');
      expect(beneficiary.bankCode, '044');
    });

    test('parses support ticket messages and attachments', () {
      final ticket = SupportTicket.fromJson({
        'ticketId': 'ticket_1',
        'status': 'in_review',
        'createdAt': '2026-10-08T12:00:00Z',
        'messages': [
          {
            'sender': 'support',
            'message': 'We are checking this transfer.',
            'createdAt': '2026-10-08T12:05:00Z',
            'attachmentUrls': ['https://example.com/update.pdf'],
          },
        ],
      });

      expect(ticket.messages, hasLength(1));
      expect(ticket.messages.single.attachmentUrls, hasLength(1));
    });
  });

  test('real API mode requires a base URL', () {
    const config = AppConfig(apiBaseUrl: '', useMockApi: false);
    expect(config.validate, throwsStateError);
  });

  test('contract error uses the root message and nested machine code', () {
    final options = RequestOptions(path: '/api/v1/wallet/balance');
    final exception = ApiException.fromDioException(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 403,
          data: {
            'success': false,
            'message': 'KYC verification is required.',
            'error': {'code': 'KYC_REQUIRED'},
          },
        ),
      ),
    );

    expect(exception.message, 'KYC verification is required.');
    expect(exception.code, 'KYC_REQUIRED');
  });
}
