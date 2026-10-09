import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/device_identity.dart';
import '../repositories/repositories.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService({
    required NotificationRepository repository,
    required DeviceIdentity deviceIdentity,
    required void Function() onForegroundMessage,
  }) : _repository = repository,
       _deviceIdentity = deviceIdentity,
       _onForegroundMessage = onForegroundMessage;

  final NotificationRepository _repository;
  final DeviceIdentity _deviceIdentity;
  final void Function() _onForegroundMessage;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openSubscription;
  void Function(Map<String, dynamic> data)? _onOpen;
  bool _initialized = false;
  bool _active = false;

  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onOpen,
  }) async {
    _onOpen = onOpen;
    if (_initialized) return;
    _initialized = true;

    _messageSubscription = FirebaseMessaging.onMessage.listen((_) {
      _onForegroundMessage();
    });
    _openSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _onOpen?.call(message.data),
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      if (_active) unawaited(_registerSafely(token));
    });

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _onOpen?.call(initialMessage.data);
    } catch (_) {
      // A notification lookup failure should not interrupt app startup.
    }
  }

  Future<void> activate() async {
    _active = true;
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        for (var attempt = 0; attempt < 8; attempt++) {
          if (await _messaging.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) await _register(token);
    } catch (_) {
      // Push setup must never prevent an authenticated session from opening.
    }
  }

  Future<void> deactivate() async {
    _active = false;
    final deviceId = await _deviceIdentity.getOrCreate();
    try {
      await _repository.removeDeviceToken(deviceId);
    } catch (_) {
      // The device may not have a backend registration yet.
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Local Firebase cleanup is best-effort during logout.
    }
  }

  Future<void> _registerSafely(String token) async {
    try {
      await _register(token);
    } catch (_) {
      // Token refresh will retry naturally, or registration runs at next login.
    }
  }

  Future<void> _register(String token) async {
    await _repository.registerDeviceToken(
      deviceId: await _deviceIdentity.getOrCreate(),
      fcmToken: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
    _openSubscription?.cancel();
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    repository: ref.watch(notificationRepositoryProvider),
    deviceIdentity: DeviceIdentity(),
    onForegroundMessage: () => ref.invalidate(notificationsProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
