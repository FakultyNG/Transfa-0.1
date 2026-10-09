import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/transfa_logo.dart';
import '../../../shared/widgets/wallpaper_scaffold.dart';
import '../../../features/pop-ups/cashdrop_popup.dart';
import '../../../features/pop-ups/transfaAccountShare_popup.dart';

/// Frosted "Add Money" widget pair — intro card explaining the feature
/// and an account-share card with Copy/Share/CashDrop actions.
class AddMoneyScreen extends ConsumerWidget {
  const AddMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dva = ref.watch(dvaProvider);
    final account = dva.maybeWhen(
      data: (d) => d.accountNumber,
      orElse: () => '—',
    );

    return WallpaperScaffold(
      darken: 0.55,
      blur: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const _IntroWidget(),
            const SizedBox(height: 22),
            _ShareWidget(
              account: account.replaceAllMapped(
                RegExp(r'(\d{3})(\d{3})(\d{4})'),
                (m) => '${m[1]} ${m[2]} ${m[3]}',
              ),
            ),
            const Spacer(flex: 3),
            const Spacer(flex: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WALLET PILL
// ============================================================

class _WalletPill extends StatelessWidget {
  final VoidCallback onTap;
  const _WalletPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 31, 31, 31),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          Assets.transfaWallet,
          width: 35,
          height: 35,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ============================================================
// INTRO WIDGET
// ============================================================

class _IntroWidget extends StatelessWidget {
  const _IntroWidget();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 24, 26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Assets.transfaCash,
                  width: 55,
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Money',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask anyone to Transfa money to you and get it right away.',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHARE WIDGET
// ============================================================

class _ShareWidget extends StatefulWidget {
  final String account;
  const _ShareWidget({required this.account});

  @override
  State<_ShareWidget> createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<_ShareWidget> {
  bool _isCopied = false;

  void _showCashDropPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => const CashDropScreen(),
    );
  }

  void _showTransfaAccountSharePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const TransfaAccountSharePopup(),
    );
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.account.replaceAll(' ', '')));
    setState(() {
      _isCopied = true;
    });
    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.32)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: TransfaMark(size: 26, white: true)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRANSFA',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withOpacity(0.55),
                fontSize: 16,
              ),
            ),
            Text(
              widget.account,
              style: AppTypography.heading.copyWith(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Separate Copy Pill
        _CopyPill(isCopied: _isCopied, onTap: _handleCopy),
        GestureDetector(
          onTap: _showTransfaAccountSharePopup,
          child: const _ActionPill(
            label: 'Share',
            svgAsset: Assets.sharingRoundedRed,
          ),
        ),
        GestureDetector(
          onTap: _showCashDropPopup,
          child: const _ActionPill(
            label: 'CashDrop',
            svgAsset: Assets.cashDropRoundedBlue,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COPY PILL (Separate Widget)
// ============================================================

class _CopyPill extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onTap;

  const _CopyPill({required this.isCopied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: SvgPicture.asset(
                  isCopied ? Assets.copyInactive : Assets.copyActive,
                  key: ValueKey(isCopied),
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Copy',
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

// ============================================================
// ACTION PILL
// ============================================================

class _ActionPill extends StatelessWidget {
  final String label;
  final String svgAsset;
  final Color? bg;
  final VoidCallback? onTap;

  const _ActionPill({
    Key? key,
    required this.label,
    required this.svgAsset,
    this.bg,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg ?? Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              // border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Center(
              child: bg != null
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: SvgPicture.asset(svgAsset, fit: BoxFit.contain),
                    )
                  : SvgPicture.asset(
                      svgAsset,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
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
