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

All paths use `/api/v1`. The corrected CNY quote path is
`POST /api/v1/transfers/cny/quote`.

## BVN Verification

The app sends only `registrationToken` and `bvn` for pre-registration BVN
verification. Backend derives the phone number from the registration session and,
when Strowallet is active, fetches BVN details server-side before calling
Strowallet Verify BVN. The app must not collect or send BVN name/date-of-birth
fields for this step.

When `kycSelfieRequired=true`, the app sends the captured selfie to the existing
selfie endpoint with `registrationToken`, `kycReference`, and
`selfieImageBase64`. Backend uses BytID BVN face match and feeds the BVN number
plus BVN details from the earlier verification step; the app must not send
name/date-of-birth fields for selfie KYC.

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
  "kycSelfieRequired": false
}
```

Frontend behavior:

- If `featureEnabled=false`, keep CashDrop disabled and do not request camera
  permission for CashDrop scan/register.
- If `kycSelfieRequired=false`, skip the BVN selfie camera step and continue to
  PIN creation/registration completion after BVN verification.
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
