import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/transaction.dart';

import '../../features/auth/presentation/create_pin_screen.dart';
import '../../features/auth/presentation/identity_verification_screen.dart';
import '../../features/auth/presentation/location_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/passcode_reset_screen.dart';
import '../../features/auth/presentation/photo_id_guide_screen.dart';
import '../../features/auth/presentation/photo_id_screen.dart';
import '../../features/auth/presentation/privacy_info_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/unsupported_id_screen.dart';
import '../../features/auth/presentation/id_collect_screen.dart';
import '../../features/auth/presentation/verify_bvn_screen.dart';
import '../../features/auth/presentation/verify_nin_screen.dart';
import '../../features/auth/presentation/verify_startkey_screen.dart';
import '../../features/auth/presentation/welcome_intro_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/dashboard/presentation/add_money_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/dev_menu_screen.dart';
import '../../features/dashboard/presentation/share_account_screen.dart';
import '../../features/gift_cards/presentation/gift_cards_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/change_password_screen.dart';
import '../../features/settings/presentation/legal_screen.dart';
import '../../features/settings/presentation/limits_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/privacy_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/profile_edit_screen.dart';
import '../../features/settings/presentation/security_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/register_phone_screen.dart';
import '../../features/auth/presentation/unlock_screens.dart';
import '../../features/support/presentation/memo_chat_screen.dart';
import '../../features/support/presentation/support_chat_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/wallet/presentation/wallet_widget_screen.dart';
import '../../features/wallet/presentation/wallet_overview_screen.dart';
import '../../features/transactions/presentation/transaction_details_screen.dart';
import '../../features/transactions/presentation/transaction_history_screen.dart';
import '../../features/transfers/presentation/amount_keypad_screen.dart';
import '../../features/transfers/presentation/beneficiaries_screen.dart';
import '../../features/transfers/presentation/amount_currency_sheet.dart';
import '../../features/transfers/presentation/info_modals.dart';
import '../../features/transfers/presentation/status_screens.dart';
import '../../features/pop-ups/cashdrop_popup.dart';
import '../../features/transfers/presentation/choose_bank_screen.dart';
import '../../features/transfers/presentation/receipt_screens.dart';
import '../../features/transfers/presentation/recipient_picker_screen.dart';
import '../../features/transfers/presentation/recipient_screens.dart';
import '../../features/transfers/presentation/send_form_screen.dart';
import '../../features/transfers/presentation/transfa_ai_screen.dart';
import '../../features/transfers/presentation/transfer_confirm_screen.dart';
import '../../features/transfers/presentation/transfer_details_screen.dart';
import '../../features/transfers/presentation/transfer_screen.dart';
import '../../features/transfers/presentation/choose_country_screen.dart';
import 'routes.dart';

// Custom slide-up transition builder
CustomTransitionPage buildPageWithTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0, 1); // Start from bottom
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 800),
  );
}

