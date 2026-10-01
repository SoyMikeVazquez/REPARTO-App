import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openWebPlatform() async {
    final uri = Uri.parse(AppConstants.repartoBaseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final courier = auth.courier;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Configuración & Cuenta',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: RepartoColors.primaryRed,
                    child: Text(
                      auth.courier.name.isNotEmpty
                          ? auth.courier.name[0]
                          : 'R',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.courier.name,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Repartidor de Comidas Autorizado',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: RepartoColors.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          auth.courier.email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? RepartoColors.darkTextMuted
                                : RepartoColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Food Delivery Courier Profile & Equipment
            Text(
              'Equipo y Vehículo de Reparto',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? RepartoColors.darkBgSecondary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: RepartoColors.primaryRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehículo Registrado',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? RepartoColors.darkTextSecondary
                                    : RepartoColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              '${courier.vehicleType.toUpperCase()} • Honda Cargo 150',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: RepartoColors.statusDeliveredBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Activo',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RepartoColors.statusDelivered,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? RepartoColors.darkBgSecondary
                              : const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.backpack_rounded,
                          color: RepartoColors.primaryRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mochila Térmica Reparto',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? RepartoColors.darkTextSecondary
                                    : RepartoColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              'Verificada para Alimentos Calientes',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RepartoColors.statusDelivered,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Business Slug & Connection
            Text(
              'Conexión a Reparto.mx',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Negocio Vinculado',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      Text(
                        '${auth.businessSlug}.reparto.mx',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RepartoColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estado del Servidor',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: RepartoColors.statusDelivered,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'En línea (18ms)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RepartoColors.statusDelivered,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tema de Interfaz',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      Switch.adaptive(
                        value: themeProv.isDarkMode,
                        activeTrackColor: RepartoColors.primaryRed,
                        onChanged: (_) => themeProv.toggleTheme(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Web Platform Button
            RepartoButton(
              label: 'Abrir Reparto.mx en Navegador',
              icon: Icons.open_in_new_rounded,
              type: RepartoButtonType.secondary,
              onPressed: _openWebPlatform,
            ),
            const SizedBox(height: 12),

            // Logout
            RepartoButton(
              label: 'Cerrar Sesión',
              icon: Icons.logout_rounded,
              type: RepartoButtonType.outline,
              customColor: RepartoColors.statusCanceled,
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'Reparto.mx Extensión Móvil • v${AppConstants.appVersion}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? RepartoColors.darkTextMuted
                      : RepartoColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
