import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import 'reparto_button.dart';

class AuthErrorInfo {
  final String title;
  final String message;
  final IconData icon;

  const AuthErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
  });
}

class AuthErrorHelper {
  /// Traduce cualquier error técnico o excepción de Supabase/red a un mensaje claro y amigable
  static AuthErrorInfo parse(dynamic error) {
    if (error == null) {
      return const AuthErrorInfo(
        title: 'Error Inesperado',
        message: 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.',
        icon: Icons.error_outline_rounded,
      );
    }

    // Si es un AuthException de Supabase
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = error.statusCode?.toLowerCase() ?? '';

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          msg.contains('invalid_grant')) {
        return const AuthErrorInfo(
          title: 'Credenciales Incorrectas',
          message:
              'El correo electrónico o la contraseña ingresados no coinciden con nuestros registros. Verifica tus datos e inténtalo de nuevo.',
          icon: Icons.lock_reset_rounded,
        );
      }

      if (msg.contains('email not confirmed') ||
          msg.contains('email_not_confirmed')) {
        return const AuthErrorInfo(
          title: 'Correo No Confirmado',
          message:
              'Tu correo electrónico aún no ha sido confirmado. Revisa tu bandeja de entrada o carpeta de spam para verificar tu cuenta.',
          icon: Icons.mark_email_unread_rounded,
        );
      }

      if (msg.contains('user not found') || msg.contains('user_not_found')) {
        return const AuthErrorInfo(
          title: 'Cuenta No Encontrada',
          message:
              'No encontramos ninguna cuenta registrada con este correo electrónico.',
          icon: Icons.person_search_rounded,
        );
      }

      if (msg.contains('over_request_rate_limit') ||
          msg.contains('over_email_send_rate_limit') ||
          msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        return const AuthErrorInfo(
          title: 'Demasiados Intentos',
          message:
              'Has realizado demasiadas solicitudes en poco tiempo. Por seguridad, espera 2 minutos antes de intentarlo de nuevo.',
          icon: Icons.hourglass_empty_rounded,
        );
      }

      if (code == 'otp_expired' ||
          msg.contains('token has expired') ||
          msg.contains('otp expired')) {
        return const AuthErrorInfo(
          title: 'Código Expirado',
          message:
              'El código de verificación ha expirado. Por favor solicita uno nuevo.',
          icon: Icons.timer_outlined,
        );
      }

      if (msg.contains('invalid token') ||
          msg.contains('invalid otp') ||
          msg.contains('token is invalid')) {
        return const AuthErrorInfo(
          title: 'Código Incorrecto',
          message:
              'El código ingresado no es válido. Revisa el SMS e intenta nuevamente.',
          icon: Icons.pin_outlined,
        );
      }

      if (msg.contains('password') && msg.contains('least')) {
        return const AuthErrorInfo(
          title: 'Contraseña Débil',
          message: 'La contraseña debe tener al menos 6 caracteres.',
          icon: Icons.security_rounded,
        );
      }

      return AuthErrorInfo(
        title: 'Error de Autenticación',
        message: error.message,
        icon: Icons.shield_outlined,
      );
    }

    final rawStr = error.toString().toLowerCase();

    // 1. Errores de Red / Socket / Sandbox macOS / Conexión denegada
    if (rawStr.contains('socketconnection failed') ||
        rawStr.contains('socketexception') ||
        rawStr.contains('operation not permitted') ||
        rawStr.contains('failed host lookup') ||
        rawStr.contains('connection refused') ||
        rawStr.contains('connection reset') ||
        rawStr.contains('network is unreachable') ||
        rawStr.contains('clientexception')) {
      return const AuthErrorInfo(
        title: 'Error de Conexión',
        message:
            'No se pudo conectar con el servidor. Revisa tu conexión a internet o verifica los permisos de red del sistema.',
        icon: Icons.wifi_off_rounded,
      );
    }

    // 2. Repartidor no encontrado en tabla 'repartidores'
    if (rawStr.contains('no está registrada en la tabla de "repartidores"') ||
        rawStr.contains('tabla de repartidores') ||
        rawStr.contains('no está registrado como repartidor') ||
        rawStr.contains('cuenta no registrada en la base de datos')) {
      return const AuthErrorInfo(
        title: 'Repartidor No Registrado',
        message:
            'No existe un registro de repartidor vinculado a esta cuenta. Si eres nuevo, puedes solicitar tu alta con el botón "Solicitar Registro".',
        icon: Icons.two_wheeler_rounded,
      );
    }

    // 3. Estatus de cuenta
    if (rawStr.contains('pendiente')) {
      return const AuthErrorInfo(
        title: 'Solicitud en Revisión',
        message:
            'Tu solicitud de repartidor sigue en proceso de validación. Te avisaremos en cuanto tu cuenta esté aprobada.',
        icon: Icons.hourglass_top_rounded,
      );
    }

    if (rawStr.contains('rechazad') ||
        rawStr.contains('suspendid') ||
        rawStr.contains('inactiv')) {
      return const AuthErrorInfo(
        title: 'Cuenta Inactiva',
        message:
            'Tu cuenta de repartidor no se encuentra activa en este momento. Por favor comunícate con el administrador o soporte.',
        icon: Icons.block_rounded,
      );
    }

    // 4. Credenciales
    if (rawStr.contains('invalid login credentials') ||
        rawStr.contains('credenciales incorrectas') ||
        rawStr.contains('contraseña incorrecta')) {
      return const AuthErrorInfo(
        title: 'Credenciales Incorrectas',
        message:
            'El correo electrónico o la contraseña ingresados son incorrectos. Por favor, verifica tus datos e inténtalo de nuevo.',
        icon: Icons.lock_reset_rounded,
      );
    }

    // Limpieza de texto de excepción técnica
    String cleanMsg = error.toString();
    cleanMsg = cleanMsg.replaceAll('Exception: ', '');
    cleanMsg = cleanMsg.replaceAll('AuthException: ', '');
    cleanMsg = cleanMsg.replaceAll('ClientException: ', '');

    return AuthErrorInfo(
      title: 'Aviso de Acceso',
      message: cleanMsg,
      icon: Icons.info_outline_rounded,
    );
  }

  /// Despliega un Pop-up modal moderno con diseño estilo Reparto.mx
  static Future<void> showErrorPopup(
    BuildContext context,
    dynamic error, {
    VoidCallback? onDismiss,
  }) async {
    final info = parse(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 20,
          backgroundColor: isDark ? RepartoColors.darkCard : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono decorado con fondo circular
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: RepartoColors.primaryRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RepartoColors.primaryRed.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        info.icon,
                        size: 32,
                        color: RepartoColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Título amigable en español
                  Text(
                    info.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark
                          ? RepartoColors.darkTextPrimary
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mensaje detallado traducido
                  Text(
                    info.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark
                          ? RepartoColors.darkTextSecondary
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Entendido
                  RepartoButton(
                    label: 'Entendido',
                    width: double.infinity,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (onDismiss != null) onDismiss();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
