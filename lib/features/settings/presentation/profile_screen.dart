import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/glass_card.dart';

/// Profile screen — neumorphic profile card on top, then Nigerian row,
/// Born/Phone rows, NIN row with copy button. Floating back arrow.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final kycStatus = ref.watch(kycStatusProvider);
    final user = profile.asData?.value ?? ref.watch(currentUserProvider);
    final firstName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim().split(RegExp(r'\s+')).first
        : 'Transfa';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
              children: [
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  radius: 32,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                            ? null
                            : NetworkImage(user.avatarUrl!),
                        child:
                            user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 64,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        firstName,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Transfa Account',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _PillRow(
                  leading: SizedBox(
                    width: 32,
                    height: 30,
                    child: SvgPicture.asset(
                      Assets.Nigerian_Flag,
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Text(
                    user?.country?.isNotEmpty == true
                        ? user!.country!
                        : 'Not provided',
                    style: AppTypography.subheading.copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 20),
                _GroupedCard(
                  children: [
                    _Row(
                      icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          Assets.birthdayCake,
                          fit: BoxFit.contain,
                        ),
                      ),
                      label: 'Born',
                      value: user?.dateOfBirth ?? 'Not provided',
                    ),
                    const Divider(
                      color: Color(0xFFEEEEEE),
                      height: 1,
                      indent: 0,
                    ),
                    _Row(
                      icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          Assets.phone,
                          fit: BoxFit.contain,
                        ),
                      ),
                      label: 'Phone',
                      value: user?.phone ?? 'Not provided',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _GroupedCard(
                  children: [
                    _Row(
                      icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          Assets.nationalIDGreen,
                          fit: BoxFit.contain,
                        ),
                      ),
                      label: 'Email',
                      value: (user?.email.isNotEmpty ?? false)
                          ? user!.email
                          : 'Not provided',
                    ),
                    const Divider(
                      color: Color(0xFFEEEEEE),
                      height: 1,
                      indent: 0,
                    ),
                    _Row(
                      icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          Assets.nationalID,
                          fit: BoxFit.contain,
                        ),
                      ),
                      label: 'KYC',
                      value:
                          kycStatus.value?['kycStatus']?.toString() ??
                          user?.kycStatus ??
                          'Not started',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // _PillRow(
                //   leading: Text('NIN',
                //       style: AppTypography.subheading
                //           .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                //   trailing: GestureDetector(
                //     onTap: () {
                //       Clipboard.setData(
                //           const ClipboardData(text: '0000111100002222'));
                //       ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(content: Text('NIN copied')));
                //     },
                //     child: const Icon(Icons.copy_rounded,
                //         color: AppColors.textMuted, size: 22),
                //   ),
                //   child: Text('0000 1111 0000 2222',
                //       style: AppTypography.subheading
                //           .copyWith(fontSize: 17, color: AppColors.textMuted)),
                // ),
              ],
            ),
            Positioned(
              left: 20,
              bottom: 16,
              child: _BackFab(onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final Widget leading;
  final Widget child;
  const _PillRow({required this.leading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: leading)),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section: icon + label
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 40, child: Center(child: icon)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTypography.subheading.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Right section: value
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subheading.copyWith(
                fontSize: 17,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BackFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Color(0xFFFF375F),
          size: 28,
        ),
      ),
    );
  }
}
