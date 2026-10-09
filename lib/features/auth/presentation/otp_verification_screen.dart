import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  bool _loading = false;

  Future<void> _verify() async {
    setState(() => _loading = true);
    final session = ref.read(registrationSessionProvider);
    if (session?.otpReference == null) {
      setState(() => _loading = false);
      return;
    }
    final ok = await ref
        .read(authRepositoryProvider)
        .verifyOtp(
          phoneNumber: session!.phoneNumber,
          otp: _otp,
          otpReference: session.otpReference!,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.push(Routes.createPin);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid code. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        ref.watch(registrationSessionProvider)?.phoneNumber ?? 'your phone';
    return AppScaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Verify your code', style: AppTypography.headingLarge),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to $phone.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 32),
          PinCodeTextField(
            appContext: context,
            length: 6,
            animationType: AnimationType.fade,
            keyboardType: TextInputType.number,
            cursorColor: AppColors.primary,
            textStyle: AppTypography.subheading,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(16),
              fieldHeight: 56,
              fieldWidth: 46,
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary,
              inactiveColor: AppColors.divider,
              activeFillColor: AppColors.surface,
              selectedFillColor: AppColors.surface,
              inactiveFillColor: AppColors.surfaceMuted,
            ),
            enableActiveFill: true,
            onChanged: (v) => setState(() => _otp = v),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                "Didn't receive it? Resend",
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Verify',
            loading: _loading,
            onPressed: _otp.length == 6 ? _verify : null,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
