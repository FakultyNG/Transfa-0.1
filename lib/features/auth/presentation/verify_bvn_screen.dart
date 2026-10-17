import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import 'verify_code_screen.dart';

/// "Verify Your BVN" — uses the CBN logo tile and BVN-specific copy.
/// Reuses [VerifyCodeScreen] for the keypad-hidden-by-default behaviour.
class VerifyBvnScreen extends StatelessWidget {
  const VerifyBvnScreen({super.key});

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
        child: Image.asset(Assets.cbnLogo, fit: BoxFit.contain),
      ),
      title: 'Verify Your BVN',
      subtitle: 'CBN sent a verification code to your\nphone: 4888.',
      onVerified: (_) async => context.push(Routes.identityVerification),
    );
  }
}
