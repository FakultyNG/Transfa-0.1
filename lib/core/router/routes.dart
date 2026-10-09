/// Named route paths. Centralised so navigation calls don't sprinkle
/// magic strings across the codebase.
class Routes {
  Routes._();

  // Boot / pre-auth
  static const splash = '/';
  static const welcomeIntro = '/welcome-intro';
  static const onboarding = '/onboarding';
  static const devMenu = '/dev';

  // Identity / KYC
  static const identityVerification = '/identity';
  static const identityPrivacy = '/identity/privacy';
  static const identityBankPrivacy = '/identity/bank-privacy';
  static const photoId = '/identity/photo-id';
  static const verifyNin = '/identity/verify-nin';
  static const addBvn = '/identity/add-bvn';
  static const addNin = '/identity/add-nin';
  static const verifyBvn = '/identity/verify-bvn';
  static const unsupportedId = '/identity/unsupported';
  static const photoIdGuide = '/identity/photo-id-guide';
  static const location = '/identity/location';

  // Auth
  static const register = '/register';
  static const login = '/login';
  static const verifyStartkey = '/verify-startkey';
  static const createPin = '/create-pin';
  static const welcome = '/welcome';

  // Unlock & recovery
  static const faceShotUnlock = '/unlock/face';
  static const welcomeHomePhone = '/unlock/phone';
  static const unlockPasscode = '/unlock/passcode';
  static const payPasscode = '/unlock/pay';
  static const securityLockout = '/unlock/lockout';
  static const forgotPasscode = '/unlock/forgot';
  static const recoveryStartkey = '/unlock/recovery-startkey';

  // Memo / chat
  static const memoChat = '/support/memo';

  // Info / status modals
  static const bankUnavailable = '/modal/bank-unavailable';
  static const noInternet = '/modal/no-internet';
  static const insufficientMoney = '/modal/insufficient-money';
  static const stampDuty = '/modal/stamp-duty';
  static const faceNotRecognized = '/modal/face-not-recognized';
  static const getPower = '/modal/get-power';
  static const statusUnable = '/modal/status-unable';
  static const statusProcessing = '/modal/status-processing';
  static const statusSent = '/modal/status-sent';
  static const amountCurrency = '/modal/amount-currency';

  // Main
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  // static const wallet = '/wallet';
  static const addMoney = '/add-money';
  static const shareAccount = '/share-account';
  static const cashDrop = '/cashdrop';
  static const cashDropSend = '/cashdrop/send';
  static const cashDropReceive = '/cashdrop/receive';
  static const cashDropScan = '/cashdrop/scan';
  static const support = '/support';
  static const supportChat = '/support/chat';
  static const supportTicket = '/support/tickets/:id';
  static const walletWidget = '/wallet/widget';
  static const walletOverview = '/wallet/overview';
  static const giftCards = '/gift-cards';
  static const transactions = '/transactions';
  static const transactionDetails = '/transactions/:id';

  static const transfer = '/transfer';
  static const transferDetails = '/transfer/details';
  static const transferConfirm = '/transfer/confirm';
  static const beneficiaries = '/transfer/beneficiaries';

  // New transfer flow (Transfa AI / Pay)
  static const transfaAi = '/transfa-ai';
  static const amount = '/transfer/amount';
  static const sendForm = '/transfer/send';
  static const recipientPick = '/transfer/recipient';
  static const recipientProfile = '/transfer/recipient/profile';
  static const recipientMultiBank = '/transfer/recipient/multi-bank';
  static const recipientAmountPreview = '/transfer/recipient/preview';
  static const chooseBank = '/transfer/choose-bank';
  static const chooseCountry = '/transfer/choose-country';
  static const receiptUniversal = '/transfer/receipt-universal';
  static const receiptStatus = '/transfer/receipt-status';
  static const receiptUnable = '/transfer/receipt-unable';
  static const receiptReceived = '/transfer/receipt-received';
  static const receiptInReview = '/transfer/receipt-in-review';
  static const receiptReceivedCompany = '/transfer/receipt-received-company';
  static const receiptUniversalReceived =
      '/transfer/receipt-universal-received';
  static const receiptUniversalProcessing =
      '/transfer/receipt-universal-processing';

  // Settings
  static const settings = '/settings';
  static const profile = '/settings/profile';
  static const profileEdit = '/settings/profile/edit';
  static const privacy = '/settings/privacy';
  static const security = '/settings/security';
  static const limits = '/settings/limits';
  static const privacyPolicy = '/settings/privacy-policy';
  static const legal = '/settings/legal';
  static const changePassword = '/settings/change-password';

  //pop ups
  static const cashDropPopUp = '/pop-ups/cashdrop_pop-up';
}
