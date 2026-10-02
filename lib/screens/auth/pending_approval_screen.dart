import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_button.dart';
import '../../providers/auth_provider.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: RepartoColors.primaryRed.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Solicitud en Revisión',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hemos recibido tu solicitud para ser repartidor.\nNuestro equipo está validando tus datos y documentos. Te notificaremos cuando tu cuenta esté "Confirmada".',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              RepartoButton(
                label: 'Cerrar Sesión',
                type: RepartoButtonType.secondary,
                onPressed: () {
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
