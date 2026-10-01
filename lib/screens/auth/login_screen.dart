import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_logo.dart';
import '../../core/widgets/reparto_card.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'repartidor@reparto.mx');
  final _passwordController = TextEditingController(text: '••••••••');
  final _slugController = TextEditingController(text: 'demo');
  final _selectedRole = 'courier'; // Repartidor de comidas
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      slug: _slugController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: RepartoLogo(size: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Portal Repartidores',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? RepartoColors.darkTextPrimary
                            : RepartoColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'App exclusiva para repartidores de comida',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : RepartoColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? RepartoColors.darkCardElevated
                              : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: RepartoColors.primaryRed.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delivery_dining_rounded,
                              size: 16,
                              color: RepartoColors.primaryRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Entregas de Comida en Vivo',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: RepartoColors.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Business Slug Field
                    Text(
                      'Slug de Negocio / Tienda',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : RepartoColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _slugController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                        suffixText: '.reparto.mx',
                        suffixStyle: GoogleFonts.inter(
                          color: RepartoColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'tunegocio',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Text(
                      'Correo Electrónico',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : RepartoColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        hintText: 'tu@correo.com',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      'Contraseña',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? RepartoColors.darkTextSecondary
                            : RepartoColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: '••••••••',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    RepartoButton(
                      label: 'Entrar a la Plataforma',
                      icon: Icons.login_rounded,
                      isLoading: auth.isLoading,
                      onPressed: _handleLogin,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),

                    // Quick Demo Login Button
                    RepartoButton(
                      label: 'Acceso Rápido (Modo Demo)',
                      icon: Icons.flash_on_rounded,
                      type: RepartoButtonType.secondary,
                      onPressed: _handleLogin,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 28),

                    // Divider with web link
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? RepartoColors.darkBorder
                                : RepartoColors.lightBorder,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '¿Aún no tienes cuenta?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? RepartoColors.darkTextMuted
                                  : RepartoColors.lightTextMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? RepartoColors.darkBorder
                                : RepartoColors.lightBorder,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Open Web Platform Button
                    RepartoCard(
                      onTap: _openWebPlatform,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RepartoColors.primaryRedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              color: RepartoColors.primaryRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registra tu negocio en reparto.mx',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? RepartoColors.darkTextPrimary
                                        : RepartoColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Prueba gratis 14 días en la web',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? RepartoColors.darkTextSecondary
                                        : RepartoColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: RepartoColors.primaryRed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
