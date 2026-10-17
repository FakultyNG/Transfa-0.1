import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True only after the user has authenticated during the current foreground
/// session. It is reset whenever the app leaves the foreground.
final appUnlockedProvider = StateProvider<bool>((_) => false);

/// A notification destination waiting for authentication. Keeping this out of
/// the router prevents a notification tap from briefly exposing protected UI.
final pendingAuthenticatedRouteProvider = StateProvider<String?>((_) => null);

String unlockAppAndTakePendingRoute(WidgetRef ref) {
  ref.read(appUnlockedProvider.notifier).state = true;
  final pending = ref.read(pendingAuthenticatedRouteProvider);
  ref.read(pendingAuthenticatedRouteProvider.notifier).state = null;
  return pending ?? '/dashboard';
}
