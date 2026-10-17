import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Reusable "Verify Your XXX" code-entry screen used by both NIN (NIMC
/// logo) and BVN (CBN logo) flows.
///
/// Layout:
///   • Header card with a square white-tile icon + bold title + subtitle.
///   • Code card with "Enter the code here" prompt + 6 underscore slots.
///     Tapping the slots focuses a hidden numeric TextField, which opens
///     the platform soft keyboard. As the user types, the slots fill.
///   • "Code Delayed?" footer card with Send New Code + Cancel actions.
class VerifyCodeScreen extends StatefulWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String initialCode;
  final int length;
  final Future<void> Function(String code) onVerified;
  final Future<void> Function()? onResend;

  const VerifyCodeScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onVerified,
    this.onResend,
    this.initialCode = '',
    this.length = 6,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialCode,
  );
  final FocusNode _focus = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() {});
    if (_ctrl.text.length == widget.length && !_submitting) {
      // Defer briefly so the last digit renders before we navigate.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _ctrl.text.length == widget.length) _submit();
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onVerified(_ctrl.text);
    } catch (error) {
      if (!mounted) return;
      _ctrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (_submitting || widget.onResend == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onResend!();
      _ctrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new verification code was sent.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showKeyboard() {
    if (!_focus.hasFocus) {
      FocusScope.of(context).requestFocus(_focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 32),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 60, height: 60, child: widget.icon),
                          const SizedBox(height: 18),
                          Text(
                            widget.title,
                            style: AppTypography.displayMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            style: AppTypography.body.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showKeyboard,
                      behavior: HitTestBehavior.opaque,
                      child: GlassCard(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                        child: Column(
                          children: [
                            Text(
                              'Enter the code here',
                              style: AppTypography.subheading.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(widget.length, (i) {
                                final char = i < _ctrl.text.length
                                    ? _ctrl.text[i]
                                    : null;
                                return _CodeSlot(char: char);
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code Delayed?',
                            style: AppTypography.subheading.copyWith(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionRow(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Send New Code',
                            onTap: widget.onResend == null ? null : _resend,
                          ),
                          const SizedBox(height: 10),
                          _ActionRow(
                            icon: Icons.close_rounded,
                            label: 'Cancel',
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Off-screen numeric TextField — invisible but real, so the
              // platform soft keyboard opens when it gains focus. The
              // controller listener mirrors typed digits into the slot row.
              Positioned(
                left: 0,
                right: 0,
                bottom: -100,
                child: SizedBox(
                  height: 1,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    showCursor: false,
                    maxLength: widget.length,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    style: const TextStyle(
                      color: Colors.transparent,
                      height: 0,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeSlot extends StatelessWidget {
  final String? char;
  const _CodeSlot({this.char});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                char ?? '',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 2),
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
