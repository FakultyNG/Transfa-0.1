import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
}

abstract interface class SessionStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<String?> readLastPhoneNumber();
  Future<bool> hasCompletedOnboarding();
  Future<void> write(AuthSession session);
  Future<void> rememberPhoneNumber(String phoneNumber);
  Future<void> markOnboardingCompleted();
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'transfa_access_token';
  static const _refreshTokenKey = 'transfa_refresh_token';
  static const _lastPhoneNumberKey = 'transfa_last_phone_number';
  static const _onboardingCompletedKey = 'transfa_onboarding_completed';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<String?> readLastPhoneNumber() =>
      _storage.read(key: _lastPhoneNumberKey);

  @override
  Future<bool> hasCompletedOnboarding() async =>
      await _storage.read(key: _onboardingCompletedKey) == 'true';

  @override
  Future<void> write(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    if (session.refreshToken case final refreshToken?) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } else {
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  @override
  Future<void> rememberPhoneNumber(String phoneNumber) =>
      _storage.write(key: _lastPhoneNumberKey, value: phoneNumber);

  @override
  Future<void> markOnboardingCompleted() =>
      _storage.write(key: _onboardingCompletedKey, value: 'true');

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
