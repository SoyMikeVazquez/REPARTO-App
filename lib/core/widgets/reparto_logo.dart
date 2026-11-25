import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class PideloSeguroLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const PideloSeguroLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? RepartoColors.darkTextPrimary
            : RepartoColors.lightTextPrimary);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo oficial Pidelo Seguro (insignia 3D)
          SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.22),
              child: Image.asset(
                AppConstants.appLogoAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (showText) ...[
            SizedBox(width: size * 0.28),
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: size * 0.62,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: effectiveTextColor,
                ),
                children: const [
                  TextSpan(text: 'Pidelo '),
                  TextSpan(
                    text: 'Seguro',
                    style: TextStyle(
                      color: RepartoColors.primaryRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Alias de compatibilidad
typedef RepartoLogo = PideloSeguroLogo;
