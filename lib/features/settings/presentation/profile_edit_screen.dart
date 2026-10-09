import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dateOfBirth = TextEditingController();
  bool _initialized = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user =
        ref.read(currentUserProvider) ?? ref.read(profileProvider).value;
    if (user != null) {
      final parts = user.fullName.trim().split(RegExp(r'\s+'));
      _firstName.text = parts.isEmpty ? '' : parts.first;
      _lastName.text = parts.length < 2 ? '' : parts.skip(1).join(' ');
      _email.text = user.email;
      _phone.text = user.phone;
      _dateOfBirth.text = user.dateOfBirth ?? '';
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final updated = await ref
          .read(authRepositoryProvider)
          .updateProfile(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            dateOfBirth: _dateOfBirth.text.trim(),
          );
      final existing = ref.read(currentUserProvider);
      ref.read(currentUserProvider.notifier).state =
          existing?.copyWith(
            fullName: updated.fullName,
            email: updated.email,
            phone: updated.phone,
            dateOfBirth: updated.dateOfBirth,
          ) ??
          updated;
      ref.invalidate(profileProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
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
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Text(
          'Your verification status is managed separately and cannot be edited here.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: 20),
        AppInput(
          label: 'First name',
          hint: 'First name',
          controller: _firstName,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        AppInput(
          label: 'Last name',
          hint: 'Last name',
          controller: _lastName,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        AppInput(
          label: 'Email',
          hint: 'name@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AppInput(
          label: 'Phone number',
          hint: '2348103100000',
          controller: _phone,
          enabled: false,
          keyboardType: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        AppInput(
          label: 'Date of birth',
          hint: 'YYYY-MM-DD',
          controller: _dateOfBirth,
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Save changes',
          loading: _loading,
          onPressed: _save,
        ),
      ],
    ),
  );
}
