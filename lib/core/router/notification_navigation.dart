import 'routes.dart';

String? notificationRoute(String? deepLink) {
  final uri = Uri.tryParse(deepLink ?? '');
  if (uri == null) return null;

  final destination = '${uri.host}${uri.path}';
  if (destination == 'support' || destination.startsWith('support/')) {
    return Routes.support;
  }

  return switch (destination) {
    'wallet' => Routes.walletOverview,
    'transactions' => Routes.transactions,
    'security/activity' => Routes.security,
    _ => null,
  };
}

String? notificationRouteFromData(Map<String, dynamic> data) {
  return notificationRoute(
    data['deepLink']?.toString() ?? data['deep_link']?.toString(),
  );
}
