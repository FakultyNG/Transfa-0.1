import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Pill-shaped input per DESIGN_NOTES: 58h, 35r, 16 padding.
class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool obscure;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final TextCapitalization capitalization;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.formatters,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.capitalization = TextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 58,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            obscureText: obscure,
            validator: validator,
            onChanged: onChanged,
            maxLength: maxLength,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            textCapitalization: capitalization,
            style: AppTypography.body,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: leading,
              suffixIcon: trailing,
              filled: true,
              fillColor: AppColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: _border(AppColors.divider),
              enabledBorder: _border(AppColors.divider),
              focusedBorder: _border(AppColors.primary, width: 1.4),
              errorBorder: _border(AppColors.error),
              focusedErrorBorder: _border(AppColors.error, width: 1.4),
              disabledBorder: _border(AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(35),
        borderSide: BorderSide(color: color, width: width),
      );
}
