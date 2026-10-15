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
  });
}
