import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:transfa/core/constants/assets.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/keypad_button.dart';
import '../../../shared/widgets/wallpaper_scaffold.dart';

/// iOS lockscreen-style passcode entry. Two steps: create, then confirm.
/// 5-digit passcode (matches the 5 dot indicators in the design).
class CreatePinRecoveryArgs {
  const CreatePinRecoveryArgs({
    required this.phoneNumber,
    required this.resetToken,
  });

  final String phoneNumber;
  final String resetToken;
}

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key, this.recovery});

  final CreatePinRecoveryArgs? recovery;

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  static const _length = 5;
  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  bool _isNavigating = false;

  void _tap(String v) async {
    if (_isNavigating) return;

    setState(() {
      if (!_confirming) {
        if (_first.length < _length) _first += v;
        if (_first.length == _length) _confirming = true;
      } else if (_confirm.length < _length) {
        _confirm += v;
      }
    });

    if (_confirming && _confirm.length == _length) {
      if (_first == _confirm) {
        _isNavigating = true;
        try {
          final recovery = widget.recovery;
          if (recovery != null) {
            final repository = ref.read(authRepositoryProvider);
            await repository.completePasscodeReset(
              resetToken: recovery.resetToken,
              newPasscode: _first,
            );
            await ref.read(sessionStoreProvider).clear();
            ref.read(currentUserProvider.notifier).state = null;
            if (!mounted) return;
            context.go(Routes.welcomeHomePhone, extra: recovery.phoneNumber);
            return;
          }
          final session = ref.read(registrationSessionProvider);
          if (session?.registrationToken == null) {
            throw StateError('Registration session expired. Start again.');
          }
          final user = await ref
              .read(authRepositoryProvider)
              .completeRegistration(
                registrationToken: session!.registrationToken!,
                passcode: _first,
              );
          await ref.read(sessionStoreProvider).markOnboardingCompleted();
          ref.read(currentUserProvider.notifier).state = user;
          ref.read(registrationSessionProvider.notifier).state = null;
          if (!mounted) return;
          context.go(Routes.welcome);
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _isNavigating = false;
            _first = '';
            _confirm = '';
            _confirming = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(userFacingError(error))));
        }
      } else {
        // mismatch — reset both, stay on create step
        setState(() {
          _first = '';
          _confirm = '';
          _confirming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Passcodes don't match. Try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _back() {
    if (_isNavigating) return;
    setState(() {
      if (_confirming && _confirm.isNotEmpty) {
        _confirm = _confirm.substring(0, _confirm.length - 1);
      } else if (_first.isNotEmpty) {
        _first = _first.substring(0, _first.length - 1);
        _confirming = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = _confirming ? _confirm.length : _first.length;
    return WallpaperScaffold(
      darken: 0.55,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SvgPicture.asset(
              Assets.locked,
              fit: BoxFit.contain,
              height: 28,
              width: 28,
            ),
            const SizedBox(height: 12),
            Text(
              _confirming
                  ? 'Confirm Your Transfa\nPasscode to Continue'
                  : 'Create Your Transfa\nPasscode to Continue',
              textAlign: TextAlign.center,
              style: AppTypography.heading.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 26),
            _Dots(length: _length, filled: filled),
            const SizedBox(height: 50),
            _Keypad(
              onTap: _tap,
              onBack: _back,
              showBack: filled > 0 || _confirming,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int length;
  final int filled;
  const _Dots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isFilled ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 1.4),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onTap;
  final VoidCallback onBack;
  final bool showBack;
  const _Keypad({
    required this.onTap,
    required this.onBack,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(['1', '2', '3'], onTap: onTap),
        const SizedBox(height: 16),
        _Row(['4', '5', '6'], onTap: onTap),
        const SizedBox(height: 16),
        _Row(['7', '8', '9'], onTap: onTap),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 78),
            KeypadButton(digit: '0', onTap: () => onTap('0')),
            SizedBox(
              width: 78,
              child: showBack
                  ? IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final List<String> keys;
  final void Function(String) onTap;
  const _Row(this.keys, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys
          .map((k) => KeypadButton(digit: k, onTap: () => onTap(k)))
          .toList(),
    );
  }
}
