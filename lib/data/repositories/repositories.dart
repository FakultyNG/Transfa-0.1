import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/device_identity.dart';
import '../api/rest_transfa_api.dart';
import '../api/session_store.dart';
import '../api/transfa_api.dart';
import '../mock_api/mock_api.dart';
import '../models/auth.dart';
import '../models/bank.dart';
import '../models/device_features.dart';
import '../models/gift_card.dart';
import '../models/notification.dart';
import '../models/support.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/wallet.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  final config = AppConfig.fromEnvironment();
  config.validate();
  return config;
});

final sessionStoreProvider = Provider<SessionStore>(
  (_) => SecureSessionStore(),
);

final transfaApiProvider = Provider<TransfaApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) return MockApi.instance;

  final sessionStore = ref.watch(sessionStoreProvider);
  return RestTransfaApi(
    client: ApiClient(baseUrl: config.apiBaseUrl, sessionStore: sessionStore),
    sessionStore: sessionStore,
  );
});

class AuthRepository {
  AuthRepository(this._api);
  final TransfaApi _api;

  Future<RegistrationStart> startRegistration(String phoneNumber) =>
      _api.startRegistration(phoneNumber);

  Future<OtpChallenge> sendOtp(String phoneNumber) => _api.sendOtp(phoneNumber);

  Future<OtpChallenge> resendOtp({
    required String phoneNumber,
    required String otpReference,
  }) async {
    try {
      return await _api.resendOtp(
        phoneNumber: phoneNumber,
        otpReference: otpReference,
      );
    } on ApiException catch (error) {
      if (error.code != 'OTP_EXPIRED') rethrow;
      return _api.sendOtp(phoneNumber);
    }
  }

  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) => _api.validateOtp(
    phoneNumber: phoneNumber,
    otp: otp,
    otpReference: otpReference,
  );

  Future<AppUser> completeRegistration({
    required String registrationToken,
    required String passcode,
  }) => _api.completeRegistration(
    registrationToken: registrationToken,
    passcode: passcode,
  );

  Future<AppUser> login(String phoneNumber, String passcode) =>
      _api.login(phoneNumber: phoneNumber, passcode: passcode);

  Future<void> logout() => _api.logout();
  Future<AppUser> getProfile() => _api.getProfile();
  Future<void> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) => _api.changePasscode(oldPasscode: oldPasscode, newPasscode: newPasscode);
  Future<void> verifyActivePasscode(String passcode) =>
      _api.verifyActivePasscode(passcode);
  Future<FaceUnlockConfig> getFaceUnlockConfig() => _api.getFaceUnlockConfig();
  Future<AppUser> faceUnlock({
    required String phoneNumber,
    required String faceImageBase64,
  }) => _api.faceUnlock(
    phoneNumber: phoneNumber,
    faceImageBase64: faceImageBase64,
  );

  Future<OtpChallenge> requestPasscodeReset(String phoneNumber) =>
      _api.requestPasscodeReset(phoneNumber);
  Future<String> verifyPasscodeReset({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  }) => _api.verifyPasscodeReset(
    phoneNumber: phoneNumber,
    otp: otp,
    otpReference: otpReference,
  );
  Future<void> completePasscodeReset({
    required String resetToken,
    required String newPasscode,
  }) => _api.completePasscodeReset(
    resetToken: resetToken,
    newPasscode: newPasscode,
  );

  Future<AppUser?> restoreSession() async {
    try {
      return await _api.getProfile();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) return null;
      rethrow;
    }
  }

  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  }) => _api.updateProfile(
    firstName: firstName,
    lastName: lastName,
    email: email,
    dateOfBirth: dateOfBirth,
  );

  Future<BvnVerification> verifyBvn({
    required String registrationToken,
    required String bvn,
  }) => _api.verifyBvn(registrationToken: registrationToken, bvn: bvn);

  Future<SelfieVerification> validateBvnSelfie({
    required String registrationToken,
    required String kycReference,
    required String selfieImageBase64,
  }) => _api.validateBvnSelfie(
    registrationToken: registrationToken,
    kycReference: kycReference,
    selfieImageBase64: selfieImageBase64,
  );
  Future<LivenessSession> startBvnLiveness({
    required String registrationToken,
    required String kycReference,
  }) => _api.startBvnLiveness(
    registrationToken: registrationToken,
    kycReference: kycReference,
  );
  Future<LivenessStatus> getBvnLivenessStatus({
    required String registrationToken,
    required String kycReference,
    required String livenessSessionId,
  }) => _api.getBvnLivenessStatus(
    registrationToken: registrationToken,
    kycReference: kycReference,
    livenessSessionId: livenessSessionId,
  );
  Future<SelfieVerification> completeBvnLiveness({
    required String registrationToken,
    required String kycReference,
    required String livenessSessionId,
    required String profileImageBase64,
  }) => _api.completeBvnLiveness(
    registrationToken: registrationToken,
    kycReference: kycReference,
    livenessSessionId: livenessSessionId,
    profileImageBase64: profileImageBase64,
  );
  Future<Map<String, dynamic>> getKycStatus() => _api.getKycStatus();
}

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(transfaApiProvider)),
);
final currentUserProvider = StateProvider<AppUser?>((_) => null);
final registrationSessionProvider = StateProvider<RegistrationSession?>(
  (_) => null,
);
final profileProvider = FutureProvider<AppUser>(
  (ref) => ref.watch(authRepositoryProvider).getProfile(),
);
final kycStatusProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(authRepositoryProvider).getKycStatus(),
);
final sessionRestorationProvider = FutureProvider<AppUser?>((ref) async {
  final token = await ref.watch(sessionStoreProvider).readAccessToken();
  final refreshToken = await ref.watch(sessionStoreProvider).readRefreshToken();
  if ((token == null || token.isEmpty) &&
      (refreshToken == null || refreshToken.isEmpty)) {
    return null;
  }
  return ref.watch(authRepositoryProvider).restoreSession();
});

