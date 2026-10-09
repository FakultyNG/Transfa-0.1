import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:transfa/shared/widgets/homeFab.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/wallpaper_scaffold.dart';
import '../../../shared/widgets/transfa_logo.dart';

/// "Wallet / For everything you do" — the iOS-widget-style frosted card
/// shown on the home/lock screen surface. Distinct from the full Wallet
/// detail (which exposes balance + DVA). Tapping opens the full Wallet.
///
/// Layout (matches the user-supplied screenshot):
///   • Big frosted "Wallet" widget card with the rainbow wallet glyph
///   • Row of three app icons underneath: Power · Internet · Reeplay
///   • Bottom row: gradient Home pill (left) and red + button (right)
class WalletWidgetScreen extends StatelessWidget {
  const WalletWidgetScreen({super.key});

  void _showComingSoonPopup(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: true,
      builder: (context) => _ComingSoonPopup(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      darken: 0.50,
      blur: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          children: [
            const Spacer(flex: 3),

            // 1. Frosted Wallet widget card.
            GestureDetector(
              onTap: () => context.push(Routes.walletOverview),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: SvgPicture.asset(
                            Assets.transfaWallet,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Wallet',
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For everything you do.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 2. Row of three app-icon tiles: Power · Internet · Reeplay.
            Row(
              children: [
                _AppIcon(
                  asset: Assets.powerIcon,
                  label: 'Power',
                  onTap: () => _showComingSoonPopup(
                    context,
                    'Easter Egg',
                    'You got 7 Days of Power. Share power when available on Transfa.',
                  ),
                ),
                const SizedBox(width: 30),
                _AppIcon(
                  asset: Assets.internetIcon,
                  label: 'Internet',
                  onTap: () => _showComingSoonPopup(
                    context,
                    'Easter Egg',
                    'You got 7 Days of Internet. Share photos when Internet is available on Transfa.',
                  ),
                ),
                const SizedBox(width: 30),
                _AppIcon(
                  asset: Assets.reeplayIcon,
                  label: 'Reeplay',
                  onTap: () => context.push(Routes.giftCards),
                ),
              ],
            ),
            const Spacer(flex: 1),

            // 3. Bottom row: gradient Home pill (left) + red + button (right).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HomeFab(onTap: () => context.go(Routes.dashboard)),
                Add(onTap: () => context.go(Routes.addMoney)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _AppIcon({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          label == 'Reeplay'
              ? Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Image.asset(asset, fit: BoxFit.contain),
                )
              : SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePill extends StatelessWidget {
  final VoidCallback onTap;
  const _HomePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB347), Color(0xFFFF7AA8), Color(0xFFCB6BBA)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFF375F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

// ============================================================
// COMING SOON POPUP (slides from top)
// ============================================================

class _ComingSoonPopup extends StatefulWidget {
  final String title;
  final String message;

  const _ComingSoonPopup({required this.title, required this.message});

  @override
  State<_ComingSoonPopup> createState() => _ComingSoonPopupState();
}

class _ComingSoonPopupState extends State<_ComingSoonPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    await _slideController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeWithAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 290,
                decoration: BoxDecoration(
                  color: const Color(0x80FCFCFB),
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x20FFFFFF),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header Card with Easter Egg graphic
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Easter Egg Graphic
                                    Container(
                                      width: 98,
                                      height: 98,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 98,
                                            height: 98,
                                            decoration: BoxDecoration(),
                                            child: SvgPicture.asset(
                                              Assets.easterEgg,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // Title - iOS Settings Header style
                                    Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        widget.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Arial Rounded MT Bold',
                                          fontSize: 32, // Increased from 30
                                          letterSpacing: 0.02,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ), // Increased from 8
                                    // Message - iOS Settings style
                                    Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        widget.message,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 19, // Increased from 17
                                          height: 1.5,
                                          letterSpacing: 0.02,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20), // Increased from 12
                              // Remind Me Button
                              GestureDetector(
                                onTap: _closeWithAnimation,
                                child: Container(
                                  width: double.infinity,
                                  height: 56, // Fixed height for consistency
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFF4466),
                                        Color(0xFFF41E42),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Remind Me',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight
                                          .w500, // Increased from w400
                                      fontSize: 19, // Increased from 17
                                      letterSpacing: 0.02,
                                      color: Color(0xFFFCFCFB),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16), // Increased from 15
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
