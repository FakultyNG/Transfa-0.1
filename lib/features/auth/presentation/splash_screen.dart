import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/transfa_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    setState(() => _error = null);
    try {
      final restoration = ref.read(sessionRestorationProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final user = await restoration;
      if (!mounted) return;
      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go(Routes.unlockPasscode, extra: user.phone);
      } else {
        final knownPhone = await ref
            .read(sessionStoreProvider)
            .readLastPhoneNumber();
        if (!mounted) return;
        context.go(
          knownPhone == null || knownPhone.isEmpty
              ? Routes.welcomeIntro
              : Routes.welcomeHomePhone,
          extra: knownPhone,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userFacingError(error));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween(begin: 0.88, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: const TransfaLogo(size: 240),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _restore,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
