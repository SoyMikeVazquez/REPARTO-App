import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../providers/auth_provider.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final courier = auth.courier;

    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Hoy'];
    final weekValues = [620.0, 780.0, 540.0, 920.0, 1100.0, 1250.0, 840.0];
    const maxVal = 1300.0;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Métricas & Rendimiento',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Rating & Total Earnings Hero Card
            RepartoCard(
              isActive: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Ingresos Totales de la Semana',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? RepartoColors.darkTextSecondary
                          : RepartoColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$6,050.00 MXN',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: RepartoColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+14% comparado con la semana anterior',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RepartoColors.statusDelivered,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance KPIs Grid
            Row(
              children: [
                Expanded(
                  child: RepartoCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: RepartoColors.statusInRoute,
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tiempo Promedio',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '21.4 min',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RepartoCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.speed_outlined,
                          color: RepartoColors.statusDelivered,
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Puntualidad',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '98.6%',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RepartoCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.two_wheeler_outlined,
                          color: RepartoColors.statusPending,
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Km Recorridos',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '34.8 km',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weekly Earnings Bar Chart
            RepartoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresos Diarios (Últimos 7 días)',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Custom Bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(weekDays.length, (i) {
                      final val = weekValues[i];
                      final barHeight = (val / maxVal) * 110.0;
                      final isToday = i == weekDays.length - 1;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '\$${val.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? RepartoColors.primaryRed
                                  : (isDark
                                      ? RepartoColors.darkTextMuted
                                      : RepartoColors.lightTextMuted),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 24,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? RepartoColors.primaryRed
                                  : (isDark
                                      ? RepartoColors.darkCardElevated
                                      : RepartoColors.lightCardElevated),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isToday
                                    ? RepartoColors.primaryRed
                                    : (isDark
                                        ? RepartoColors.darkBorder
                                        : RepartoColors.lightBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weekDays[i],
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday
                                  ? RepartoColors.primaryRed
                                  : (isDark
                                      ? RepartoColors.darkTextSecondary
                                      : RepartoColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Satisfaction Card
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calificación ${courier.rating.toStringAsFixed(2)} / 5.0',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Basado en 320 valoraciones de clientes en reparto.mx.',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
