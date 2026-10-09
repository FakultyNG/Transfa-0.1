import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

enum _ResetStep { phone, otp, passcode }

class PasscodeResetScreen extends ConsumerStatefulWidget {
  const PasscodeResetScreen({super.key});

  @override
  ConsumerState<PasscodeResetScreen> createState() =>
      _PasscodeResetScreenState();
}

class _PasscodeResetScreenState extends ConsumerState<PasscodeResetScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _passcode = TextEditingController();
  final _confirm = TextEditingController();
  _ResetStep _step = _ResetStep.phone;
  String? _otpReference;
  String? _resetToken;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _passcode.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _loading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      switch (_step) {
        case _ResetStep.phone:
          final challenge = await repository.requestPasscodeReset(
            _phone.text.trim(),
          );
          _otpReference = challenge.otpReference;
          _step = _ResetStep.otp;
          break;
        case _ResetStep.otp:
          _resetToken = await repository.verifyPasscodeReset(
            phoneNumber: _phone.text.trim(),
            otp: _otp.text.trim(),
            otpReference: _otpReference!,
          );
          _step = _ResetStep.passcode;
          break;
        case _ResetStep.passcode:
          if (_passcode.text != _confirm.text) {
            throw StateError('The passcodes do not match.');
          }
          await repository.completePasscodeReset(
            resetToken: _resetToken!,
            newPasscode: _passcode.text,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passcode reset successfully.')),
          );
          context.go(Routes.login);
          break;
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canContinue => switch (_step) {
    _ResetStep.phone => RegExp(r'^0?\d{10,13}$').hasMatch(_phone.text.trim()),
    _ResetStep.otp => _otp.text.length == 6,
    _ResetStep.passcode =>
      _passcode.text.length == 5 && _confirm.text.length == 5,
  };

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _ResetStep.phone => 'Reset passcode',
      _ResetStep.otp => 'Verify code',
      _ResetStep.passcode => 'New passcode',
    };
    return AppScaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Text(switch (_step) {
            _ResetStep.phone =>
              'Enter the phone number registered to your account.',
            _ResetStep.otp => 'Enter the six-digit code sent to your phone.',
            _ResetStep.passcode => 'Choose a new five-digit passcode.',
          }, style: AppTypography.bodyMuted),
          const SizedBox(height: 24),
          if (_step == _ResetStep.phone)
            AppInput(
              label: 'Phone number',
              hint: '08103100000',
              controller: _phone,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          if (_step == _ResetStep.otp)
            AppInput(
              label: 'Verification code',
              hint: '123456',
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          if (_step == _ResetStep.passcode) ...[
            AppInput(
              label: 'New passcode',
              hint: 'Five digits',
              controller: _passcode,
              obscure: true,
              keyboardType: TextInputType.number,
              maxLength: 5,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Confirm passcode',
              hint: 'Repeat passcode',
              controller: _confirm,
              obscure: true,
              keyboardType: TextInputType.number,
              maxLength: 5,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _step == _ResetStep.passcode ? 'Reset passcode' : 'Continue',
            loading: _loading,
            onPressed: _canContinue ? _continue : null,
          ),
        ],
      ),
    );
  }
}
