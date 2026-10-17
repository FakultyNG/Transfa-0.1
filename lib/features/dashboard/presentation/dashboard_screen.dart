import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/user.dart';
import '../../../data/models/wallet.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/transfa_logo.dart';
import '../../../shared/widgets/wallpaper_scaffold.dart';
import '../../../features/pop-ups/viewBalance_popup.dart';
import '../../../features/pop-ups/cashdrop_popup.dart';

/// iOS-style home: bell top-right, "🏠 Home" title, frosted balance widget
/// with profile + balance + Add Money pill, then a grid of app icons.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _addMoneyClicked = false;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final liveProfile = ref.watch(profileProvider);
    final user = liveProfile.asData?.value ?? ref.watch(currentUserProvider);
    final balance = wallet.maybeWhen(
      data: (w) => w.ngnBalance,
      orElse: () => 0,
    );
    final showAddMoney = !_addMoneyClicked && (user?.showAddMoney ?? true);

    return WallpaperScaffold(
      darken: 0.35,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(profileProvider);
          await Future.wait([
            ref.read(walletProvider.future),
            ref.read(profileProvider.future),
          ]);
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),
                      // Bell with red dot
                      Align(
                        alignment: Alignment.centerRight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  context.push(Routes.notifications),
                              icon: SvgPicture.asset(
                                Assets.notificationCenter,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Home title.
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Row(
                          children: [
                            SvgPicture.asset(Assets.home, fit: BoxFit.contain),
                            const SizedBox(width: 10),
                            Text(
                              'Home',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      _BalanceWidget(
                        user: user,
                        balance: balance,
                        showAddMoney: showAddMoney,
                        onAddMoney: () => _openAddMoney(context, user, balance),
                      ),
                      const SizedBox(height: 32), // Equal spacing
                      // App icon grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _HomeAppIcon(
                            label: 'Settings',
                            // background: const Color(0xFF1A1A1A),
                            onTap: () => context.push(Routes.settings),
                            iconScale: 1,
                            child: SvgPicture.asset(
                              Assets.settingsBadge,
                              fit: BoxFit.contain,
                            ),
                          ),
                          _HomeAppIcon(
                            label: 'Support',
                            background: const Color(0xFF1976FF),
                            iconScale: 1,
                            onTap: () => context.push(Routes.support),
                            child: Image.asset(
                              Assets.appIconSupport,
                              fit: BoxFit.cover,
                            ),
                          ),
                          _HomeAppIcon(
                            label: 'Transfa',
                            background: const Color(0xFF1A1A1A),
                            onTap: () => context.push(Routes.amount),
                            child: const TransfaMark(size: 32, white: true),
                          ),
                          _HomeAppIcon(
                            label: 'CashDrop',
                            iconScale: 1,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C2FF), Color(0xFF006EFF)],
                            ),
                            svgAsset: Assets.cashDropHome,
                            onTap: () => _showCashDropPopup(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _HomeAppIcon(
                            label: 'Wallet',
                            background: const Color(0xFF1A1A1A),
                            iconScale: 1,
                            onTap: () => context.push(Routes.walletWidget),
                            child: SvgPicture.asset(
                              Assets.transfaWallet,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddMoney(
    BuildContext context,
    AppUser? user,
    num balance,
  ) async {
    if (!_addMoneyClicked && (user?.showAddMoney ?? true)) {
      setState(() => _addMoneyClicked = true);
      final updated = user?.copyWith(showAddMoney: false);
      if (updated != null) {
        ref.read(currentUserProvider.notifier).state = updated;
      }
      try {
        await ref.read(walletRepositoryProvider).markAddMoneyClicked();
        ref.invalidate(profileProvider);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
        }
      }
    }
    if (context.mounted) {
      await _showViewBalancePopup(context, ref, user, balance);
    }
  }

  Future<void> _showViewBalancePopup(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    num balance,
  ) async {
    var requestFinished = false;
    var dismissedByUser = false;
    BuildContext? progressContext;
    void dismissProgress() {
      final dialogContext = progressContext;
      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        progressContext = dialogContext;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && !requestFinished) dismissedByUser = true;
          },
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
    late final DedicatedVirtualAccount dva;
    num displayedBalance = balance;
    try {
      final walletRepository = ref.read(walletRepositoryProvider);
      final results = await Future.wait<Object>([
        walletRepository.createDva(),
        walletRepository.get(),
      ]);
      dva = results[0] as DedicatedVirtualAccount;
      displayedBalance = (results[1] as Wallet).ngnBalance;
      ref.invalidate(dvaProvider);
      ref.invalidate(walletProvider);
    } catch (error) {
      requestFinished = true;
      dismissProgress();
      if (context.mounted && !dismissedByUser) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
      }
      return;
    }
    requestFinished = true;
    dismissProgress();
    if (!context.mounted || dismissedByUser) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => ViewBalancePopup(
        user: user,
        balance: displayedBalance,
        dva: dva,
        onCashDropTap: () {
          Navigator.of(context).pop();
          _showCashDropPopup(context);
        },
      ),
    );
  }

  void _showCashDropPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const CashDropScreen(),
    );
  }
}

class _BalanceWidget extends StatelessWidget {
  final AppUser? user;
  final num balance;
  final bool showAddMoney;
  final VoidCallback? onAddMoney;

  const _BalanceWidget({
    required this.user,
    required this.balance,
    required this.showAddMoney,
    this.onAddMoney,
  });

  String _formatBalance(num amount) {
    final formatted = AppFormat.ngn(amount);
    // Remove cents if present
    if (formatted.contains('.')) {
      return formatted.split('.').first;
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAddMoney,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            height: 190,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), // Equal padding
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Photo - same size as service icons (60x60)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF00BCF6), Color(0xFF006EFF)],
                    ),
                  ),
                  child: ClipOval(child: _ProfileImage(url: user?.avatarUrl)),
                ),
                const SizedBox(height: 8), // Space between photo and balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _formatBalance(balance),
                        style: TextStyle(
                          fontFamily: 'Arial Rounded MT Bold',
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (showAddMoney) // Only show if balance < N50k
                      GestureDetector(
                        onTap: onAddMoney,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Text(
                            'Add Money',
                            style: AppTypography.bodyStrong.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const Icon(Icons.person_rounded, color: Colors.white, size: 34);
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.person_rounded, color: Colors.white, size: 34),
    );
  }
}

class _HomeAppIcon extends StatelessWidget {
  final String label;
  final Widget? child;
  final String? svgAsset;
  final Color? background;
  final Gradient? gradient;
  final double iconScale;
  final VoidCallback? onTap;

  const _HomeAppIcon({
    required this.label,
    this.child,
    this.svgAsset,
    this.background,
    this.gradient,
    this.iconScale = 0.55,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: background,
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 66 * iconScale,
                height: 66 * iconScale,
                child:
                    child ??
                    (svgAsset != null
                        ? SvgPicture.asset(svgAsset!, fit: BoxFit.contain)
                        : const SizedBox.shrink()),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