class WalletRepository {
  WalletRepository(this._api);
  final TransfaApi _api;

  Future<Wallet> get() => _api.getWallet();
  Future<WalletSummary> summary() => _api.getWalletSummary();
  Future<AppTransaction> verifyFunding(String reference) =>
      _api.verifyFunding(reference);
  Future<DedicatedVirtualAccount> createDva() => _api.createDva();
  Future<DedicatedVirtualAccount> dva() async {
    try {
      return await _api.getDva();
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.code == 'DVA_NOT_FOUND') {
        return _api.createDva();
      }
      rethrow;
    }
  }
}

final walletRepositoryProvider = Provider(
  (ref) => WalletRepository(ref.watch(transfaApiProvider)),
);
final walletProvider = FutureProvider<Wallet>(
  (ref) => ref.watch(walletRepositoryProvider).get(),
);
final dvaProvider = FutureProvider<DedicatedVirtualAccount>(
  (ref) => ref.watch(walletRepositoryProvider).dva(),
);
final walletSummaryProvider = FutureProvider<WalletSummary>(
  (ref) => ref.watch(walletRepositoryProvider).summary(),
);

class TransferRepository {
  TransferRepository(this._api);
  final TransfaApi _api;

  Future<List<Bank>> banks() => _api.getNgnBanks();

  Future<ResolvedBankAccount> resolveAccount({
    required String bankCode,
    required String accountNumber,
  }) =>
      _api.resolveNgnAccount(bankCode: bankCode, accountNumber: accountNumber);

  Future<List<BankSuggestion>> suggestBanks(String accountNumber) =>
      _api.suggestNgnBanks(accountNumber);

  Future<TransferQuote> quoteNgn({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String narration,
  }) => _api.quoteNgnTransfer(
    amount: amount,
    bankCode: bankCode,
    accountNumber: accountNumber,
    narration: narration,
  );

