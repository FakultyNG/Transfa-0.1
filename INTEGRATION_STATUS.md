# Backend Integration Status

Status captured on 2026-10-09. The explicit API host supplied for this work is
`https://api.transfaintel.xyz`; all application routes add the `/api/v1`
prefix.

## Implemented And Locally Verified

- Auth: registration, OTP send/resend/validation, login, logout, token refresh,
  passcode change, the full passcode-reset flow, and persisted-session restore.
- KYC: BVN verification, selfie validation, and KYC status.
- Wallet/funding: balance, wallet summary, DVA get/create, and manual funding
  verification.
- Transfers: NGN bank list, bank suggestions, account resolution, NGN/USD/CNY
  quote and confirmation, recent-beneficiary list/search/delete, and
  transaction history/details.
- Gift cards: catalogue, quote, purchase, paginated purchase history, and
  purchase-detail API support.
- Support: create/list/detail/reply/close tickets and multipart attachments.
- Profile: retrieval and editable first name, last name, email, and date of
  birth. Phone number and KYC status are correctly treated as server-controlled.
- Device features: local biometric checks plus backend trusted-device status,
  enable, disable, and login; CashDrop status, register, disable, and scan
  resolution.
- Notifications: list, mark one/all read, semantic deep links, external CTA
  links, Firebase initialization, permission handling, foreground refresh,
  background/tap handling, and automatic device-token register/refresh/remove.
- Native mobile configuration: Android and iOS identifiers are
  `com.transfa.app`; both supplied Firebase client files are installed.
- Contract-shaped local mocks and model tests for the integrated interfaces.

## Live Verification

- `GET https://api.transfaintel.xyz/api/v1/health` returned HTTP 200 with
  `{"status":"ok"}`.
- A protected gift-card request without a token returned HTTP 401 as expected.
- Authenticated end-to-end acceptance still requires a test user with wallet
  funds and cannot be completed from an anonymous health check.

## Remaining External Prerequisites

- The deployed backend must receive `FIREBASE_PROJECT_ID`,
  `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` from a Firebase Admin
  service account. The mobile Firebase files do not contain the server private
  key.
- Apple push delivery requires an APNs authentication key or certificate linked
  to the iOS app in Firebase Console and the App Store signing capability.
- The new backend migration and gift-card routes must be deployed before live
  purchase-history acceptance. The configured local PostgreSQL service was not
  running, so the migration was generated and validated but not locally applied.
- A native Android build cannot run on this workstation until an Android SDK is
  installed and `ANDROID_HOME` is configured. Windows Developer Mode is also
  required when Flutter regenerates plugin symlinks.
- Non-breaking npm audit updates were applied. The backend still reports 20
  production dependency advisories (5 high, 14 moderate, 1 low); clearing the
  high findings requires planned NestJS/platform-express and Sharp major-version
  upgrades rather than an automatic forced update.

## Missing From The Contract

- NIN, photo-ID, and proof-of-address submission endpoints used by existing
  identity screens. These screens remain unchanged pending the planned product
  replacement/hide work.
- Power and internet/data utility endpoints.
- Admin endpoints are intentionally not exposed in the customer mobile app.

## Contract Correction

The CNY quote route has been implemented as `POST /transfers/cny/quote`. The
attached backend `API_CONTRACT.md` was updated from the accidental USD route to
this CNY route.

## Local Verification

- Targeted Flutter analysis: no issues in the integration code. Whole-project
  analysis has no compile errors; legacy warnings/style notices remain elsewhere.
- Flutter tests: 13 passed.
- Backend TypeScript typecheck/build: passed.
- Backend tests: 87 passed across 21 suites.
- `git diff --check`: passed.
- Native Android build attempted and blocked before compilation because no
  Android SDK is installed on this workstation.
