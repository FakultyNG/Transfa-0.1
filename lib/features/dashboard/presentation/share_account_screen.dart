import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/repositories.dart';
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
    final bankName = dva.maybeWhen(
      data: (d) => d.bankName,
      orElse: () => 'Bank',
    );

    return ModalScaffold(
      horizontalPadding: 28,
      child: AccountShareCard(
        user: user,
        bankName: bankName,
        accountNumber: account,
      ),
    );
  }
}

/// The original account-details card. This same widget is rendered into the
/// PNG shared from the wallet popup, keeping the preview and exported image
/// identical.
class AccountShareCard extends StatelessWidget {
  const AccountShareCard({
    super.key,
    required this.user,
    required this.bankName,
    required this.accountNumber,
  });

  final AppUser? user;
  final String bankName;
  final String accountNumber;

  String get _formattedAccountNumber {
    final digits = accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (digits.length != 10) return accountNumber;
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl;
    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(52),
      ),
      child: Material(
        color: Colors.transparent,
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
                    color: const Color(0xFF111111),
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E5EA),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 72,
                          color: Colors.white,
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                user?.fullName ?? 'Transfa customer',
                style: AppTypography.displayMedium.copyWith(
                  color: const Color(0xFF111111),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 42),
            Container(
              width: double.infinity,
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
                    bankName,
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formattedAccountNumber,
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
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