  Future<TransferQuote> quoteUsd({
    required double amount,
    required String recipientCountry,
    required String paymentReference,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String swiftCode,
    String? routingNumber,
  }) => _api.quoteUsdTransfer(
    amount: amount,
    recipientCountry: recipientCountry,
    purpose: 'supplier_payment',
    paymentReference: paymentReference,
    bankName: bankName,
    accountNumber: accountNumber,
    accountName: accountName,
    swiftCode: swiftCode,
    routingNumber: routingNumber,
  );

  Future<TransferQuote> quoteCny({
    required double amount,
    required String recipientCountry,
    required String paymentReference,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String swiftCode,
  }) => _api.quoteCnyTransfer(
    amount: amount,
    recipientCountry: recipientCountry,
    purpose: 'supplier_payment',
    paymentReference: paymentReference,
    bankName: bankName,
    accountNumber: accountNumber,
    accountName: accountName,
    swiftCode: swiftCode,
  );

  Future<List<Beneficiary>> beneficiaries(String type) =>
      _api.listBeneficiaries(type);
  Future<List<Beneficiary>> searchBeneficiaries({
    required String query,
    required String type,
  }) => _api.searchBeneficiaries(query: query, type: type);
  Future<void> deleteBeneficiary(String id) => _api.deleteBeneficiary(id);

  Future<AppTransaction> confirm({
    required TransferQuote quote,
    String? passcode,
    String? biometricDeviceId,
    required String recipientName,
    String? recipientAccount,
    String? bankName,
    String? memo,
  }) => _api.confirmTransfer(
    quote: quote,
    passcode: passcode,
    biometricDeviceId: biometricDeviceId,
    recipientName: recipientName,
    recipientAccount: recipientAccount,
    bankName: bankName,
    memo: memo,
  );
}

final transferRepositoryProvider = Provider(
  (ref) => TransferRepository(ref.watch(transfaApiProvider)),
);
final ngnBanksProvider = FutureProvider<List<Bank>>(
  (ref) => ref.watch(transferRepositoryProvider).banks(),
);
final recentBeneficiariesProvider =
    FutureProvider.family<List<Beneficiary>, String>(
      (ref, type) => ref.watch(transferRepositoryProvider).beneficiaries(type),
    );

class GiftCardRepository {
  GiftCardRepository(this._api);
  final TransfaApi _api;

  Future<List<GiftCardProduct>> list() => _api.listGiftCards();
  Future<GiftCardQuote> quote({
    required GiftCardProduct product,
    required double amount,
  }) => _api.quoteGiftCard(
    giftCardId: product.id,
    amount: amount,
    currency: product.currency,
  );
  Future<GiftCardPurchase> buy({
    required GiftCardQuote quote,
    required String passcode,
  }) => _api.buyGiftCard(quoteId: quote.quoteId, passcode: passcode);
  Future<List<GiftCardPurchase>> purchases({
    int page = 1,
    int limit = 20,
    String? status,
  }) => _api.listGiftCardPurchases(page: page, limit: limit, status: status);
  Future<GiftCardPurchase> get(String id) => _api.getGiftCard(id);
}

final giftCardRepositoryProvider = Provider(
  (ref) => GiftCardRepository(ref.watch(transfaApiProvider)),
);
final giftCardsProvider = FutureProvider<List<GiftCardProduct>>(
  (ref) => ref.watch(giftCardRepositoryProvider).list(),
);
final giftCardPurchasesProvider = FutureProvider<List<GiftCardPurchase>>(
  (ref) => ref.watch(giftCardRepositoryProvider).purchases(),
);
final giftCardPurchaseProvider =
    FutureProvider.family<GiftCardPurchase, String>(
      (ref, id) => ref.watch(giftCardRepositoryProvider).get(id),
    );

class TransactionRepository {
  TransactionRepository(this._api);
  final TransfaApi _api;

  Future<List<AppTransaction>> list() => _api.listTransactions();
  Future<AppTransaction?> get(String id) => _api.getTransaction(id);
}

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(ref.watch(transfaApiProvider)),
);
final transactionsProvider = FutureProvider<List<AppTransaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).list(),
);

