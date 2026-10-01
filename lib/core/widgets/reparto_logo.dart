import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RepartoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const RepartoLogo({
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Lightning bolt icon container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: RepartoColors.primaryRed,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: const [
              BoxShadow(
                color: RepartoColors.primaryRedGlow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: size * 0.75,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.35),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: size * 0.72,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: effectiveTextColor,
              ),
              children: const [
                TextSpan(text: 'Reparto'),
                TextSpan(
                  text: '.mx',
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
    );
  }
}
