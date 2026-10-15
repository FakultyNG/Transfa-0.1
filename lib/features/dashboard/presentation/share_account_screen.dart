import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/transfa_logo.dart';

/// Personalised "Transfa" profile card with the user's photo, name and a
/// large red account-number pill — used when sharing receive details.
class ShareAccountScreen extends ConsumerWidget {
  const ShareAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dva = ref.watch(dvaProvider);
    final account = dva.maybeWhen(
      data: (d) => d.accountNumber,
      orElse: () => '—',
    );

    return ModalScaffold(
      horizontalPadding: 28,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: TransfaMark(size: 22, white: true),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Transfa',
                  style: AppTypography.heading.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 78,
                backgroundImage:
                    user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                    ? null
                    : NetworkImage(user.avatarUrl!),
                backgroundColor: Colors.grey,
                child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 72,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                user?.fullName ?? 'Transfa customer',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Account Number',
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    account.replaceAllMapped(
                      RegExp(r'(\d{3})(\d{3})(\d{4})'),
                      (m) => '${m[1]} ${m[2]} ${m[3]}',
                    ),
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
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
