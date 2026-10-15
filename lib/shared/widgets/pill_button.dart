import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'pressable_scale.dart';

/// Rounded pill button — used as the standard CTA across the app.
/// Variants: primary (red gradient), dark, secondary (muted), orange.
enum PillVariant { primary, dark, secondary, orange }

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? leading;
  final PillVariant variant;
  final double height;
  final double? width;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.leading,
    this.variant = PillVariant.primary,
    this.height = 58,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return PressableScale(
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(height / 2),
            child: Ink(
              decoration: _decoration(),
              child: InkWell(
                borderRadius: BorderRadius.circular(height / 2),
                onTap: disabled ? null : onPressed,
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: 12),
                            ],
                            Text(label, style: _textStyle()),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    switch (variant) {
      case PillVariant.primary:
        return BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(height / 2),
          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.primary.withValues(alpha: 0.28),
          //     blurRadius: 18,
          //     offset: const Offset(0, 8),
          //   ),
          // ],
        );
      case PillVariant.dark:
        return BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(height / 2),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.20),
          //     blurRadius: 14,
          //     offset: const Offset(0, 6),
          //   ),
          // ],
        );
      case PillVariant.secondary:
        return BoxDecoration(
          color: const Color(0xFFB7B7B7),
          borderRadius: BorderRadius.circular(height / 2),
        );
      case PillVariant.orange:
        return BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(height / 2),
          // boxShadow: [
          //   BoxShadow(
          //     color: const Color(0xFFFF7A00).withValues(alpha: 0.28),
          //     blurRadius: 18,
          //     offset: const Offset(0, 8),
          //   ),
          // ],
        );
    }
  }

  TextStyle _textStyle() {
    final base = AppTypography.body.copyWith(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w500,
    );
    return base;
  }
}
