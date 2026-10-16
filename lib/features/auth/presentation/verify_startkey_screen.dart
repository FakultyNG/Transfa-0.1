import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:transfa/core/constants/assets.dart';
import 'package:transfa/shared/widgets/animated_dotted_loader.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../pop-ups/enterCorrectCode_popup.dart';

/// "Verify Your Startkey" — three glass cards: brand header, code entry
/// with 6 underscore slots, and countdown/action cards.
class VerifyStartkeyScreen extends ConsumerStatefulWidget {
  const VerifyStartkeyScreen({super.key});

  @override
  ConsumerState<VerifyStartkeyScreen> createState() =>
      _VerifyStartkeyScreenState();
}

class _VerifyStartkeyScreenState extends ConsumerState<VerifyStartkeyScreen> {
  String _code = '';
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _showCountdownCard = true;
  bool _isVerifying = false; // Loading state for verification
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _startCountdown();

    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length <= 6) {
      setState(() {
        _code = value;
      });
      if (value.length == 6) {
        _verify();
      }
    }
    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  /// Opens the keypad reliably even if the focus node already has
  /// focus (e.g. the user swiped the keyboard away without losing
  /// focus). `requestFocus()` is a no-op when focus doesn't change,
  /// so in that case we explicitly ask the platform to show the
  /// keyboard instead.
  void _showKeypad() {
    if (_isVerifying) return;
    if (_focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } else {
      _focusNode.requestFocus();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = 60;
      _showCountdownCard = true;
      _isVerifying = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _showCountdownCard = false;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _verify() async {
    // Don't proceed if already verifying or code is not complete
    if (_isVerifying || _code.length != 6) return;

    // Start loading indicator
    setState(() {
      _isVerifying = true;
    });

    try {
      final session = ref.read(registrationSessionProvider);
      if (session?.otpReference == null) {
        throw StateError('Registration session is missing. Start again.');
      }
      final verified = await ref
          .read(authRepositoryProvider)
          .verifyOtp(
            phoneNumber: session!.phoneNumber,
            otp: _code,
            otpReference: session.otpReference!,
          );

      if (!mounted) return;

      if (!verified) {
        setState(() => _isVerifying = false);
        _showEnterCorrectCodePopup();
        return;
      }

      ref.read(registrationSessionProvider.notifier).state = session.copyWith(
        otpVerified: true,
      );

      // Navigate on success
      context.push(Routes.addBvn);
    } catch (error) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
      }
    }
  }

  void _showEnterCorrectCodePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => const EnterCorrectCodePopup(),
    );
  }

  Future<void> _resendCode() async {
    final session = ref.read(registrationSessionProvider);
    if (session?.otpReference == null) return;
    setState(() => _isVerifying = true);
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .resendOtp(
            phoneNumber: session!.phoneNumber,
            otpReference: session.otpReference!,
          );
      ref.read(registrationSessionProvider.notifier).state = session.copyWith(
        otpReference: challenge.otpReference,
      );
      if (!mounted) return;
      _startCountdown();
      setState(() {
        _code = '';
        _controller.clear();
        _isVerifying = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        ref.watch(registrationSessionProvider)?.phoneNumber ??
        ref.watch(currentUserProvider)?.phone ??
        'your phone';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _showKeypad,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top section - Brand and Enter key cards
                            Column(
                              children: [
                                GlassCard(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    28,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: SvgPicture.asset(
                                          _showCountdownCard
                                              ? Assets.transfaStartkey
                                              : Assets.passcodeBadge,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Startkey',
                                        style: AppTypography.displayMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 32,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Transfa sent your Startkey to your\nphone: $phone.',
                                        style: AppTypography.body.copyWith(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: _showKeypad,
                                  child: GlassCard(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      22,
                                      24,
                                      30,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isVerifying
                                                  ? 'Verifying...'
                                                  : 'Enter the Startkey here',
                                              style: AppTypography.subheading
                                                  .copyWith(fontSize: 19),
                                            ),
                                            const SizedBox(width: 10),
                                            // Show loader only during verification
                                            if (_isVerifying)
                                              const AnimatedDottedLoader(),
                                          ],
                                        ),
                                        const SizedBox(height: 36),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(6, (i) {
                                            final char = i < _code.length
                                                ? _code[i]
                                                : null;
                                            return _KeySlot(char: char);
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                            // Bottom section - Combined card
                            if (_showCountdownCard)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              'Code Delayed?',
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 16,
                                                letterSpacing: 0.02,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              child: SvgPicture.asset(
                                                Assets.memoReady,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            const Expanded(
                                              child: Text(
                                                'Code Sent',
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 17,
                                                  letterSpacing: 0.02,
                                                  color: Color(0xFF8A8A8C),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(_remainingSeconds),
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 17,
                                                letterSpacing: 0.02,
                                                color: Color(0xFF8A8A8C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => context.pop(),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(35),
                                                ),
                                                child: Center(
                                                  child: SvgPicture.asset(
                                                    Assets.checks,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              const Expanded(
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 17,
                                                    letterSpacing: 0.02,
                                                    color: Color(0xFFF41E42),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (!_showCountdownCard)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: GlassCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    22,
                                    22,
                                    22,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Missing the Key?',
                                        style: AppTypography.subheading
                                            .copyWith(fontSize: 19),
                                      ),
                                      const SizedBox(height: 12),
                                      _ActionRow(
                                        icon: Assets.memoReady,
                                        label: 'Send New Startkey',
                                        onTap: _resendCode,
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionRow(
                                        icon: Assets.checks,
                                        label: 'Cancel',
                                        onTap: () => context.pop(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Hidden TextField
              Container(
                height: 1,
                width: 1,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: false,
                  showCursor: false,
                  autofocus: true,
                  enabled: !_isVerifying, // Disable while verifying
                  style: const TextStyle(fontSize: 1),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onEditingComplete: () {
                    if (_code.length == 6 && !_isVerifying) {
                      _verify();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _KeySlot extends StatelessWidget {
  final String? char;
  const _KeySlot({this.char});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 36,
            child: Center(
              child: Text(
                char ?? '',
                style: AppTypography.heading.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            height: 3,
            color: Colors.black,
            margin: const EdgeInsets.only(top: 2),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final Gradient gradient = const LinearGradient(
    colors: [Color(0xFFFF7088), Color(0xFFF41E42)],
  );
  final String icon;
  final String label;
  final VoidCallback onTap;
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
              decoration: const BoxDecoration(shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w400,
                foreground: Paint()
                  ..shader = gradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 50),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
