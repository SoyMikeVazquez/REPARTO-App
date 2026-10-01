import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class RepartoBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final bool showDot;

  const RepartoBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'in_route':
      case 'en ruta':
        bg = RepartoColors.statusInRouteBg;
        textColor = RepartoColors.statusInRoute;
        break;
      case 'delivered':
      case 'entregado':
        bg = RepartoColors.statusDeliveredBg;
        textColor = RepartoColors.statusDelivered;
        break;
      case 'preparing':
      case 'en preparación':
        bg = RepartoColors.statusPreparingBg;
        textColor = RepartoColors.statusPreparing;
        break;
      case 'ready':
      case 'listo':
      case 'listo para recolectar':
        bg = RepartoColors.statusReadyBg;
        textColor = RepartoColors.statusReady;
        break;
      case 'canceled':
      case 'cancelado':
        bg = RepartoColors.statusCanceledBg;
        textColor = RepartoColors.statusCanceled;
        break;
      case 'pending':
      case 'pendiente':
      default:
        bg = RepartoColors.statusPendingBg;
        textColor = RepartoColors.statusPending;
        break;
    }

    final label = customLabel ?? (AppConstants.statusNames[status] ?? status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