class NotificationRepository {
  NotificationRepository(this._api);
  final TransfaApi _api;

  Future<List<AppNotification>> list() => _api.listNotifications();
  Future<void> markRead(String id) => _api.markNotificationRead(id);
  Future<void> markAllRead() => _api.markAllNotificationsRead();
  Future<void> registerDeviceToken({
    required String deviceId,
    required String fcmToken,
    required String platform,
  }) => _api.registerDeviceToken(
    deviceId: deviceId,
    fcmToken: fcmToken,
    platform: platform,
  );
  Future<void> removeDeviceToken(String deviceId) =>
      _api.removeDeviceToken(deviceId);
}

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(ref.watch(transfaApiProvider)),
);
final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).list(),
);

class SupportRepository {
  SupportRepository(this._api);
  final TransfaApi _api;

  Future<SupportTicket> create({
    required String subject,
    required String message,
    String? transactionId,
    String? category,
    List<String> attachmentUrls = const [],
  }) => _api.createSupportTicket(
    subject: subject,
    message: message,
    transactionId: transactionId,
    category: category,
    attachmentUrls: attachmentUrls,
  );

  Future<List<SupportTicket>> list() => _api.listSupportTickets();
  Future<SupportTicket> get(String id) => _api.getSupportTicket(id);
  Future<void> reply({
    required String id,
    required String message,
    List<String> attachmentUrls = const [],
  }) => _api.replySupportTicket(
    id: id,
    message: message,
    attachmentUrls: attachmentUrls,
  );
  Future<void> close(String id) => _api.closeSupportTicket(id);
  Future<SupportAttachment> upload({
    required Uint8List bytes,
    required String fileName,
  }) => _api.uploadSupportAttachment(bytes: bytes, fileName: fileName);
}

final supportRepositoryProvider = Provider(
  (ref) => SupportRepository(ref.watch(transfaApiProvider)),
);
final supportTicketsProvider = FutureProvider<List<SupportTicket>>(
  (ref) => ref.watch(supportRepositoryProvider).list(),
);
final supportTicketProvider = FutureProvider.family<SupportTicket, String>(
  (ref, id) => ref.watch(supportRepositoryProvider).get(id),
);

class DeviceFeaturesRepository {
  DeviceFeaturesRepository(this._api);
  final TransfaApi _api;

  Future<BiometricStatus> biometricStatus() async =>
      _api.getBiometricStatus(await DeviceIdentity().getOrCreate());
  Future<BiometricStatus> enableBiometric({
    required String method,
    required String deviceId,
  }) => _api.enableBiometric(method: method, deviceId: deviceId);
  Future<void> disableBiometric(String deviceId) =>
      _api.disableBiometric(deviceId);
  Future<AppUser> biometricLogin(String deviceId) =>
      _api.biometricLogin(deviceId);
  Future<CashDropConfig> cashDropConfig() => _api.getCashDropConfig();
  Future<CashDropStatus> cashDropStatus() => _api.getCashDropStatus();
  Future<CashDropStatus> registerCashDrop() => _api.registerCashDrop();
  Future<CashDropStatus> disableCashDrop() =>
      _api.disableCashDrop('User disabled CashDrop');
  Future<CashDropMatch> resolveCashDrop(String image) =>
      _api.resolveCashDrop(image);
}

final deviceFeaturesRepositoryProvider = Provider(
  (ref) => DeviceFeaturesRepository(ref.watch(transfaApiProvider)),
);
final biometricStatusProvider = FutureProvider<BiometricStatus>(
  (ref) => ref.watch(deviceFeaturesRepositoryProvider).biometricStatus(),
);
final cashDropStatusProvider = FutureProvider<CashDropStatus>(
  (ref) => ref.watch(deviceFeaturesRepositoryProvider).cashDropStatus(),
);
final cashDropConfigProvider = FutureProvider<CashDropConfig>(
  (ref) => ref.watch(deviceFeaturesRepositoryProvider).cashDropConfig(),
);
