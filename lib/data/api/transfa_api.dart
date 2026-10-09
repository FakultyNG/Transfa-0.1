import 'dart:typed_data';

import '../models/auth.dart';
import '../models/bank.dart';
import '../models/device_features.dart';
import '../models/gift_card.dart';
import '../models/notification.dart';
import '../models/support.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/wallet.dart';

abstract interface class TransfaApi {
  Future<RegistrationStart> startRegistration(String phoneNumber);
  Future<OtpChallenge> sendOtp(String phoneNumber);
  Future<OtpChallenge> resendOtp({
    required String phoneNumber,
    required String otpReference,
  });
  Future<bool> validateOtp({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  });
  Future<AppUser> completeRegistration({
    required String registrationToken,
    required String passcode,
  });
  Future<AppUser> login({
    required String phoneNumber,
    required String passcode,
  });
  Future<void> logout();
  Future<AppUser> getProfile();
  Future<void> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  });
  Future<OtpChallenge> requestPasscodeReset(String phoneNumber);
  Future<String> verifyPasscodeReset({
    required String phoneNumber,
    required String otp,
    required String otpReference,
  });
  Future<void> completePasscodeReset({
    required String resetToken,
    required String newPasscode,
  });

  Future<BvnVerification> verifyBvn({
    required String registrationToken,
    required String bvn,
  });
  Future<bool> validateBvnSelfie({
    required String registrationToken,
    required String kycReference,
    required String selfieImageBase64,
  });
  Future<Map<String, dynamic>> getKycStatus();

  Future<Wallet> getWallet();
  Future<WalletSummary> getWalletSummary();
  Future<AppTransaction> verifyFunding(String reference);
  Future<DedicatedVirtualAccount> getDva();
  Future<DedicatedVirtualAccount> createDva();

  Future<List<Bank>> getNgnBanks();
  Future<ResolvedBankAccount> resolveNgnAccount({
    required String bankCode,
    required String accountNumber,
  });
  Future<List<BankSuggestion>> suggestNgnBanks(String accountNumber);
  Future<TransferQuote> quoteNgnTransfer({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String narration,
  });
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
  });
  Future<TransferQuote> quoteCnyTransfer({
    required double amount,
    required String recipientCountry,
    required String purpose,
    required String paymentReference,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String swiftCode,
  });
  Future<AppTransaction> confirmTransfer({
    required TransferQuote quote,
    required String passcode,
    required String recipientName,
    String? recipientAccount,
    String? bankName,
    String? memo,
  });

  Future<List<AppTransaction>> listTransactions();
  Future<AppTransaction?> getTransaction(String id);

  Future<List<Beneficiary>> listBeneficiaries(String type);
  Future<List<Beneficiary>> searchBeneficiaries({
    required String query,
    required String type,
  });
  Future<void> deleteBeneficiary(String id);

  Future<List<GiftCardProduct>> listGiftCards();
  Future<GiftCardQuote> quoteGiftCard({
    required String giftCardId,
    required double amount,
    required String currency,
  });
  Future<GiftCardPurchase> buyGiftCard({
    required String quoteId,
    required String passcode,
  });
  Future<List<GiftCardPurchase>> listGiftCardPurchases({
    int page = 1,
    int limit = 20,
    String? status,
  });
  Future<GiftCardPurchase> getGiftCard(String id);

  Future<List<AppNotification>> listNotifications();
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<void> registerDeviceToken({
    required String deviceId,
    required String fcmToken,
    required String platform,
  });
  Future<void> removeDeviceToken(String deviceId);

  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  });

  Future<BiometricStatus> getBiometricStatus();
  Future<BiometricStatus> enableBiometric({
    required String method,
    required String deviceId,
  });
  Future<void> disableBiometric(String deviceId);
  Future<AppUser> biometricLogin(String deviceId);

  Future<CashDropStatus> getCashDropStatus();
  Future<CashDropStatus> registerCashDrop();
  Future<CashDropStatus> disableCashDrop(String reason);
  Future<CashDropMatch> resolveCashDrop(String scannedImageBase64);

  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
    String? transactionId,
    String? category,
    List<String> attachmentUrls = const [],
  });
  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> getSupportTicket(String id);
  Future<void> replySupportTicket({
    required String id,
    required String message,
    List<String> attachmentUrls = const [],
  });
  Future<void> closeSupportTicket(String id);
  Future<SupportAttachment> uploadSupportAttachment({
    required Uint8List bytes,
    required String fileName,
  });
}
