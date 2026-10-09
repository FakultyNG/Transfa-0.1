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

- Registration, OTP, BVN/selfie KYC, KYC status, login/logout, token refresh,
  passcode change/reset, and biometric trusted-device authentication.
- Wallet balance/summary, DVA retrieval/creation, and funding verification.
- NGN bank discovery/suggestions/account resolution and NGN/USD/CNY transfers.
- Recent beneficiaries and transaction history/details.
- Gift-card catalogue, quote, purchase, paginated purchase history, and detail.
- Profile retrieval/update (name, email, and date of birth), notifications, and
  device-token APIs. Phone number and KYC status remain server-controlled.
- Full support-ticket workflow and support attachment upload.
- CashDrop registration/status/disable/resolve.

All paths use `/api/v1`. The corrected CNY quote path is
`POST /api/v1/transfers/cny/quote`.

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
