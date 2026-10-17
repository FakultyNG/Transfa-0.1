import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/repositories/repositories.dart';
import 'verify_code_screen.dart';

class NinOtpArgs {
  const NinOtpArgs({required this.otpReference, required this.maskedPhone});

  final String otpReference;
  final String maskedPhone;
}

class VerifyNinScreen extends ConsumerStatefulWidget {
  const VerifyNinScreen({super.key, required this.args});

  final NinOtpArgs args;

  @override
  ConsumerState<VerifyNinScreen> createState() => _VerifyNinScreenState();
}

class _VerifyNinScreenState extends ConsumerState<VerifyNinScreen> {
  late String _otpReference = widget.args.otpReference;
  late String _maskedPhone = widget.args.maskedPhone;

  Future<void> _confirm(String otp) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmNinOtp(otpReference: _otpReference, otp: otp);
      ref.invalidate(profileProvider);
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted && _supportRequired(error)) {
        context.go(
          Routes.supportChat,
          extra: 'I need help upgrading my limit to captain tier',
        );
      }
      rethrow;
    }
  }

  Future<void> _resend() async {
    final result = await ref
        .read(authRepositoryProvider)
        .resendNinOtp(_otpReference);
    if (!mounted) return;
    setState(() {
      _otpReference = result['otpReference']?.toString() ?? _otpReference;
      _maskedPhone = result['maskedPhone']?.toString() ?? _maskedPhone;
    });
  }

  bool _supportRequired(Object error) {
    if (error is! ApiException || error.details is! Map) return false;
    return (error.details as Map)['supportRequired'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return VerifyCodeScreen(
      icon: Container(
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
        padding: const EdgeInsets.all(6),
        child: Image.asset(Assets.nimcLogo, fit: BoxFit.contain),
      ),
      title: 'Verify Your NIN',
      subtitle: 'A verification code was sent to\nyour phone: $_maskedPhone.',
      onVerified: _confirm,
      onResend: _resend,
    );
  }
}
