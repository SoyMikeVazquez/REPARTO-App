import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_colors.dart';

class RepartoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final Color? customBg;
  final double borderRadius;
  final bool isGlass;

  const RepartoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.isActive = false,
    this.customBg,
    this.borderRadius = 16.0,
    this.isGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? (isActive ? RepartoColors.darkCardElevated : RepartoColors.darkCard)
        : Colors.white;

    final borderColor = isActive
        ? RepartoColors.primaryRed.withValues(alpha: 0.6)
        : (isDark ? RepartoColors.darkBorder : const Color(0xFFE5E7EB));

    Widget content;
    if (isGlass) {
      content = GlassContainer(
        useOwnLayer: true,
        padding: padding,
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        glowIntensity: isActive ? 0.35 : 0.0,
        settings: LiquidGlassSettings(
          thickness: 20,
          blur: 14,
          glassColor: isDark
              ? const Color(0x20FFFFFF)
              : const Color(0x65FFFFFF),
        ),
        child: child,
      );
    } else {
      content = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: customBg ?? defaultBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1.0),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: RepartoColors.primaryRed.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]),
        ),
        child: child,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
