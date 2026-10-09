// lib/app.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/router/notification_navigation.dart';
import 'core/theme/app_theme.dart';
import 'data/models/user.dart';
import 'data/notifications/push_notification_service.dart';
import 'data/repositories/repositories.dart';

import 'package:flutter/services.dart';
import 'shared/widgets/connectivity_observer.dart';

class TransfaApp extends ConsumerStatefulWidget {
  const TransfaApp({super.key});

  @override
  ConsumerState<TransfaApp> createState() => _TransfaAppState();
}

class _TransfaAppState extends ConsumerState<TransfaApp> {
  ProviderSubscription<AppUser?>? _userSubscription;
  String? _pendingPushRoute;

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushNotificationServiceProvider);
    unawaited(push.initialize(onOpen: _handleNotificationOpen));
    _userSubscription = ref.listenManual<AppUser?>(currentUserProvider, (
      previous,
      user,
    ) {
      if (user == null) return;
      unawaited(push.activate());
      final route = _pendingPushRoute;
      _pendingPushRoute = null;
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(goRouterProvider).push(route);
        });
      }
    });
  }

  void _handleNotificationOpen(Map<String, dynamic> data) {
    final route = notificationRouteFromData(data);
    if (route == null) return;
    if (ref.read(currentUserProvider) == null) {
      _pendingPushRoute = route;
      return;
    }
    ref.read(goRouterProvider).push(route);
  }

  @override
  void dispose() {
    _userSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Transfa',
      theme: AppTheme.light(context),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // ConnectivityObserver for checking when internet connection drops
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return ConnectivityObserver(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
