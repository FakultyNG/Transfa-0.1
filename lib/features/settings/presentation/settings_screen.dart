import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/notifications/push_notification_service.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/homeFab.dart';

/// Simpler "Settings" — header tile (gear), profile card with chevron,
/// then a single rounded list with Privacy + Security rows, and a Home
/// pill at the bottom-left.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProfile = ref.watch(profileProvider);
    final sessionUser = ref.watch(currentUserProvider);
    final fetchedProfile = liveProfile.asData?.value;
    final user = fetchedProfile?.id == sessionUser?.id
        ? fetchedProfile
        : sessionUser;
    final fullName = user?.fullName.trim() ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,

                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      Assets.settingsBadge,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Settings',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              _ProfileRow(
                name: fullName.isNotEmpty ? fullName : 'Transfa',
                imageUrl: user?.avatarUrl,
                onTap: () => context.push(Routes.profile),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: SvgPicture.asset(
                        Assets.privacy,
                        width: 30,
                        height: 30,
                      ),
                      label: 'Privacy',
                      onTap: () => context.push(Routes.privacy),
                    ),
                    const Divider(color: Color(0x080A0A0A), height: 1),
                    _SettingsRow(
                      icon: _GreenTile(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: SvgPicture.asset(
                            Assets.security,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      label: 'Security',
                      onTap: () => context.push(Routes.security),
                    ),
                    const Divider(color: Color(0x080A0A0A), height: 1),
                    _SettingsRow(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 28,
                      ),
                      label: 'Log out',
                      onTap: () async {
                        try {
                          await ref
                              .read(pushNotificationServiceProvider)
                              .deactivate();
                          await ref.read(authRepositoryProvider).logout();
                        } finally {
                          ref.read(currentUserProvider.notifier).state = null;
                          ref.invalidate(walletProvider);
                          ref.invalidate(transactionsProvider);
                          ref.invalidate(sessionRestorationProvider);
                          if (context.mounted) {
                            context.go(Routes.welcomeIntro);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Designed by Magic in Ohafia.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              HomeFab(onTap: () => context.go(Routes.dashboard)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;
  const _ProfileRow({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: imageUrl == null || imageUrl!.isEmpty
                  ? null
                  : NetworkImage(imageUrl!),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.subheading.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Transfa Account & ID.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.subheading.copyWith(fontSize: 17),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreenTile extends StatelessWidget {
  final Widget child;
  const _GreenTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
