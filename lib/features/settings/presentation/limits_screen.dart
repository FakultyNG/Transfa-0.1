import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../data/repositories/repositories.dart';

class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  static const _plans = [
    _Plan('Citizen', Assets.contactsRed, [
      _Limit('Send', '₦50,000'),
      _Limit('Receive', '₦300,000'),
      _Limit('Max Balance', '₦300,000'),
    ], true),
    _Plan('Captain', Assets.group, [
      _Limit('Send', '₦200,000'),
      _Limit('Receive', '₦500,000'),
      _Limit('Max Balance', '₦500,000'),
    ], false),
    _Plan('Prime', Assets.chess, [
      _Limit('Send', '₦5,000,000'),
      _Limit('Receive', 'Over ₦1 Billion'),
      _Limit('Max Balance', 'Over ₦1 Trillion'),
    ], false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier =
        ref.watch(profileProvider).valueOrNull?.accountTier ?? 'citizen';
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEF1),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                0,
                60,
                0,
                120,
              ), // Removed horizontal padding
              children: [
                // Header with horizontal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHeader(),
                ),
                const SizedBox(height: 28),
                // Page note with horizontal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPageNote(),
                ),
                const SizedBox(height: 28),
                // Horizontal scrolling plan cards - edge to edge
                SizedBox(
                  height: 620,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ), // Add padding to the list itself
                    itemCount: _plans.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, i) =>
                        _buildPlanCard(context, _plans[i], tier),
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

  Widget _buildHeader() => GlassCard(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
    radius: 32,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(Assets.moneyLimits, width: 60, height: 60),
        const SizedBox(height: 22),
        Text(
          'Money Limits',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'See how much you can currently\nsend, receive & hold with Transfa.',
          style: AppTypography.body.copyWith(fontSize: 17),
        ),
      ],
    ),
  );

  Widget _buildPageNote() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      'Transfa automatically reviews and adjusts your money limits based on your income, history, and connections.',
      style: AppTypography.displayMedium.copyWith(fontSize: 20, height: 1.3),
    ),
  );

  Widget _buildPlanCard(
    BuildContext context,
    _Plan plan,
    String tier,
  ) => Container(
    width: 330,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(45),
    ),
    child: Column(
      children: [
        _buildPlanHeader(plan, tier),
        const Divider(color: Color(0x08000000), height: 1, thickness: 1),
        ...plan.limits.expand(
          (l) => [
            _LimitRow(l),
            const Divider(color: Color(0x08000000), height: 1, thickness: 1),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'This is the total amount of Nigerian Naira you can Transfa daily.',
            style: AppTypography.body.copyWith(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const Divider(color: Color(0x08000000), height: 1, thickness: 1),
        _buildVerificationOptions(context, plan),
      ],
    ),
  );

  Widget _buildPlanHeader(_Plan plan, String tier) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(35)),
          alignment: Alignment.center,
          child: SvgPicture.asset(plan.icon, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            plan.name,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_tierRank(tier) >= _tierRank(plan.name.toLowerCase()))
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(35)),
            child: SvgPicture.asset(Assets.checkRound, fit: BoxFit.cover),
          ),
      ],
    ),
  );

  Widget _buildVerificationOptions(BuildContext context, _Plan plan) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: plan.name == 'Prime'
          ? [
              _VerificationOption('Home', Assets.sweetHome, false),
              const SizedBox(height: 10),
              _VerificationOption('Face Shot', Assets.faceIDRound, true),
              const SizedBox(height: 10),
              _VerificationOption('Passport Photo', Assets.photoIDRound, true),
            ]
          : [
              _VerificationOption(
                plan.name == 'Citizen' ? 'BVN' : 'NIN',
                plan.name == 'Citizen' ? Assets.cbnLogo : Assets.nimcLogo,
                plan.name == 'Citizen',
                onTap: plan.name == 'Captain'
                    ? () => context.push(Routes.addNin)
                    : null,
              ),
            ],
    ),
  );

  int _tierRank(String tier) => switch (tier) {
    'prime' => 3,
    'captain' => 2,
    _ => 1,
  };
}

class _Plan {
  final String name;
  final String icon;
  final List<_Limit> limits;
  final bool verified;
  const _Plan(this.name, this.icon, this.limits, this.verified);
}

class _Limit {
  final String label;
  final String amount;
  const _Limit(this.label, this.amount);
}

class _LimitRow extends StatelessWidget {
  final _Limit limit;
  const _LimitRow(this.limit);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Text(limit.label, style: AppTypography.body.copyWith(fontSize: 17)),
        const Spacer(),
        Text(
          limit.amount,
          style: AppTypography.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            decorationColor: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      ],
    ),
  );
}

class _VerificationOption extends StatelessWidget {
  final String label;
  final String icon;
  final bool verified;
  final VoidCallback? onTap;
  const _VerificationOption(this.label, this.icon, this.verified, {this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFB),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(35)),
            alignment: Alignment.center,
            child: label == "BVN" || label == "NIN"
                ? Image.asset(icon, fit: BoxFit.cover)
                : SvgPicture.asset(icon, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(fontSize: 17),
            ),
          ),
          if (verified)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
              ),
              child: SvgPicture.asset(Assets.checkRound, fit: BoxFit.cover),
            )
          else
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFD9D6CD),
              size: 14,
            ),
        ],
      ),
    ),
  );
}

class _BackFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BackFab({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
