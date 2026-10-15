import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/auth.dart';
import '../models/bank.dart';
import '../models/device_features.dart';
import '../models/gift_card.dart';
import '../models/notification.dart';
import '../models/support.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'session_store.dart';
import 'transfa_api.dart';

class RestTransfaApi implements TransfaApi {
  RestTransfaApi({
    required ApiClient client,
    required SessionStore sessionStore,
  }) : _client = client,
       _sessionStore = sessionStore;

  static const _api = ApiClient.apiPrefix;

  final ApiClient _client;
  final SessionStore _sessionStore;

  @override
  Future<RegistrationStart> startRegistration(String phoneNumber) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/register/start',
        data: {'phoneNumber': phoneNumber},
        allowRefresh: false,
      ),
    );
    return RegistrationStart.fromJson(data);
  }

  @override
  Future<OtpChallenge> sendOtp(String phoneNumber) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/otp/send',
        data: {'phoneNumber': phoneNumber},
        allowRefresh: false,
      ),
    );
    return OtpChallenge.fromJson(data);
  }

  @override
  Future<OtpChallenge> resendOtp({
    required String phoneNumber,
    required String otpReference,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/otp/resend',
        data: {'phoneNumber': phoneNumber, 'otpReference': otpReference},
        allowRefresh: false,
      ),
    );
    return OtpChallenge(
      phoneNumber: phoneNumber,
      otpReference: data['otpReference'].toString(),
    );
  }

  @override
  Future<bool> validateOtp({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/otp/validate',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
          'otpReference': otpReference,
        },
        allowRefresh: false,
      ),
    );
    return data['phoneVerified'] == true;
  }

  @override
  Future<AppUser> completeRegistration({
    required String registrationToken,
    required String passcode,
  }) => _authenticate('$_api/auth/register/complete', {
    'registrationToken': registrationToken,
    'passcode': passcode,
  });

  @override
  Future<AppUser> login({
    required String phoneNumber,
    required String passcode,
  }) => _authenticate('$_api/auth/login', {
    'phoneNumber': phoneNumber,
    'passcode': passcode,
  });

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final data = _dataMap(
      await _client.post(path, data: body, allowRefresh: false),
    );
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(message: 'The server did not return a session.');
    }
    await _sessionStore.write(
      AuthSession(accessToken: accessToken, refreshToken: refreshToken),
    );
    return AppUser.fromJson(_requiredMap(data['user']));
  }

  @override
  Future<void> logout() async {
    try {
      _data(await _client.post('$_api/auth/logout'));
    } finally {
      await _sessionStore.clear();
    }
  }

  @override
  Future<AppUser> getProfile() async {
    final data = _dataMap(await _client.get('$_api/profile'));
    return AppUser.fromJson(data);
  }

  @override
  Future<void> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) async {
    _data(
      await _client.patch(
        '$_api/auth/passcode/change',
        data: {'oldPasscode': oldPasscode, 'newPasscode': newPasscode},
      ),
    );
  }

  @override
  Future<OtpChallenge> requestPasscodeReset(String phoneNumber) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/passcode/reset/request',
        data: {'phoneNumber': phoneNumber},
        allowRefresh: false,
      ),
    );
    return OtpChallenge(
      phoneNumber: phoneNumber,
      otpReference: data['otpReference'].toString(),
    );
  }

  @override
  Future<String> verifyPasscodeReset({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/auth/passcode/reset/verify',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
          'otpReference': otpReference,
        },
        allowRefresh: false,
      ),
    );
    return data['resetToken'].toString();
  }

  @override
  Future<void> completePasscodeReset({
    required String resetToken,
    required String newPasscode,
  }) async {
    _data(
      await _client.post(
        '$_api/auth/passcode/reset/complete',
        data: {'resetToken': resetToken, 'newPasscode': newPasscode},
        allowRefresh: false,
      ),
    );
  }

  @override
  Future<BvnVerification> verifyBvn({
    required String registrationToken,
    required String bvn,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/kyc/bvn/verify',
        data: {'registrationToken': registrationToken, 'bvn': bvn},
        allowRefresh: false,
      ),
    );
    return BvnVerification.fromJson(data);
  }

  @override
  Future<SelfieVerification> validateBvnSelfie({
    required String registrationToken,
    required String kycReference,
    required String selfieImageBase64,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/kyc/bvn/selfie-validate',
        data: {
          'registrationToken': registrationToken,
          'kycReference': kycReference,
          'selfieImageBase64': selfieImageBase64,
        },
        allowRefresh: false,
      ),
    );
    return SelfieVerification.fromJson(data);
  }

  @override
  Future<LivenessSession> startBvnLiveness({
    required String registrationToken,
    required String kycReference,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/kyc/bvn/liveness/start',
        data: {
          'registrationToken': registrationToken,
          'kycReference': kycReference,
        },
        allowRefresh: false,
      ),
    );
    return LivenessSession.fromJson(data);
  }

  @override
  Future<LivenessStatus> getBvnLivenessStatus({
    required String registrationToken,
    required String kycReference,
    required String livenessSessionId,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/kyc/bvn/liveness/status',
        data: {
          'registrationToken': registrationToken,
          'kycReference': kycReference,
          'livenessSessionId': livenessSessionId,
        },
        allowRefresh: false,
      ),
    );
    return LivenessStatus.fromJson(data);
  }

  @override
  Future<SelfieVerification> completeBvnLiveness({
    required String registrationToken,
    required String kycReference,
    required String livenessSessionId,
    required String profileImageBase64,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/kyc/bvn/liveness/complete',
        data: {
          'registrationToken': registrationToken,
          'kycReference': kycReference,
          'livenessSessionId': livenessSessionId,
          'profileImageBase64': profileImageBase64,
        },
        allowRefresh: false,
      ),
    );
    return SelfieVerification.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> getKycStatus() async =>
      _dataMap(await _client.get('$_api/kyc/status'));

  @override
  Future<Wallet> getWallet() async {
    final data = _dataMap(await _client.get('$_api/wallet/balance'));
    return Wallet.fromJson(data);
  }

  @override
  Future<WalletSummary> getWalletSummary() async => WalletSummary.fromJson(
    _dataMap(await _client.get('$_api/wallet/summary')),
  );

  @override
  Future<AppTransaction> verifyFunding(String reference) async {
    final data = _dataMap(
      await _client.post(
        '$_api/funding/verify',
        data: {'reference': reference},
      ),
    );
    return AppTransaction.fromJson({
      ...data,
      'id': data['transactionId'],
      'type': 'wallet_funding',
      'description': 'Wallet funding',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<DedicatedVirtualAccount> getDva() async {
    final data = _dataMap(await _client.get('$_api/wallet/dva'));
    return DedicatedVirtualAccount.fromJson(data);
  }

  @override
  Future<DedicatedVirtualAccount> createDva() async {
    final data = _dataMap(
      await _client.post(
        '$_api/wallet/dva/create',
        data: {'preferredBank': 'auto'},
      ),
    );
    return DedicatedVirtualAccount.fromJson(data);
  }

  @override
  Future<List<Bank>> getNgnBanks() async {
    final data = _data(await _client.get('$_api/transfers/ngn/banks'));
    if (data is! List) {
      throw const ApiException(
        message: 'The bank list response was not valid.',
      );
    }
    return data.map((bank) => Bank.fromJson(_requiredMap(bank))).toList();
  }

  @override
  Future<ResolvedBankAccount> resolveNgnAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/transfers/ngn/resolve-account',
        data: {'bankCode': bankCode, 'accountNumber': accountNumber},
      ),
    );
    return ResolvedBankAccount.fromJson(data);
  }

  @override
  Future<List<BankSuggestion>> suggestNgnBanks(String accountNumber) async {
    final data = _dataMap(
      await _client.post(
        '$_api/transfers/ngn/suggest-banks',
        data: {'accountNumber': accountNumber},
      ),
    );
    final suggestions = data['suggestions'];
    if (suggestions is! List) {
      throw const ApiException(message: 'The bank suggestions were not valid.');
    }
    return suggestions
        .map((item) => BankSuggestion.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<TransferQuote> quoteNgnTransfer({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String narration,
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/transfers/ngn/quote',
        data: {
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'amount': amount,
          'narration': narration,
        },
      ),
    );
    return TransferQuote.fromJson(data);
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
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/transfers/usd/quote',
        data: {
          'amount': amount,
          'recipientCountry': recipientCountry,
          'purpose': purpose,
          'paymentReference': paymentReference,
          'beneficiary': {
            'bankName': bankName,
            'accountNumber': accountNumber,
            'accountName': accountName,
            'swiftCode': swiftCode,
            if (routingNumber != null && routingNumber.isNotEmpty)
              'routingNumber': routingNumber,
          },
        },
      ),
    );
    return TransferQuote.fromJson(data);
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
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/transfers/cny/quote',
        data: {
          'amount': amount,
          'recipientCountry': recipientCountry,
          'purpose': purpose,
          'paymentReference': paymentReference,
          'beneficiary': {
            'bankName': bankName,
            'accountNumber': accountNumber,
            'accountName': accountName,
            'swiftCode': swiftCode,
          },
        },
      ),
    );
    return TransferQuote.fromJson(data);
  }

  @override
  Future<AppTransaction> confirmTransfer({
    required TransferQuote quote,
    String? passcode,
    String? biometricDeviceId,
    required String recipientName,
    String? recipientAccount,
    String? bankName,
    String? memo,
  }) async {
    final isForeign = quote.currency != TxCurrency.ngn;
    final currencyPath = quote.currency.name;
    final data = _dataMap(
      await _client.post(
        isForeign
            ? '$_api/transfers/$currencyPath/confirm'
            : '$_api/transfers/ngn/confirm',
        data: {
          'quoteId': quote.quoteId,
          if (passcode != null) 'passcode': passcode,
          if (biometricDeviceId != null) 'biometricDeviceId': biometricDeviceId,
          if (isForeign) 'purpose': 'supplier_payment',
          if (!isForeign) 'narration': memo ?? 'TF Transfer',
        },
        headers: {'Idempotency-Key': quote.quoteId},
      ),
    );
    return AppTransaction.fromJson({
      ...data,
      'id': data['transactionId'],
      'type': 'debit',
      'currency': data['currency'] ?? data['payoutCurrency'],
      'amount': data['amount'] ?? data['payoutAmount'],
      'ngnAmount': data['totalNgnDebit'] ?? data['amount'],
      'fee': data['fee'] ?? quote.fee,
      'totalDebit': data['totalDebit'] ?? data['totalNgnDebit'] ?? quote.total,
      'reference': data['reference'],
      'counterpartyName': recipientName,
      'counterpartyAccount': recipientAccount,
      'bankName': bankName,
      'memo': memo,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<AppTransaction>> listTransactions() async {
    final data = _dataMap(
      await _client.get(
        '$_api/transactions',
        queryParameters: {'page': 1, 'limit': 100},
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(
        message: 'The transactions response was not valid.',
      );
    }
    return items
        .map((item) => AppTransaction.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<AppTransaction?> getTransaction(String id) async {
    try {
      final data = _dataMap(await _client.get('$_api/transactions/$id'));
      return AppTransaction.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Beneficiary>> listBeneficiaries(String type) async {
    final data = _dataMap(
      await _client.get(
        '$_api/transfers/recent-beneficiaries',
        queryParameters: {'type': type},
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(message: 'The beneficiary list was not valid.');
    }
    return items
        .map((item) => Beneficiary.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<List<Beneficiary>> searchBeneficiaries({
    required String query,
    required String type,
  }) async {
    final data = _dataMap(
      await _client.get(
        '$_api/transfers/recent-beneficiaries/search',
        queryParameters: {'q': query, 'type': type},
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(
        message: 'The beneficiary search was not valid.',
      );
    }
    return items
        .map((item) => Beneficiary.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<void> deleteBeneficiary(String id) async {
    _data(await _client.delete('$_api/transfers/recent-beneficiaries/$id'));
  }

  @override
  Future<List<GiftCardProduct>> listGiftCards() async {
    final data = _data(await _client.get('$_api/gift-cards'));
    if (data is! List) {
      throw const ApiException(
        message: 'The gift card catalogue was not valid.',
      );
    }
    return data
        .map((item) => GiftCardProduct.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<GiftCardQuote> quoteGiftCard({
    required String giftCardId,
    required double amount,
    required String currency,
  }) async => GiftCardQuote.fromJson(
    _dataMap(
      await _client.post(
        '$_api/gift-cards/quote',
        data: {
          'giftCardId': giftCardId,
          'amount': amount,
          'currency': currency,
        },
      ),
    ),
  );

  @override
  Future<GiftCardPurchase> buyGiftCard({
    required String quoteId,
    required String passcode,
  }) async => GiftCardPurchase.fromJson(
    _dataMap(
      await _client.post(
        '$_api/gift-cards/create',
        data: {'quoteId': quoteId, 'passcode': passcode},
        headers: {'Idempotency-Key': quoteId},
      ),
    ),
  );

  @override
  Future<List<GiftCardPurchase>> listGiftCardPurchases({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final data = _dataMap(
      await _client.get(
        '$_api/gift-cards/purchases',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(
        message: 'The gift card purchase history was not valid.',
      );
    }
    return items
        .map((item) => GiftCardPurchase.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<GiftCardPurchase> getGiftCard(String id) async =>
      GiftCardPurchase.fromJson(
        _dataMap(await _client.get('$_api/gift-cards/purchases/$id')),
      );

  @override
  Future<List<AppNotification>> listNotifications() async {
    final data = _dataMap(
      await _client.get(
        '$_api/notifications',
        queryParameters: {'page': 1, 'limit': 50},
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(
        message: 'The notifications response was not valid.',
      );
    }
    return items
        .map((item) => AppNotification.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    _data(await _client.patch('$_api/notifications/$id/read'));
  }

  @override
  Future<void> markAllNotificationsRead() async {
    _data(await _client.patch('$_api/notifications/read-all'));
  }

  @override
  Future<void> registerDeviceToken({
    required String deviceId,
    required String fcmToken,
    required String platform,
  }) async {
    _data(
      await _client.post(
        '$_api/notifications/device-token/register',
        data: {
          'deviceId': deviceId,
          'fcmToken': fcmToken,
          'platform': platform,
        },
      ),
    );
  }

  @override
  Future<void> removeDeviceToken(String deviceId) async {
    _data(
      await _client.post(
        '$_api/notifications/device-token/remove',
        data: {'deviceId': deviceId},
      ),
    );
  }

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  }) async {
    final data = _dataMap(
      await _client.patch(
        '$_api/profile',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'dateOfBirth': dateOfBirth,
        },
      ),
    );
    return AppUser.fromJson({...data, 'id': data['id'] ?? 'current_user'});
  }

  @override
  Future<BiometricStatus> getBiometricStatus(String deviceId) async =>
      BiometricStatus.fromJson(
        _dataMap(
          await _client.get(
            '$_api/auth/biometric/status',
            queryParameters: {'deviceId': deviceId},
          ),
        ),
      );

  @override
  Future<BiometricStatus> enableBiometric({
    required String method,
    required String deviceId,
  }) async => BiometricStatus.fromJson(
    _dataMap(
      await _client.post(
        '$_api/auth/biometric/enable',
        data: {'method': method, 'deviceId': deviceId},
      ),
    ),
  );

  @override
  Future<void> disableBiometric(String deviceId) async {
    _data(
      await _client.post(
        '$_api/auth/biometric/disable',
        data: {'deviceId': deviceId},
      ),
    );
  }

  @override
  Future<AppUser> biometricLogin(String deviceId) =>
      _authenticate('$_api/auth/biometric/login', {'deviceId': deviceId});

  @override
  Future<CashDropConfig> getCashDropConfig() async => CashDropConfig.fromJson(
    _dataMap(await _client.get('$_api/cash-drop/config')),
  );

  @override
  Future<CashDropStatus> getCashDropStatus() async => CashDropStatus.fromJson(
    _dataMap(await _client.get('$_api/cash-drop/status')),
  );

  @override
  Future<CashDropStatus> registerCashDrop() async => CashDropStatus.fromJson(
    _dataMap(
      await _client.post(
        '$_api/cash-drop/register',
        data: {'useCurrentProfileImage': true},
      ),
    ),
  );

  @override
  Future<CashDropStatus> disableCashDrop(String reason) async =>
      CashDropStatus.fromJson(
        _dataMap(
          await _client.post(
            '$_api/cash-drop/disable',
            data: {'reason': reason},
          ),
        ),
      );

  @override
  Future<CashDropMatch> resolveCashDrop(String scannedImageBase64) async =>
      CashDropMatch.fromJson(
        _dataMap(
          await _client.post(
            '$_api/cash-drop/resolve',
            data: {'scannedImageBase64': scannedImageBase64},
          ),
        ),
      );

  @override
  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
    String? transactionId,
    String? category,
    List<String> attachmentUrls = const [],
  }) async {
    final data = _dataMap(
      await _client.post(
        '$_api/support/tickets',
        data: {
          'subject': subject,
          'message': message,
          if (transactionId != null && transactionId.isNotEmpty)
            'transactionId': transactionId,
          if (category != null && category.isNotEmpty) 'category': category,
          if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
        },
      ),
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() async {
    final data = _dataMap(await _client.get('$_api/support/tickets'));
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(
        message: 'The support ticket list was not valid.',
      );
    }
    return items
        .map((item) => SupportTicket.fromJson(_requiredMap(item)))
        .toList();
  }

  @override
  Future<SupportTicket> getSupportTicket(String id) async =>
      SupportTicket.fromJson(
        _dataMap(await _client.get('$_api/support/tickets/$id')),
      );

  @override
  Future<void> replySupportTicket({
    required String id,
    required String message,
    List<String> attachmentUrls = const [],
  }) async {
    _data(
      await _client.post(
        '$_api/support/tickets/$id/reply',
        data: {
          'message': message,
          if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
        },
      ),
    );
  }

  @override
  Future<void> closeSupportTicket(String id) async {
    _data(await _client.post('$_api/support/tickets/$id/close'));
  }

  @override
  Future<SupportAttachment> uploadSupportAttachment({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return SupportAttachment.fromJson(
      _dataMap(
        await _client.post('$_api/uploads/support-attachment', data: form),
      ),
    );
  }
}

Object? _data(Object? response) {
  final root = _requiredMap(response);
  if (root['success'] == false) {
    final error = root['error'];
    throw ApiException(
      message: root['message']?.toString() ?? 'The request failed.',
      code: error is Map ? error['code']?.toString() : null,
      details: error,
    );
  }
  return root['data'];
}

Map<String, dynamic> _dataMap(Object? response) =>
    _requiredMap(_data(response));

Map<String, dynamic> _requiredMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const ApiException(message: 'The server response was not valid.');
}
