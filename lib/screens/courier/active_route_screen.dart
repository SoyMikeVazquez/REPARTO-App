import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../providers/route_provider.dart';
import '../../providers/orders_provider.dart';
import 'proof_of_delivery_sheet.dart';

class ActiveRouteScreen extends StatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  State<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends State<ActiveRouteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeProv = Provider.of<RouteProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);

    final currentStop = routeProv.currentStop;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ruta Optimizada',
        showLogo: false,
        actions: [
          IconButton(
            tooltip: 'Centrar en mi ubicación',
            icon: const Icon(Icons.my_location_rounded, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('Ubicación GPS sincronizada en tiempo real.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated Interactive Map Canvas
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 2.5,
              child: CustomPaint(
                painter: RouteMapPainter(
                  isDark: isDark,
                  stops: routeProv.stops,
                  courierLat: routeProv.courierLat,
                  courierLng: routeProv.courierLng,
                  pulseValue: _pulseController.value,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Floating GPS advance simulation button
          Positioned(
            right: 16,
            top: 100,
            child: FloatingActionButton.extended(
              heroTag: 'simulate_gps_btn',
              onPressed: () => routeProv.simulateGpsStep(),
              backgroundColor: RepartoColors.darkCardElevated,
              foregroundColor: RepartoColors.statusInRoute,
              elevation: 4,
              icon: const Icon(Icons.speed_rounded, size: 20),
              label: Text(
                'Simular Avance',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Turn-by-turn Navigation Header Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: RepartoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isActive: true,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RepartoColors.primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.turn_right_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStop != null
                              ? 'En 250m gira a la derecha'
                              : 'Ruta de entregas finalizada',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          currentStop != null
                            ? 'Hacia: ${currentStop.address}'
                            : 'Todos los pedidos fueron entregados.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${routeProv.remainingMinutes} min',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: RepartoColors.primaryRed,
                        ),
                      ),
                      Text(
                        '${routeProv.remainingDistanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? RepartoColors.darkTextMuted
                              : RepartoColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Draggable Bottom Sheet with Stops List
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.22,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? RepartoColors.darkBg : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? RepartoColors.darkBorder
                              : RepartoColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paradas de la Ruta (${routeProv.stops.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: RepartoColors.statusInRouteBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Optimizado por IA',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: RepartoColors.statusInRoute,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stops timeline
                    ...routeProv.stops.map((stop) {
                      final isCurrent = !stop.isCompleted &&
                          (currentStop?.sequenceIndex == stop.sequenceIndex);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepartoCard(
                          isActive: isCurrent,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: stop.isCompleted
                                      ? RepartoColors.statusDeliveredBg
                                      : (isCurrent
                                          ? RepartoColors.primaryRed
                                          : (isDark
                                              ? RepartoColors.darkCardElevated
                                              : RepartoColors.lightCardElevated)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: stop.isCompleted
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: RepartoColors.statusDelivered,
                                          size: 18,
                                        )
                                      : Text(
                                          '${stop.sequenceIndex}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isCurrent
                                                ? Colors.white
                                                : (isDark
                                                    ? RepartoColors.darkTextPrimary
                                                    : RepartoColors.lightTextPrimary),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      stop.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? RepartoColors.darkTextSecondary
                                            : RepartoColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (stop.notes != null)
                                      Text(
                                        stop.notes!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isCurrent
                                              ? RepartoColors.primaryRed
                                              : (isDark
                                                  ? RepartoColors.darkTextMuted
                                                  : RepartoColors.lightTextMuted),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                RepartoButton(
                                  label: 'Validar',
                                  icon: Icons.check,
                                  height: 38,
                                  onPressed: () {
                                    final matchingOrder =
                                        ordersProv.orders.firstWhere(
                                      (o) => o.id == stop.orderId,
                                      orElse: () => ordersProv.orders.first,
                                    );

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => ProofOfDeliverySheet(
                                        order: matchingOrder,
                                        onConfirm: (sig, rec, photo) {
                                          ordersProv.registerProofOfDelivery(
                                            orderId: stop.orderId,
                                            signature: sig,
                                            receivedBy: rec,
                                            photoUrl: photo,
                                          );
                                          routeProv.completeStop(stop.sequenceIndex);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter que dibuja el mapa interactivo inspirado en el mockup de reparto.mx
class RouteMapPainter extends CustomPainter {
  final bool isDark;
  final List<dynamic> stops;
  final double courierLat;
  final double courierLng;
  final double pulseValue;

  RouteMapPainter({
    required this.isDark,
    required this.stops,
    required this.courierLat,
    required this.courierLng,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0B101E) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Dibuja las avenidas y calles
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF19233C) : const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadSecondary = Paint()
      ..color = isDark ? const Color(0xFF131A2B) : const Color(0xFFEBEFF5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Grid de calles
    for (double x = 40; x < size.width + 100; x += 90) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 60; y < size.height + 100; y += 90) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Calles diagonales
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.7),
      roadSecondary,
    );

    // Coordenadas simuladas para waypoints
    final p0 = Offset(size.width * 0.35, size.height * 0.45); // Origen
    final p1 = Offset(size.width * 0.55, size.height * 0.35); // Stop 1
    final p2 = Offset(size.width * 0.72, size.height * 0.58); // Stop 2

    // Ruta Polyline roja con glow
    final glowPathPaint = Paint()
      ..color = RepartoColors.primaryRed.withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePathPaint = Paint()
      ..color = RepartoColors.primaryRed
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(path, glowPathPaint);
    canvas.drawPath(path, routePathPaint);

    // Waypoint Markers
    _drawMarker(canvas, p0, '🏪', 'Sucursal', isDark);
    _drawMarker(canvas, p1, '1', 'Mariana', isDark, isSelected: true);
    _drawMarker(canvas, p2, '2', 'Roberto', isDark);

    // Courier Moto Marker (Animated live pulse)
    final courierPos = Offset(
      p0.dx + (p1.dx - p0.dx) * 0.6,
      p0.dy,
    );

    final pulseRadius = 14 + (pulseValue * 8);
    final pulsePaint = Paint()
      ..color = RepartoColors.statusInRoute
          .withValues(alpha: 0.4 * (1 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(courierPos, pulseRadius, pulsePaint);

    final courierCircle = Paint()..color = RepartoColors.statusInRoute;
    canvas.drawCircle(courierPos, 12, courierCircle);

    final courierInner = Paint()..color = Colors.white;
    canvas.drawCircle(courierPos, 5, courierInner);
  }

  void _drawMarker(
    Canvas canvas,
    Offset position,
    String label,
    String title,
    bool isDark, {
    bool isSelected = false,
  }) {
    final markerPaint = Paint()
      ..color = isSelected ? RepartoColors.primaryRed : const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 14, markerPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 14, borderPaint);

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(RouteMapPainter oldDelegate) => true;
}
