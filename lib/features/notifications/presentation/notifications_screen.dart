import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/notification_navigation.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/notification.dart';
import '../../../data/repositories/repositories.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationsProvider);
    }
    if (!context.mounted) return;
    final deepLink = notification.deepLink;
    if (deepLink != null) {
      final route = notificationRoute(deepLink);
      if (route != null) {
        context.push(route);
        return;
      }
    }
    await _openCta(notification.ctaUrl);
  }

  Future<void> _openCta(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.wallpaper, fit: BoxFit.cover),
          ColoredBox(color: Colors.black.withValues(alpha: 0.92)),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Notifications',
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 34,
                        ),
                      ),
                    ),
                  ),
                  notifications.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            userFacingError(error),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                    data: (items) => items.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No notifications yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _NotificationTile(
                                    notification: items[index],
                                    onTap: () => _openNotification(
                                      context,
                                      ref,
                                      items[index],
                                    ),
                                    onCta: items[index].ctaUrl == null
                                        ? null
                                        : () => _openCta(items[index].ctaUrl),
                                  ),
                                ),
                                childCount: items.length,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAllRead();
                    ref.invalidate(notificationsProvider);
                    if (context.mounted) context.go(Routes.dashboard);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userFacingError(error))),
                    );
                  }
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Mark all read'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onCta,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final color = switch (notification.category) {
      'security' => const Color(0xFFFF9F0A),
      'transactions' => const Color(0xFF34C759),
      'update' => const Color(0xFF0A84FF),
      _ => const Color(0xFFFF375F),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: notification.isRead ? 0.08 : 0.16,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.transparent : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.header,
                    style: AppTypography.bodyStrong.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (notification.ctaText != null && onCta != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onCta,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(notification.ctaText!),
                    ),
                  ],
                  if (notification.subHeader != null)
                    Text(
                      notification.subHeader!,
                      style: AppTypography.body.copyWith(color: color),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.body.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormat.dateTime(notification.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
