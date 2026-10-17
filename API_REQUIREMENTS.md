# Transfa API Contract

This file records the mobile integration boundary. The backend-provided
`API_CONTRACT.md` is authoritative for endpoint payloads and response fields.
The explicit production API host supplied for this integration is authoritative
over URLs shown in other documents.

## Configuration

Run against production with:

```text
flutter run --dart-define=API_BASE_URL=https://api.transfaintel.xyz
```

Authenticated requests send `Authorization: Bearer <access_token>`. Responses
use the contract's `{ success, message, data }` envelope and camelCase fields.

## Registration And OTP

`POST /api/v1/auth/register/start` now creates/reuses the temporary registration
session and sends the first OTP in one request. Its data includes
`registrationToken`, `phoneNumber`, `requiresOtp`, and `otpReference`. The app
must not call `/auth/otp/send` immediately afterward. `/auth/otp/resend` remains
the explicit retry route after the initial challenge.

When registration start returns `PHONE_NUMBER_ALREADY_REGISTERED` (or the
legacy `USER_ALREADY_EXISTS`), treat the number as a returning customer: skip
OTP and open `/unlock/passcode` with that phone number. A correct passcode uses
the normal login endpoint and opens Home; an incorrect passcode stays on the
passcode screen. `BVN_ALREADY_REGISTERED` remains a blocking KYC conflict and
must not advance to the next onboarding screen.

## Startup, Unlock, And Recovery

- After onboarding PIN confirmation, the welcome screen remains visible until
  the customer swipes upward; it must not auto-advance or advance on a tap.
- On a later launch, a restorable server session routes to `/unlock/passcode`.
  The submitted five-digit passcode is verified with
  `POST /api/v1/auth/passcode/verify` before Home opens.
- Once onboarding completes, persist a non-sensitive completion flag. If no
  server session can be restored on a later launch, route to `/unlock/phone`.
  Retain only the last successfully authenticated phone number as a convenience
  value; clearing expired access/refresh tokens must not clear either value.
- Passcode recovery requests an OTP with
  `POST /api/v1/auth/passcode/reset/request`, verifies it with
  `/auth/passcode/reset/verify`, and passes the returned `resetToken` into the
  existing Create PIN UI, which calls `/auth/passcode/reset/complete`.
- Face unlock first reads `GET /api/v1/auth/face-unlock/config`, captures a new
  front-camera image, and submits it with the phone number to
  `POST /api/v1/auth/face-unlock`. The API compares it with the active CashDrop
  camera profile using `CASH_DROP_MATCH_THRESHOLD`; it never uses the BVN photo.
  Countdown timing, maximum attempts, and lockout duration come from the config
  response. The default is a five-second countdown, three attempts, and a
  one-hour lockout.
- All successful unlock methods replace the locally stored mobile tokens and
  route to Home. Explicit Home controls use the dashboard route.
- Modal content routes and dismissible dialogs treat a tap on the unobscured
  background as Back. Non-dismissible in-flight progress overlays remain locked
  until their request completes to prevent navigation corruption.

## Integrated Domains

- Registration, OTP, BVN/optional selfie KYC, KYC status, login/logout, token refresh,
  passcode change/reset, and biometric trusted-device authentication.
- Wallet balance/summary, DVA retrieval/creation, and funding verification.
- NGN bank discovery/suggestions/account resolution and NGN/USD/CNY transfers.
- Recent beneficiaries and transaction history/details.
- Gift-card catalogue, quote, purchase, paginated purchase history, and detail.
- Profile retrieval/update (name, email, and date of birth), notifications, and
  device-token APIs. Phone number and KYC status remain server-controlled.
- Full support-ticket workflow and support attachment upload.
- CashDrop feature config, registration/status/disable/resolve.

## Live Home And Payment Flow

- Home balance and transaction history come from `/wallet` and `/transactions`.
- Add Money calls `POST /wallet/dva/create` and displays the returned bank and
  account number with the live wallet balance.
- The app continues to send `preferredBank: "auto"`. The backend maps this to
  Strowallet's default live virtual-account route; bank-specific provider paths,
  credentials, customer-email fallback, and webhook configuration remain
  server-only concerns.
- The Naira keypad carries its entered amount into bank selection/account
  resolution, then uses `/transfers/ngn/quote` for the server-owned fee and
  total. `NGN_TRANSFER_FIXED_FEE` is the backend fallback when no database
  pricing override exists.
- Touch to Confirm invokes local Face ID/fingerprint. When the device is already
  enabled as a trusted biometric device, confirmation sends
  `biometricDeviceId`; otherwise the UI falls back to the 5-digit PIN and sends
  `passcode`. The app never sends both.
