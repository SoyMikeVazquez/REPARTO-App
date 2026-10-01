import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum RepartoButtonType { primary, secondary, outline, text }

class RepartoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final RepartoButtonType type;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? customColor;

  const RepartoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = RepartoButtonType.primary,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    Widget button;

    switch (type) {
      case RepartoButtonType.primary:
        button = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (customColor ?? RepartoColors.primaryRed)
                    .withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: customColor ?? RepartoColors.primaryRed,
              foregroundColor: Colors.white,
              minimumSize: Size(width ?? 0, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: childContent,
          ),
        );
        break;

      case RepartoButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? RepartoColors.darkCardElevated
                : RepartoColors.lightCardElevated,
            foregroundColor: isDark
                ? RepartoColors.darkTextPrimary
                : RepartoColors.lightTextPrimary,
            minimumSize: Size(width ?? 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? RepartoColors.darkBorder : RepartoColors.lightBorder,
              ),
            ),
            elevation: 0,
          ),
          child: childContent,
        );
        break;

      case RepartoButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ??
                (isDark
                    ? RepartoColors.darkTextPrimary
                    : RepartoColors.lightTextPrimary),
            side: BorderSide(
              color: customColor ??
                  (isDark ? RepartoColors.darkBorder : RepartoColors.lightBorder),
            ),
            minimumSize: Size(width ?? 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: childContent,
        );
        break;

      case RepartoButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? RepartoColors.primaryRed,
            minimumSize: Size(width ?? 0, height),
          ),
          child: childContent,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
