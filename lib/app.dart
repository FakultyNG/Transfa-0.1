// lib/app.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/router/notification_navigation.dart';
import 'core/security/app_lock_state.dart';
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

class _TransfaAppState extends ConsumerState<TransfaApp>
    with WidgetsBindingObserver {
  ProviderSubscription<AppUser?>? _userSubscription;
  bool _lockOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final push = ref.read(pushNotificationServiceProvider);
    unawaited(push.initialize(onOpen: _handleNotificationOpen));
    _userSubscription = ref.listenManual<AppUser?>(currentUserProvider, (
      previous,
      user,
    ) {
      if (previous?.id != user?.id) {
        ref.invalidate(profileProvider);
        ref.invalidate(walletProvider);
        ref.invalidate(walletSummaryProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadSupportCountProvider);
        ref.invalidate(supportTicketsProvider);
      }
      if (user == null) return;
      unawaited(push.activate());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _lockOnResume = ref.read(currentUserProvider) != null;
      if (_lockOnResume) {
        ref.read(appUnlockedProvider.notifier).state = false;
      }
      return;
    }
    if (state != AppLifecycleState.resumed || !_lockOnResume) return;
    _lockOnResume = false;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(goRouterProvider);
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path == Routes.unlockPasscode || path.startsWith('/unlock/')) return;
      router.go(Routes.unlockPasscode, extra: user.phone);
    });
  }

  void _handleNotificationOpen(Map<String, dynamic> data) {
    final route = notificationRouteFromData(data);
    if (route == null) return;
    if (ref.read(currentUserProvider) == null ||
        !ref.read(appUnlockedProvider)) {
      ref.read(pendingAuthenticatedRouteProvider.notifier).state = route;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(goRouterProvider).go(Routes.unlockPasscode, extra: user.phone);
      }
      return;
    }
    ref.read(goRouterProvider).push(route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