- Confirmation and transaction-history responses expose `fee`, `totalDebit`,
  `reference`, recipient account/name, bank, and narration so status and receipt
  screens contain live data.
- Support is presented as one continuous instant-message thread. The existing
  ticket endpoints remain an internal persistence mechanism; the app merges the
  customer's message history and replies to the latest open record.
- Home, Settings, profile, and CashDrop use `profileImageUrl` from `/profile` or
  `/cash-drop/status`. This URL is the successfully matched camera faceshot,
  never the BVN provider photo or a bundled demo asset.

All paths use `/api/v1`. The corrected CNY quote path is
`POST /api/v1/transfers/cny/quote`.

## BVN Verification

The app sends only `registrationToken` and `bvn` for pre-registration BVN
verification. Backend derives the phone number from the registration session and,
when Strowallet is active, fetches BVN details server-side before calling
Strowallet Verify BVN. The app must not collect or send BVN name/date-of-birth
fields for this step.

When `kycSelfieRequired=true`, behavior is selected by `kycSelfieMode` from the
feature config. `static` sends the captured image to the existing selfie
endpoint. `bytid_liveness` captures and retains a front-camera profile image,
starts `/kyc/bvn/liveness/start`, opens the returned hosted URL, handles the
`transfa://kyc/liveness-complete` callback inside a full-screen in-app WebView, polls
`/kyc/bvn/liveness/status`, and calls `/kyc/bvn/liveness/complete` only after
the session is usable. The profile image is for the customer profile and
CashDrop only; BytID uses `liveness_session_id` to match against the stored BVN.

Every selfie retry keeps the same public `registrationToken` and `kycReference`.
Backend creates a distinct BytID provider reference per captured image, so the
mobile app must not generate or send a provider reference. BytID configuration,
permission, balance, validation, IP allowlist, and rate-limit failures arrive as
specific `BYTID_*` error codes with a safe root message for the existing error UI.

The selfie response includes `kycStatus`, `faceMatch`, `confidenceScore`,
`faceMatchStatus`, `faceMatchReason`, and `livenessStatus`. The app must only
advance when `kycStatus=verified` and `faceMatch=true`. On rejection it displays
`faceMatchReason`, because a BytID HTTP 200 may still contain `not_matched` or
`unavailable`. A static selfie normally reports `livenessStatus=not_checked`.

## CashDrop / Selfie Feature Flags

The app must call:

```text
GET /api/v1/cash-drop/config
```

before showing CashDrop camera actions or routing BVN onboarding into the
Face Shot screen.

Expected data:

```json
{
  "featureEnabled": false,
  "kycSelfieRequired": false,
  "kycSelfieMode": "bytid_liveness",
  "selfieCountdownEnabled": true,
  "selfieCountdownSeconds": 5
}
```

Frontend behavior:

- If `featureEnabled=false`, keep CashDrop disabled and do not request camera
  permission for CashDrop scan/register.
- If `kycSelfieRequired=false`, skip the BVN selfie camera step and continue to
  PIN creation/registration completion after BVN verification.
- If `kycSelfieMode=bytid_liveness`, use the hosted session flow. If it is
  `static`, use `/kyc/bvn/selfie-validate` with the camera image.
- If `selfieCountdownEnabled=true`, display `selfieCountdownSeconds` before
  automatically capturing the selfie. If disabled, capture as soon as the
  camera is ready.
- A failed face match may be retried with the same `registrationToken` and
  `kycReference`; backend retains the verified BVN only until success or session
  expiry. The retry action must reset the captured image, verification state,
  timer, and camera preview.
- `GET /api/v1/cash-drop/status` also returns `featureEnabled`; when disabled
  it returns `status: "disabled_by_config"`.

## Error Shape

Non-2xx responses should use a stable machine-readable code and safe message:

```json
{
  "success": false,
  "message": "Your wallet balance is too low for this transfer.",
  "error": {
    "code": "INSUFFICIENT_FUNDS"
  }
}
```

## Backend Requirements

- Treat money as fixed-precision decimal values in storage and calculations.
- Make financial confirmation idempotent using the quote ID or an explicit
  idempotency key.
- Expire quotes server-side and never trust fees, totals, rates, or balances
  submitted by the app.
- Rate-limit authentication, OTP, passcode, and transfer endpoints.
- Encrypt sensitive personal data and keep an immutable transfer audit trail.
- Return UTC ISO-8601 timestamps and uppercase ISO currency codes.
