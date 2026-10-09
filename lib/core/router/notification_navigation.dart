import 'routes.dart';

String? notificationRoute(String? deepLink) {
  final uri = Uri.tryParse(deepLink ?? '');
  if (uri == null) return null;

  return switch ('${uri.host}${uri.path}') {
    'wallet' => Routes.walletOverview,
    'transactions' => Routes.transactions,
    'security/activity' => Routes.security,
    'support' => Routes.support,
    _ => null,
  };
}

String? notificationRouteFromData(Map<String, dynamic> data) {
  return notificationRoute(
    data['deepLink']?.toString() ?? data['deep_link']?.toString(),
  );
}
