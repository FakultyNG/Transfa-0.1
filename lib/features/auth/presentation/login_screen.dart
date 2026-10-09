import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/api/device_identity.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _passcode = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _passcode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(_phone.text.replaceAll(' ', ''), _passcode.text);
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go(Routes.dashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _loading = true);
    try {
      final authenticated = await LocalAuthentication().authenticate(
        localizedReason: 'Log in to Transfa',
        biometricOnly: true,
      );
      if (!authenticated) return;
      final user = await ref
          .read(deviceFeaturesRepositoryProvider)
          .biometricLogin(await DeviceIdentity().getOrCreate());
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go(Routes.dashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Welcome back')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Text('Log in to continue.', style: AppTypography.bodyMuted),
          const SizedBox(height: 24),
          AppInput(
            label: 'Phone number',
            hint: '0810 310 0000',
            controller: _phone,
            keyboardType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 11,
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Passcode',
            hint: 'Your 5-digit passcode',
            controller: _passcode,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 5,
            obscure: _obscure,
            trailing: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.forgotPasscode),
              child: Text(
                'Forgot password?',
                style: AppTypography.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Log in', loading: _loading, onPressed: _submit),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _biometricLogin,
            icon: const Icon(Icons.fingerprint_rounded),
            label: const Text('Use biometrics'),
          ),
        ],
      ),
    );
  }
}