// Helper function to create routes with transition
GoRoute slideRoute(String path, Widget page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildPageWithTransition(page),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      // Boot / pre-auth
      slideRoute(Routes.splash, const SplashScreen()),
      slideRoute(Routes.devMenu, const DevMenuScreen()),
      slideRoute(Routes.welcomeIntro, const WelcomeIntroScreen()),
      slideRoute(Routes.onboarding, const OnboardingScreen()),

      // Identity / KYC
      slideRoute(
        Routes.identityVerification,
        const IdentityVerificationScreen(),
      ),
      slideRoute(Routes.identityPrivacy, const PrivacyIdScreen()),
      slideRoute(Routes.identityBankPrivacy, const PrivacyBankScreen()),
      slideRoute(Routes.photoId, const PhotoIdScreen()),
      slideRoute(Routes.photoIdGuide, const PhotoIdGuideScreen()),
      GoRoute(
        path: Routes.verifyNin,
        pageBuilder: (context, state) => buildPageWithTransition(
          state.extra is NinOtpArgs
              ? VerifyNinScreen(args: state.extra as NinOtpArgs)
              : const AddNinScreen(),
        ),
      ),
      slideRoute(Routes.addBvn, const AddBvnScreen()),
      slideRoute(Routes.addNin, const AddNinScreen()),
      slideRoute(Routes.verifyBvn, const VerifyBvnScreen()),
      slideRoute(Routes.unsupportedId, const UnsupportedIdScreen()),
      slideRoute(Routes.location, const LocationScreen()),

      // Auth
      slideRoute(Routes.register, const RegisterPhoneScreen()),
      slideRoute(Routes.login, const LoginScreen()),
      slideRoute(Routes.verifyStartkey, const VerifyStartkeyScreen()),
      GoRoute(
        path: Routes.createPin,
        pageBuilder: (context, state) => buildPageWithTransition(
          CreatePinScreen(
            recovery: state.extra is CreatePinRecoveryArgs
                ? state.extra as CreatePinRecoveryArgs
                : null,
          ),
        ),
      ),
      slideRoute(Routes.welcome, const WelcomeScreen()),

      //pop-ups
      slideRoute(Routes.cashDrop, const CashDropScreen()),

      // Main
      slideRoute(Routes.dashboard, const DashboardScreen()),
      slideRoute(Routes.notifications, const NotificationsScreen()),
      slideRoute(Routes.addMoney, const AddMoneyScreen()),
      slideRoute(Routes.shareAccount, const ShareAccountScreen()),
      slideRoute(Routes.support, const SupportScreen()),
      GoRoute(
        path: Routes.supportChat,
        pageBuilder: (context, state) => buildPageWithTransition(
          SupportChatScreen(initialMessage: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.supportTicket,
        pageBuilder: (context, state) =>
            buildPageWithTransition(const SupportChatScreen()),
      ),
      slideRoute(Routes.walletWidget, const WalletWidgetScreen()),
      slideRoute(Routes.walletOverview, const WalletOverviewScreen()),
      slideRoute(Routes.giftCards, const GiftCardsScreen()),
      slideRoute(Routes.transactions, const TransactionHistoryScreen()),

      GoRoute(
        path: Routes.transactionDetails,
        pageBuilder: (context, state) => buildPageWithTransition(
          TransactionDetailsScreen(id: state.pathParameters['id']!),
        ),
      ),

      slideRoute(Routes.transfer, const TransferScreen()),
      slideRoute(Routes.transferDetails, const TransferDetailsScreen()),
      slideRoute(Routes.transferConfirm, const TransferConfirmScreen()),
      slideRoute(Routes.beneficiaries, const BeneficiariesScreen()),

      // New transfer flow (Transfa AI)
      slideRoute(Routes.transfaAi, const TransfaAiScreen()),
      slideRoute(Routes.amount, const AmountKeypadScreen()),
      slideRoute(Routes.sendForm, const SendFormScreen()),
      GoRoute(
        path: Routes.recipientPick,
        pageBuilder: (context, state) => buildPageWithTransition(
          RecipientPickerScreen(args: state.extra as RecipientPickerArgs?),
        ),
      ),
      slideRoute(Routes.recipientProfile, const RecipientProfileScreen()),
      slideRoute(Routes.recipientMultiBank, const RecipientMultiBankScreen()),
      slideRoute(
        Routes.recipientAmountPreview,
        const RecipientAmountPreviewScreen(),
      ),
      GoRoute(
        path: Routes.chooseBank,
        pageBuilder: (context, state) => buildPageWithTransition(
          ChooseBankScreen(
            args: state.extra is ChooseBankArgs
                ? state.extra as ChooseBankArgs
                : const ChooseBankArgs(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.receiptUniversal,
        pageBuilder: (context, state) => buildPageWithTransition(
          ReceiptUniversalScreen(
            args: state.extra is ReceiptUniversalArgs
                ? state.extra as ReceiptUniversalArgs
                : null,
          ),
        ),
      ),
      slideRoute(Routes.receiptStatus, const ReceiptStatusScreen()),
      slideRoute(Routes.receiptUnable, const ReceiptUnableScreen()),
      slideRoute(Routes.receiptReceived, const ReceiptReceivedScreen()),
      GoRoute(
        path: Routes.receiptInReview,
        pageBuilder: (context, state) => buildPageWithTransition(
          ReceiptInReviewScreen(
            transaction: state.extra is AppTransaction
                ? state.extra as AppTransaction
                : null,
          ),
        ),
      ),
      slideRoute(
        Routes.receiptReceivedCompany,
        const ReceiptReceivedCompanyScreen(),
      ),
      slideRoute(
        Routes.receiptUniversalReceived,
        const ReceiptUniversalReceivedScreen(),
      ),
      slideRoute(
        Routes.receiptUniversalProcessing,
        const ReceiptUniversalProcessingScreen(),
      ),
      slideRoute(Routes.chooseCountry, const SendMoneyWherePage()),

      // Unlock + recovery
      GoRoute(
        path: Routes.faceShotUnlock,
        pageBuilder: (context, state) => buildPageWithTransition(
          FaceShotUnlockScreen(phoneNumber: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.welcomeHomePhone,
        pageBuilder: (context, state) => buildPageWithTransition(
          WelcomeHomePhoneScreen(initialPhone: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.unlockPasscode,
        pageBuilder: (context, state) => buildPageWithTransition(
          UnlockPasscodeScreen(phoneNumber: state.extra as String?),
        ),
      ),
      slideRoute(Routes.payPasscode, const PayPasscodeScreen()),
      slideRoute(Routes.securityLockout, const SecurityLockoutScreen()),
      slideRoute(Routes.forgotPasscode, const PasscodeResetScreen()),
      GoRoute(
        path: Routes.recoveryStartkey,
        pageBuilder: (context, state) => buildPageWithTransition(
          state.extra is RecoveryStartkeyArgs
              ? RecoveryStartkeyScreen(
                  args: state.extra as RecoveryStartkeyArgs,
                )
              : const ForgotPasscodeScreen(),
        ),
      ),

      // Memo support chat
      slideRoute(Routes.memoChat, const MemoChatScreen()),

      // Info / status / currency modals
      slideRoute(Routes.bankUnavailable, const BankUnavailableScreen()),
      slideRoute(Routes.noInternet, const NoInternetScreen()),
      slideRoute(Routes.insufficientMoney, const InsufficientMoneyScreen()),
      slideRoute(Routes.stampDuty, const StampDutyScreen()),
      slideRoute(Routes.faceNotRecognized, const FaceNotRecognizedScreen()),
      slideRoute(Routes.getPower, const GetPowerScreen()),
      slideRoute(Routes.statusUnable, const StatusUnableScreen()),
      slideRoute(Routes.statusProcessing, const StatusProcessingScreen()),
      slideRoute(Routes.statusSent, const StatusSentScreen()),
      slideRoute(Routes.amountCurrency, const AmountCurrencyScreen()),

      // Settings
      slideRoute(Routes.settings, const SettingsScreen()),
      slideRoute(Routes.profile, const ProfileScreen()),
      slideRoute(Routes.profileEdit, const ProfileEditScreen()),
      slideRoute(Routes.privacy, const PrivacyScreen()),
      slideRoute(Routes.security, const SecurityScreen()),
      slideRoute(Routes.limits, const LimitsScreen()),
      slideRoute(Routes.privacyPolicy, const PrivacyPolicyScreen()),
      slideRoute(Routes.legal, const LegalScreen()),
      slideRoute(Routes.changePassword, const ChangePasswordScreen()),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('No route: ${state.uri}'))),
  );
});
