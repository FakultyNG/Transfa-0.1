# Transfa

Transfa is a Flutter fintech application centered on an NGN wallet, dedicated
funding account, local and international transfers, transaction history, and
identity verification.

## Stack

- Flutter and Dart
- Riverpod for state and dependency injection
- GoRouter for navigation
- Dio for the REST transport
- Flutter Secure Storage for access and refresh tokens
- Camera, image/file pickers, local authentication, URL launching, permissions,
  and connectivity plugins for native flows

## Project Structure

```text
lib/
  core/          Configuration, routing, theme, and utilities
  data/          API adapters, models, mock data, and repositories
  features/      Feature-oriented screens and state
  shared/        Reusable widgets
```

The UI talks to domain repositories, which depend on the `TransfaApi`
interface. `MockApi` and `RestTransfaApi` implement the same contract, so the
transport can change without changing feature code.

## Run

The production API is enabled by default:

```shell
flutter pub get
flutter run
```

The configured production base URL is `https://api.transfaintel.xyz`. Override
it for local or staging environments with:

```shell
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

Run with the local demo backend adapter using:

```shell
flutter run --dart-define=USE_MOCK_API=true
```

The initial backend contract and security expectations are documented in
[`API_REQUIREMENTS.md`](API_REQUIREMENTS.md).
Implementation coverage and known backend blockers are tracked in
[`INTEGRATION_STATUS.md`](INTEGRATION_STATUS.md).

## Verification

```shell
flutter analyze
flutter test
```
