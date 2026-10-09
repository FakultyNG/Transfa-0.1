import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../api/transfa_api.dart';
import '../models/auth.dart';
import '../models/bank.dart';
import '../models/device_features.dart';
import '../models/gift_card.dart';
import '../models/notification.dart';
import '../models/support.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import 'mock_data.dart';

class MockApi implements TransfaApi {
  MockApi._();
  static final MockApi instance = MockApi._();

  final _rng = Random();
  final List<AppTransaction> _transactions = [...MockData.transactions];
  Wallet _wallet = MockData.wallet;
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_mock_1',
      type: 'wallet_funded',
      category: 'transactions',
      header: 'Wallet funded',
      body: 'Your wallet funding was successful.',
      isRead: false,
      createdAt: DateTime.now(),
    ),
  ];
  final List<SupportTicket> _tickets = [];
  final List<GiftCardPurchase> _giftCardPurchases = [
    GiftCardPurchase(
      id: 'gift_purchase_mock_1',
      transactionId: 'txn_gift_mock_1',
      name: 'Reeplay Gift Card',
      amount: 25,
      currency: 'USD',
      status: 'delivered',
      totalNgnDebit: 43000,
      fee: 1000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      deliveredAt: DateTime.now().subtract(const Duration(days: 2)),
      redemptionCodeMasked: '****-****-4821',
      redemptionInstructions: 'Redeem with the issuing merchant.',
    ),
  ];
  final List<Beneficiary> _beneficiaries = const [
    Beneficiary(
      id: 'ben_mock_1',
      type: 'ngn_transfer',
      displayName: 'DEMO RECIPIENT',
      bankName: 'Access Bank',
      bankCode: '044',
      accountNumber: '0123456789',
      accountName: 'DEMO RECIPIENT',
    ),
  ];
  bool _biometricEnabled = false;
  bool _cashDropEnabled = false;

  Future<T> _delay<T>(T value, {int min = 250, int max = 650}) {
    final ms = min + _rng.nextInt(max - min);
    return Future.delayed(Duration(milliseconds: ms), () => value);
  }

  @override
  Future<RegistrationStart> startRegistration(String phoneNumber) => _delay(
    RegistrationStart(
      registrationToken: 'reg_mock_${_rng.nextInt(99999)}',
      phoneNumber: phoneNumber,
      requiresOtp: true,
    ),
  );

  @override
  Future<OtpChallenge> sendOtp(String phoneNumber) => _delay(
    OtpChallenge(
      phoneNumber: phoneNumber,
      otpReference: 'otp_mock_${_rng.nextInt(99999)}',
    ),
  );

  @override
  Future<OtpChallenge> resendOtp({
    required String phoneNumber,
    required String otpReference,
  }) => sendOtp(phoneNumber);

  @override
  Future<bool> validateOtp({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) => _delay(otp.length == 6);

  @override
  Future<AppUser> completeRegistration({
    required String registrationToken,
    required String passcode,
  }) => _delay(MockData.currentUser);

  @override
  Future<AppUser> login({
    required String phoneNumber,
    required String passcode,
  }) => _delay(MockData.currentUser);

  @override
  Future<void> logout() async {
    await _delay(true);
  }

  @override
  Future<AppUser> getProfile() => _delay(MockData.currentUser);

  @override
  Future<void> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) async {
    await _delay(true);
  }

  @override
  Future<OtpChallenge> requestPasscodeReset(String phoneNumber) =>
      sendOtp(phoneNumber);

  @override
  Future<String> verifyPasscodeReset({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) => _delay('reset_mock_${_rng.nextInt(99999)}');

  @override
  Future<void> completePasscodeReset({
    required String resetToken,
    required String newPasscode,
  }) async {
    await _delay(true);
  }

  @override
  Future<BvnVerification> verifyBvn({
    required String registrationToken,
    required String bvn,
  }) => _delay(
    BvnVerification(
      kycReference: 'kyc_mock_${_rng.nextInt(99999)}',
      bvnVerified: bvn.length == 11,
    ),
  );

  @override
  Future<bool> validateBvnSelfie({
    required String registrationToken,
    required String kycReference,
    required String selfieImageBase64,
  }) => _delay(selfieImageBase64.isNotEmpty);

  @override
  Future<Map<String, dynamic>> getKycStatus() => _delay({
    'kycStatus': 'verified',
    'bvnVerified': true,
    'selfieVerified': true,
    'walletEligible': true,
  });

  @override
  Future<Wallet> getWallet() => _delay(_wallet);

  @override
  Future<WalletSummary> getWalletSummary() => _delay(
    WalletSummary(
      balance: _wallet.ngnBalance,
      currency: 'NGN',
      totalInflow: 500000,
      totalOutflow: 250000,
      pendingTransactions: 1,
    ),
  );

  @override
  Future<AppTransaction> verifyFunding(String reference) {
    final transaction = AppTransaction(
      id: 'txn_funding_${_rng.nextInt(99999)}',
      type: TxType.credit,
      status: TxStatus.success,
      currency: TxCurrency.ngn,
      amount: 50000,
      counterpartyName: 'Wallet funding',
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, transaction);
    return _delay(transaction);
  }

  @override
  Future<DedicatedVirtualAccount> getDva() => _delay(MockData.dva);

  @override
  Future<DedicatedVirtualAccount> createDva() => _delay(MockData.dva);

  @override
  Future<List<Bank>> getNgnBanks() => _delay(const [
    Bank(code: '044', name: 'Access Bank'),
    Bank(code: '058', name: 'GTBank'),
    Bank(code: '035', name: 'Wema Bank'),
  ]);

  @override
  Future<ResolvedBankAccount> resolveNgnAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    final banks = await getNgnBanks();
    final bank = banks.firstWhere((item) => item.code == bankCode);
    return _delay(
      ResolvedBankAccount(
        accountName: 'DEMO RECIPIENT',
        accountNumber: accountNumber,
        bankCode: bankCode,
        bankName: bank.name,
      ),
    );
  }

  @override
  Future<List<BankSuggestion>> suggestNgnBanks(String accountNumber) => _delay([
    BankSuggestion(
      accountName: 'DEMO RECIPIENT',
      accountNumber: accountNumber,
      bankCode: '044',
      bankName: 'Access Bank',
      confidence: 95,
    ),
  ]);

  @override
  Future<TransferQuote> quoteNgnTransfer({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String narration,
  }) {
    final fee = amount < 5000 ? 10.0 : (amount < 50000 ? 25.0 : 50.0);
    return _delay(
      TransferQuote(
        quoteId: 'quote_ngn_${_rng.nextInt(99999)}',
        currency: TxCurrency.ngn,
        amount: amount,
        ngnAmount: amount,
        fee: fee,
        total: amount + fee,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
  }

  @override
  Future<TransferQuote> quoteUsdTransfer({
    required double amount,
    required String recipientCountry,
    required String purpose,
    required String paymentReference,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String swiftCode,
    String? routingNumber,
  }) {
    final ngn = amount * MockData.usdToNgnRate;
    final fee = 4000.0;
    return _delay(
      TransferQuote(
        quoteId: 'quote_usd_${_rng.nextInt(99999)}',
        currency: TxCurrency.usd,
        amount: amount,
        ngnAmount: ngn,
        fee: fee,
        total: ngn + fee,
        fxRate: MockData.usdToNgnRate,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
  }

  @override
  Future<TransferQuote> quoteCnyTransfer({
    required double amount,
    required String recipientCountry,
    required String purpose,
    required String paymentReference,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String swiftCode,
  }) {
    const rate = 230.0;
    final ngn = amount * rate;
    const fee = 5500.0;
    return _delay(
      TransferQuote(
        quoteId: 'quote_cny_${_rng.nextInt(99999)}',
        currency: TxCurrency.cny,
        amount: amount,
        ngnAmount: ngn,
        fee: fee,
        total: ngn + fee,
        fxRate: rate,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
  }

  @override
  Future<AppTransaction> confirmTransfer({
    required TransferQuote quote,
    required String passcode,
    required String recipientName,
    String? recipientAccount,
    String? bankName,
    String? memo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final transaction = AppTransaction(
      id: 'txn_${_rng.nextInt(99999)}',
      type: TxType.debit,
      status: TxStatus.pending,
      currency: quote.currency,
      amount: quote.amount,
      ngnAmount: quote.total,
      counterpartyName: recipientName,
      counterpartyAccount: recipientAccount,
      bankName: bankName,
      memo: memo,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, transaction);
    _wallet = Wallet(
      id: _wallet.id,
      ngnBalance: _wallet.ngnBalance - quote.total,
      usdEquivalent: 0,
    );
    return transaction;
  }

  @override
  Future<List<AppTransaction>> listTransactions() =>
      _delay(List.unmodifiable(_transactions));

  @override
  Future<AppTransaction?> getTransaction(String id) => _delay(
    _transactions.where((transaction) => transaction.id == id).firstOrNull,
  );

  @override
  Future<List<Beneficiary>> listBeneficiaries(String type) =>
      _delay(_beneficiaries.where((item) => item.type == type).toList());

  @override
  Future<List<Beneficiary>> searchBeneficiaries({
    required String query,
    required String type,
  }) => _delay(
    _beneficiaries
        .where(
          (item) =>
              item.type == type &&
              '${item.displayName} ${item.accountNumber} ${item.bankName}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList(),
  );

  @override
  Future<void> deleteBeneficiary(String id) async {
    await _delay(true);
  }

  @override
  Future<List<GiftCardProduct>> listGiftCards() => _delay(const [
    GiftCardProduct(
      id: 'gift_reeplay_usd',
      name: 'Reeplay Gift Card',
      currency: 'USD',
      minAmount: 10,
      maxAmount: 2500,
    ),
  ]);

  @override
  Future<GiftCardQuote> quoteGiftCard({
    required String giftCardId,
    required double amount,
    required String currency,
  }) => _delay(
    GiftCardQuote(
      quoteId: 'quote_gift_${_rng.nextInt(99999)}',
      giftCardId: giftCardId,
      giftCardName: 'Reeplay Gift Card',
      amount: amount,
      currency: currency,
      totalNgnDebit: amount * 1680 + 1000,
      fee: 1000,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ),
  );

  @override
  Future<GiftCardPurchase> buyGiftCard({
    required String quoteId,
    required String passcode,
  }) async {
    final suffix = _rng.nextInt(99999);
    final purchase = GiftCardPurchase(
      id: 'gift_purchase_$suffix',
      transactionId: 'txn_gift_$suffix',
      name: 'Reeplay Gift Card',
      amount: 50,
      currency: 'USD',
      status: 'processing',
      totalNgnDebit: 85000,
      fee: 1000,
      createdAt: DateTime.now(),
    );
    _giftCardPurchases.insert(0, purchase);
    return _delay(purchase);
  }

  @override
  Future<List<GiftCardPurchase>> listGiftCardPurchases({
    int page = 1,
    int limit = 20,
    String? status,
  }) => _delay(
    _giftCardPurchases
        .where((item) => status == null || item.status == status)
        .skip((page - 1) * limit)
        .take(limit)
        .toList(),
  );

  @override
  Future<GiftCardPurchase> getGiftCard(String id) {
    final purchase = _giftCardPurchases
        .where((item) => item.id == id)
        .firstOrNull;
    return _delay(
      purchase ??
          GiftCardPurchase(
            id: id,
            name: 'Reeplay Gift Card',
            amount: 50,
            currency: 'USD',
            status: 'delivered',
          ),
    );
  }

  @override
  Future<List<AppNotification>> listNotifications() =>
      _delay(List.unmodifiable(_notifications));

  @override
  Future<void> markNotificationRead(String id) async {
    await _delay(true);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _delay(true);
  }

  @override
  Future<void> registerDeviceToken({
    required String deviceId,
    required String fcmToken,
    required String platform,
  }) async {
    await _delay(true);
  }

  @override
  Future<void> removeDeviceToken(String deviceId) async {
    await _delay(true);
  }

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  }) => _delay(
    MockData.currentUser.copyWith(
      fullName: '$firstName $lastName',
      email: email,
      dateOfBirth: dateOfBirth,
    ),
  );

  @override
  Future<BiometricStatus> getBiometricStatus() => _delay(
    BiometricStatus(
      enabled: _biometricEnabled,
      method: _biometricEnabled ? 'biometric' : null,
      deviceId: 'device_mock',
    ),
  );

  @override
  Future<BiometricStatus> enableBiometric({
    required String method,
    required String deviceId,
  }) {
    _biometricEnabled = true;
    return _delay(
      BiometricStatus(enabled: true, method: method, deviceId: deviceId),
    );
  }

  @override
  Future<void> disableBiometric(String deviceId) async {
    _biometricEnabled = false;
    await _delay(true);
  }

  @override
  Future<AppUser> biometricLogin(String deviceId) =>
      _delay(MockData.currentUser);

  @override
  Future<CashDropStatus> getCashDropStatus() => _delay(
    CashDropStatus(
      enabled: _cashDropEnabled,
      status: _cashDropEnabled ? 'active' : 'disabled',
      id: 'cashdrop_mock',
    ),
  );

  @override
  Future<CashDropStatus> registerCashDrop() {
    _cashDropEnabled = true;
    return getCashDropStatus();
  }

  @override
  Future<CashDropStatus> disableCashDrop(String reason) {
    _cashDropEnabled = false;
    return getCashDropStatus();
  }

  @override
  Future<CashDropMatch> resolveCashDrop(String scannedImageBase64) => _delay(
    const CashDropMatch(
      receiverId: 'usr_receiver_mock',
      displayName: 'Demo Recipient',
      bankName: 'Wema Bank',
      accountNumber: '1234567890',
      accountName: 'TRANSFA DEMO RECIPIENT',
      matchConfidence: 96.4,
    ),
  );

  @override
  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
    String? transactionId,
    String? category,
    List<String> attachmentUrls = const [],
  }) {
    final ticket = SupportTicket(
      id: 'ticket_mock_${_rng.nextInt(99999)}',
      status: 'open',
      subject: subject,
      createdAt: DateTime.now(),
      transactionId: transactionId,
      messages: [
        SupportMessage(
          sender: 'user',
          message: message,
          createdAt: DateTime.now(),
          attachmentUrls: attachmentUrls,
        ),
      ],
    );
    _tickets.insert(0, ticket);
    return _delay(ticket);
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() =>
      _delay(List.unmodifiable(_tickets));

  @override
  Future<SupportTicket> getSupportTicket(String id) =>
      _delay(_tickets.firstWhere((ticket) => ticket.id == id));

  @override
  Future<void> replySupportTicket({
    required String id,
    required String message,
    List<String> attachmentUrls = const [],
  }) async {
    await _delay(true);
  }

  @override
  Future<void> closeSupportTicket(String id) async {
    await _delay(true);
  }

  @override
  Future<SupportAttachment> uploadSupportAttachment({
    required Uint8List bytes,
    required String fileName,
  }) => _delay(
    SupportAttachment(
      url: 'https://example.invalid/mock/$fileName',
      fileName: fileName,
      fileType: 'image/jpeg',
      fileSize: bytes.length,
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
