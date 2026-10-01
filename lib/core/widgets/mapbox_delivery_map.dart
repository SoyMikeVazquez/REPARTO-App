import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../env.dart';
import '../../models/order_model.dart';
import '../../models/route_stop_model.dart';

/// Mapa de navegación interactivo oficial de Reparto.mx potenciado por Mapbox.
/// Utiliza los estilos oficiales de Mapbox (light-v11 y dark-v11) con el token de acceso configurado.
class MapboxDeliveryMap extends StatefulWidget {
  final double courierLat;
  final double courierLng;
  final OrderModel? activeOrder;
  final List<RouteStopModel> stops;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onSimulateGps;
  final VoidCallback? onOpenExternalNav;

  const MapboxDeliveryMap({
    super.key,
    required this.courierLat,
    required this.courierLng,
    this.activeOrder,
    this.stops = const [],
    this.isExpanded = false,
    this.onToggleExpand,
    this.onSimulateGps,
    this.onOpenExternalNav,
  });

  @override
  State<MapboxDeliveryMap> createState() => _MapboxDeliveryMapState();
}

class _MapboxDeliveryMapState extends State<MapboxDeliveryMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MapboxDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courierLat != widget.courierLat ||
        oldWidget.courierLng != widget.courierLng) {
      // Mueve suavemente la cámara siguiendo al repartidor
      _mapController.move(
        LatLng(widget.courierLat, widget.courierLng),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _recenterOnCourier() {
    _mapController.move(
      LatLng(widget.courierLat, widget.courierLng),
      15.5,
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapboxStyle = isDark ? 'dark-v11' : 'light-v11';
    final courierPos = LatLng(widget.courierLat, widget.courierLng);

    // Coordenadas del destino (cliente o restaurante)
    final destinationPos = widget.activeOrder != null
        ? LatLng(widget.activeOrder!.lat, widget.activeOrder!.lng)
        : LatLng(19.4185, -99.1620);

    // Puntos de la ruta
    final routePoints = <LatLng>[
      courierPos,
      LatLng(
        (courierPos.latitude + destinationPos.latitude) / 2 + 0.001,
        (courierPos.longitude + destinationPos.longitude) / 2 - 0.001,
      ),
      destinationPos,
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RepartoColors.darkBgSecondary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? RepartoColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ==========================================
            // 1. FLUTTER MAP POWERED BY MAPBOX TILES
            // ==========================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: courierPos,
                initialZoom: 15.0,
                minZoom: 10.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Mapbox Vector Raster Tile Layer
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/$mapboxStyle/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                  additionalOptions: const {
                    'accessToken': Env.mapboxAccessToken,
                  },
                  userAgentPackageName: 'mx.reparto.app',
                  maxZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {
                    // Silently fall back gracefully when offline or in automated test
                  },
                ),

                // Polyline de Ruta de Entrega (Rojo Reparto con Glow)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 8.0,
                      color: RepartoColors.primaryRed.withValues(alpha: 0.25),
                    ),
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: RepartoColors.primaryRed,
                    ),
                  ],
                ),

                // Marcadores: Repartidor en Moto y Destino del Cliente
                MarkerLayer(
                  markers: [
                    // Marcador de Destino del Cliente
                    Marker(
                      point: destinationPos,
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: RepartoColors.statusDelivered,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Marcador de Repartidor en Moto con Pulso Animado
                    Marker(
                      point: courierPos,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Halo pulsante
                              Container(
                                width: 28 + (_pulseController.value * 22),
                                height: 28 + (_pulseController.value * 22),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: RepartoColors.primaryRed
                                      .withValues(alpha: 0.25 * (1 - _pulseController.value)),
                                ),
                              ),
                              // Círculo sólido
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: RepartoColors.primaryRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RepartoColors.primaryRed.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.two_wheeler_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ==========================================
            // 2. OVERLAYS: DESTINO Y BADGE DE MAPBOX
            // ==========================================

            // Destino Banner Superior
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: RepartoColors.primaryRedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.turn_right_rounded,
                        color: RepartoColors.primaryRed,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.activeOrder != null
                                ? 'Hacia: ${widget.activeOrder!.deliveryAddress}'
                                : 'Esperando asignación de ruta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: RepartoColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            widget.activeOrder != null
                                ? 'Cliente: ${widget.activeOrder!.customerName} • 1.8 km (~6 min)'
                                : 'Ruta en espera',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: RepartoColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones de Control de Mapa (Recenter, Zoom +, Zoom -)
            Positioned(
              right: 10,
              bottom: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapCircleButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Centrar en mi ubicación',
                    onTap: _recenterOnCourier,
                  ),
                  const SizedBox(height: 6),
                  _buildMapCircleButton(
                    icon: Icons.add,
                    tooltip: 'Acercar',
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 6),
                  _buildMapCircleButton(
                    icon: Icons.remove,
                    tooltip: 'Alejar',
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),

            // Watermark Oficial de Mapbox (Abajo a la izquierda)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'mapbox',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      ' | © OSM',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones inferiores de acción (Simular GPS y Google Maps/Waze)
            Positioned(
              bottom: 8,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onSimulateGps != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: RepartoColors.lightTextPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onPressed: widget.onSimulateGps,
                      icon: const Icon(
                        Icons.fast_forward_rounded,
                        size: 14,
                        color: RepartoColors.primaryRed,
                      ),
                      label: Text(
                        'Simular GPS',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (widget.onOpenExternalNav != null) ...[
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RepartoColors.primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.onOpenExternalNav,
                      icon: const Icon(Icons.navigation_rounded, size: 13, color: Colors.white),
                      label: Text(
                        'Navegar',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
