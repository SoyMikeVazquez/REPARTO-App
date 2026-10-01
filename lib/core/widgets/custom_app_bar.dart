import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'reparto_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showStatusSwitch;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.showStatusSwitch = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (showLogo)
            const RepartoLogo(size: 28)
          else if (title != null)
            Text(
              title!,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? RepartoColors.darkTextPrimary
                    : RepartoColors.lightTextPrimary,
              ),
            ),
          const Spacer(),
          if (showStatusSwitch && authProvider.isCourier) ...[
            GestureDetector(
              onTap: () => authProvider.toggleOnlineStatus(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: authProvider.isOnline
                      ? RepartoColors.statusDeliveredBg
                      : RepartoColors.statusCanceledBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: authProvider.isOnline
                        ? RepartoColors.statusDelivered.withValues(alpha: 0.4)
                        : RepartoColors.statusCanceled.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: authProvider.isOnline
                            ? RepartoColors.statusDelivered
                            : RepartoColors.statusCanceled,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (authProvider.isOnline
                                    ? RepartoColors.statusDelivered
                                    : RepartoColors.statusCanceled)
                                .withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      authProvider.isOnline ? 'En línea' : 'Pausa',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: authProvider.isOnline
                            ? RepartoColors.statusDelivered
                            : RepartoColors.statusCanceled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          ...?actions,
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: isDark ? RepartoColors.darkBorder : RepartoColors.lightBorder,
          height: 1.0,
        ),
      ),
    );
  }
}
