import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:transfa/shared/widgets/animated_dotted_loader.dart';
import 'package:transfa/shared/widgets/pressable_scale.dart';
import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/auth.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/presentation/unlock_screens.dart';
import '../../pop-ups/checkYourNumber_popup.dart';

/// "Welcome Home — Unlock with your phone" for **new users** during the
/// landing/onboarding flow. Distinct from [WelcomeHomePhoneScreen] (the
/// returning-user variant) — that one shows "Transfa Passcode" + the
/// New Transfa / Unlock with Face squares; this one shows the red
/// "Continue" pill and a privacy footer with the "See how your info is
/// managed..." link.
class RegisterPhoneScreen extends ConsumerStatefulWidget {
  const RegisterPhoneScreen({super.key});

  @override
  ConsumerState<RegisterPhoneScreen> createState() =>
      _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends ConsumerState<RegisterPhoneScreen> {
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final enteredNumber = _phone.text.replaceAll(RegExp(r'\s'), '');

    if (!RegExp(r'^0\d{10}$').hasMatch(enteredNumber)) {
      _showCheckYourNumberPopup();
      return;
    }

    setState(() => _loading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final start = await repository.startRegistration(enteredNumber);
      ref
          .read(registrationSessionProvider.notifier)
          .state = RegistrationSession(
        phoneNumber: start.phoneNumber,
        registrationToken: start.registrationToken,
        otpReference: start.otpReference,
      );
      if (mounted) context.push(Routes.verifyStartkey);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCheckYourNumberPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => const CheckYourNumberPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 28),
          child: Column(
            children: [
              _GlassWrapper(
                child: Column(
                  children: [
                    Image.asset(Assets.welcomeHome, width: 72, height: 72),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome Home',
                      style: AppTypography.subheading.copyWith(
                        color: const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Continue with your phone',
                      style: AppTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _GlassWrapper(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(height: 35),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: SizedBox(
                            width: 32,
                            height: 26,
                            child: SvgPicture.asset(
                              Assets.Nigerian_Flag,
                              width: 40,
                              height: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Nigeria',
                          style: AppTypography.subheading.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PhoneField(controller: _phone, loading: _loading),
                    const SizedBox(height: 18),
                    _RedLockPill(
                      label: _loading ? 'Please wait' : 'Continue',
                      loading: _loading,
                      onTap: _loading ? null : _handleContinue,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: SvgPicture.asset(
                        Assets.transfaYou,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'As you continue, your activity and interactions help improve the service. When you pay & receive money, we also use your history to tailor your experience.\n',
                          ),
                          TextSpan(
                            text: 'See how your info is managed…',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  context.push(Routes.privacyPolicy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassWrapper extends StatelessWidget {
  final Widget child;
  const _GlassWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 236, 236),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(8, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  const _PhoneField({required this.controller, required this.loading});

  String _formatPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 4 || i == 8) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 241, 241, 241),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,

            alignment: Alignment.center,
            child: SvgPicture.asset(Assets.phoneRound, width: 30, height: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _PhoneInputFormatter(),
                ],
                style: AppTypography.subheading.copyWith(fontSize: 17),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  final formatted = _formatPhoneNumber(value);
                  if (formatted != value) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          if (loading) const AnimatedDottedLoader(),
        ],
      ),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\s'), '');
    if (digits.length > 11) {
      final truncated = digits.substring(0, 11);
      return TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    return newValue;
  }
}

class _RedLockPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _RedLockPill({
    required this.label,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: loading ? 0.75 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4466), Color(0xFFF41E42)],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.subheading.copyWith(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
