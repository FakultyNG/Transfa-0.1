import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:ui' show ImageFilter;

import '../../../core/constants/assets.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/auth.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../features/pop-ups/transfaBankPrivacy_popup.dart';

class IdCollectScreen extends StatefulWidget {
  final WidgetBuilder iconBuilder;
  final String title;
  final String subtitle;
  final String placeholder;
  final String footerLookupLabel;
  final void Function(String enteredId) onContinue;

  const IdCollectScreen({
    super.key,
    required this.iconBuilder,
    required this.title,
    required this.subtitle,
    required this.placeholder,
    required this.footerLookupLabel,
    required this.onContinue,
  });

  @override
  State<IdCollectScreen> createState() => _IdCollectScreenState();
}

class _IdCollectScreenState extends State<IdCollectScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => TransfaBankPrivacyPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: widget.iconBuilder(context),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.title,
                        style: AppTypography.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    children: [
                      _IdField(
                        controller: _ctrl,
                        placeholder: widget.placeholder,
                      ),
                      const SizedBox(height: 14),
                      _RedContinue(
                        onTap: () {
                          final cleanId = _ctrl.text.replaceAll(
                            RegExp(r'\s'),
                            '',
                          );
                          if (cleanId.length == 11) {
                            widget.onContinue(cleanId);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _FooterPill(
                              icon: Assets.privacyHand,
                              label: 'Privacy',
                              onTap: _showPrivacy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FooterPill(
                              icon: Assets.call,
                              label: widget.footerLookupLabel,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;

  const _IdField({required this.controller, required this.placeholder});

  String _formatId(String value) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              Assets.locked,
              fit: BoxFit.contain,
              height: 20,
              width: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlignVertical: TextAlignVertical.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _IdInputFormatter(),
                ],
                style: AppTypography.subheading.copyWith(
                  fontSize: 19,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: AppTypography.subheading.copyWith(
                    fontSize: 19,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  final formatted = _formatId(value);
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
        ],
      ),
    );
  }
}

class _IdInputFormatter extends TextInputFormatter {
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

class _RedContinue extends StatelessWidget {
  final VoidCallback onTap;
  const _RedContinue({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Verify',
            style: AppTypography.subheading.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterPill extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _FooterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 240),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color.fromARGB(255, 245, 245, 245)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.subheading.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showIdVerificationPopup(
  BuildContext context, {
  required String enteredNumber,
  required VoidCallback onConfirm,
  required String idType,
  required String formattedNumber,
  BvnVerification? verification,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, _, _) => _IdVerificationModalContent(
      enteredNumber: enteredNumber,
      onConfirm: onConfirm,
      idType: idType,
      formattedNumber: formattedNumber,
      verification: verification,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0, 1);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      var fadeTween = Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: curve));
      var fadeAnimation = animation.drive(fadeTween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

class _IdVerificationModalContent extends StatelessWidget {
  final String enteredNumber;
  final VoidCallback onConfirm;
  final String idType;
  final String formattedNumber;
  final BvnVerification? verification;

  const _IdVerificationModalContent({
    required this.enteredNumber,
    required this.onConfirm,
    required this.idType,
    required this.formattedNumber,
    this.verification,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 378),
            height: 500,
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
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x20FFFFFF),
                    borderRadius: BorderRadius.circular(45),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 30,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            Assets.avatar,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          verification?.fullName.isNotEmpty == true
                              ? verification!.fullName
                              : 'Name not provided',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: const Color(0xFF1A2C3E),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_isNigerian(verification?.country))
                                SvgPicture.asset(
                                  Assets.Nigerian_Flag,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                )
                              else
                                const Icon(
                                  Icons.public,
                                  size: 24,
                                  color: Color(0xFF6B7A8A),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                verification?.country ?? 'Country not provided',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF6B7A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        _StatusSummaryCard(
                          idNumber: formattedNumber,
                          idType: idType,
                          dateOfBirth: verification?.dateOfBirth,
                        ),
                        const SizedBox(height: 20.0),
                        PillButton(
                          label: 'Continue',
                          onPressed: () => {
                            Navigator.of(context).pop(),
                            onConfirm(),
                          },
                        ),
                      ],
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

  bool _isNigerian(String? country) {
    final normalized = country?.trim().toLowerCase();
    return normalized == 'nigeria' ||
        normalized == 'nigerian' ||
        normalized == 'ng';
  }
}

class AddBvnScreen extends ConsumerWidget {
  const AddBvnScreen({super.key});

  String _formatIdNumber(String number) {
    if (number.length != 11) return number;
    return '${number.substring(0, 4)} ${number.substring(4, 8)} ${number.substring(8)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IdCollectScreen(
      iconBuilder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(Assets.cbnLogo, fit: BoxFit.contain),
      ),
      title: 'Add Your BVN',
      subtitle:
          'Earn money across Nigeria and\naccess banking & capital services.',
      placeholder: '2342 7699 875',
      footerLookupLabel: 'My BVN',
      onContinue: (enteredNumber) async {
        final session = ref.read(registrationSessionProvider);
        if (session?.registrationToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration session expired.')),
          );
          return;
        }
        try {
          final verificationFuture = ref
              .read(authRepositoryProvider)
              .verifyBvn(
                registrationToken: session!.registrationToken!,
                bvn: enteredNumber,
              );
          final cashDropConfigFuture = ref
              .read(deviceFeaturesRepositoryProvider)
              .cashDropConfig();
          final verification = await verificationFuture;
          final cashDropConfig = await cashDropConfigFuture;
          if (!verification.bvnVerified || verification.fullName.isEmpty) {
            throw StateError(
              'BVN lookup did not return the required identity details.',
            );
          }
          ref.read(registrationSessionProvider.notifier).state = session
              .copyWith(
                kycReference: verification.kycReference,
                bvnVerified: verification.bvnVerified,
                selfieCountdownEnabled: cashDropConfig.selfieCountdownEnabled,
                selfieCountdownSeconds: cashDropConfig.selfieCountdownSeconds,
                selfieMode: cashDropConfig.kycSelfieMode,
              );
          if (!context.mounted) return;
          await showIdVerificationPopup(
            context,
            enteredNumber: enteredNumber,
            formattedNumber: _formatIdNumber(enteredNumber),
            idType: 'BVN',
            verification: verification,
            onConfirm: () => context.push(
              cashDropConfig.kycSelfieRequired
                  ? Routes.identityVerification
                  : Routes.createPin,
            ),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
        }
      },
    );
  }
}

class AddNinScreen extends StatelessWidget {
  const AddNinScreen({super.key});

  String _formatIdNumber(String number) {
    if (number.length != 11) return number;
    return '${number.substring(0, 4)} ${number.substring(4, 8)} ${number.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    return IdCollectScreen(
      iconBuilder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(Assets.nimcLogo, fit: BoxFit.contain),
      ),
      title: 'Add Your NIN',
      subtitle:
          'Earn money across Nigeria and\naccess banking & capital services.',
      placeholder: '2342 7699 875',
      footerLookupLabel: 'My NIN',
      onContinue: (enteredNumber) {
        showIdVerificationPopup(
          context,
          enteredNumber: enteredNumber,
          formattedNumber: _formatIdNumber(enteredNumber),
          idType: 'NIN',
          onConfirm: () {
            context.push(Routes.identityVerification);
          },
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final bool labelBold;
  final Widget value;
  final String icon;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    this.labelBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.subheading.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: labelBold ? Colors.black : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final String idNumber;
  final String idType;
  final String? dateOfBirth;

  const _StatusSummaryCard({
    required this.idNumber,
    required this.idType,
    this.dateOfBirth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Born',
            icon: Assets.birthdayCake,
            labelBold: true,
            value: Text(
              _formatDate(dateOfBirth),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w300),
            ),
          ),
          _SummaryRow(
            label: idType,
            icon: Assets.nationalID,
            labelBold: true,
            value: Text(
              idNumber,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w300),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not provided';
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return value.trim();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}
