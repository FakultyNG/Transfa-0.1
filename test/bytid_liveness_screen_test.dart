import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/features/auth/presentation/bytid_liveness_screen.dart';

void main() {
  group('BytID liveness callback', () {
    test('accepts the expected Transfa callback and session', () {
      final result = BytidLivenessScreen.completionFromUrl(
        'transfa://kyc/liveness-complete?liveness_session_id=live_123&status=passed',
        'live_123',
      );

      expect(result?.sessionId, 'live_123');
      expect(result?.status, 'passed');
    });

    test('accepts the backend HTTPS return before its app redirect', () {
      final result = BytidLivenessScreen.completionFromUrl(
        'https://api.transfaintel.xyz/api/v1/kyc/bvn/liveness/return?liveness_session_id=live_123&status=passed&reference=kyc_ref',
        'live_123',
      );

      expect(result?.sessionId, 'live_123');
      expect(result?.status, 'passed');
    });

    test('rejects a callback for a different session', () {
      final result = BytidLivenessScreen.completionFromUrl(
        'transfa://kyc/liveness-complete?liveness_session_id=live_other&status=passed',
        'live_123',
      );

      expect(result, isNull);
    });

    test('rejects unrelated custom URLs', () {
      final result = BytidLivenessScreen.completionFromUrl(
        'another-app://kyc/liveness-complete?liveness_session_id=live_123',
        'live_123',
      );

      expect(result, isNull);
    });

    test('rejects unrelated HTTPS URLs carrying callback-like parameters', () {
      final result = BytidLivenessScreen.completionFromUrl(
        'https://example.com/unrelated?liveness_session_id=live_123&status=passed',
        'live_123',
      );

      expect(result, isNull);
    });
  });
}
