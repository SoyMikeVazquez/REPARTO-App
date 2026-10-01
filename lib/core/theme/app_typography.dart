import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía inspirada en la web de reparto.mx
/// Headings: Outfit
/// Body text: Inter
class RepartoTypography {
  // Headings (Outfit)
  static TextStyle headingHero({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle heading1({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle heading2({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle heading3({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle heading4({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body Texts (Inter)
  static TextStyle bodyLarge({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color color = RepartoColors.darkTextPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle bodySmall({Color color = RepartoColors.darkTextSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle label({Color color = RepartoColors.darkTextSecondary}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );
}
