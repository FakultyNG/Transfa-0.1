import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/device_identity.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/glass_card.dart';

/// Security — intro card (green shield), True Face toggle, grouped
/// Verify/change passcode tiles and biometric-login controls.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _trueFace = true;
  bool _changingBiometric = false;

  Future<void> _setBiometric(bool enabled) async {
    if (_changingBiometric) return;
    setState(() => _changingBiometric = true);
    try {
      final deviceId = await DeviceIdentity().getOrCreate();
      final repository = ref.read(deviceFeaturesRepositoryProvider);
      if (enabled) {
        final localAuth = LocalAuthentication();
        final authenticated = await localAuth.authenticate(
          localizedReason: 'Confirm your identity to enable biometric login',
          biometricOnly: true,
        );
        if (!authenticated) return;
        final types = await localAuth.getAvailableBiometrics();
        final method = types.contains(BiometricType.face)
            ? 'face_id'
            : types.contains(BiometricType.fingerprint)
            ? 'fingerprint'
            : 'biometric';
        await repository.enableBiometric(method: method, deviceId: deviceId);
      } else {
        await repository.disableBiometric(deviceId);
      }
      ref.invalidate(biometricStatusProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _changingBiometric = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometric = ref.watch(biometricStatusProvider);
    final biometricEnabled = biometric.value?.enabled ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
              children: [
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  radius: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: SvgPicture.asset(
                          Assets.security,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 15),
                      Text(
                        'Security',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage how you access your\nTransfa.',
                        style: AppTypography.body.copyWith(fontSize: 17),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _PillToggle(
                  icon: _PurpleTile(
                    child: const Icon(
                      Icons.tag_faces_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  label: 'True Face',
                  value: _trueFace,
                  onChanged: (v) => setState(() => _trueFace = v),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'To connect & keep your money private, allow Face Shot to learn about the people who use your Transfa.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _GroupedCard(
                  children: [
                    _ChevronRow(
                      icon: _OrangeLockTile(),
                      label: 'Change Passcode',
                      onTap: () => context.push(Routes.changePassword),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Face Shot is required to change your Transfa Passcode.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _PillToggle(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: SvgPicture.asset(
                      Assets.useFaceId,
                      fit: BoxFit.contain,
                    ),
                  ),

                  label: 'Use biometrics',
                  value: biometricEnabled,
                  onChanged: _changingBiometric ? (_) {} : _setBiometric,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Unlock and Transfa with your device biometrics.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
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

class _PillToggle extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PillToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          SizedBox(width: 44, height: 44, child: Center(child: icon)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: AppTypography.subheading.copyWith(fontSize: 17),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: onChanged,
          ),
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
      child: Column(children: children),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _ChevronRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 30, height: 30, child: Center(child: icon)),
            const SizedBox(width: 14),
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

class _PurpleTile extends StatelessWidget {
  final Widget child;
  const _PurpleTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFAF52DE),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _GreenLockTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
    );
  }
}

class _OrangeLockTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF7A00)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
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
