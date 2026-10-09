import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureA = true, _obscureB = true, _obscureC = true;
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPassword.text.length != 5 || _current.text.length != 5) {
      _snack('Passcodes must contain 5 digits.');
      return;
    }
    if (_newPassword.text != _confirm.text) {
      _snack('Passwords don\'t match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePasscode(
            oldPasscode: _current.text,
            newPasscode: _newPassword.text,
          );
      if (!mounted) return;
      _snack('Passcode updated');
      context.pop();
    } catch (error) {
      if (mounted) _snack(userFacingError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Widget _eye(bool obscure, VoidCallback onTap) => IconButton(
    onPressed: onTap,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: AppColors.textMuted,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Change passcode')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Text(
            'Choose a new 5-digit Transfa passcode.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 24),
          AppInput(
            label: 'Current passcode',
            controller: _current,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 5,
            obscure: _obscureA,
            trailing: _eye(
              _obscureA,
              () => setState(() => _obscureA = !_obscureA),
            ),
          ),
          const SizedBox(height: 12),
          AppInput(
            label: 'New passcode',
            controller: _newPassword,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 5,
            obscure: _obscureB,
            trailing: _eye(
              _obscureB,
              () => setState(() => _obscureB = !_obscureB),
            ),
          ),
          const SizedBox(height: 12),
          AppInput(
            label: 'Confirm new passcode',
            controller: _confirm,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 5,
            obscure: _obscureC,
            trailing: _eye(
              _obscureC,
              () => setState(() => _obscureC = !_obscureC),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Update passcode',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
