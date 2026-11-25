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
  final List<OrderModel> nearbyOrders;
  final List<RouteStopModel> stops;
  final bool isExpanded;
  final bool isFullScreen;
  final bool showOverlays;
  final bool forceDark;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onSimulateGps;
  final VoidCallback? onOpenExternalNav;
  final Function(OrderModel)? onSelectOrder;

  const MapboxDeliveryMap({
    super.key,
    required this.courierLat,
    required this.courierLng,
    this.activeOrder,
    this.nearbyOrders = const [],
    this.stops = const [],
    this.isExpanded = false,
    this.isFullScreen = false,
    this.showOverlays = true,
    this.forceDark = true,
    this.onToggleExpand,
    this.onSimulateGps,
    this.onOpenExternalNav,
    this.onSelectOrder,
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
      15.0,
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
    final mapboxStyle = (widget.forceDark || isDark) ? 'dark-v11' : 'light-v11';
    final courierPos = LatLng(widget.courierLat, widget.courierLng);

    // Coordenadas de la sucursal y destino del cliente
    final branchPos = widget.activeOrder != null
        ? LatLng(widget.activeOrder!.branchLat, widget.activeOrder!.branchLng)
        : LatLng(widget.courierLat + 0.0020, widget.courierLng + 0.0015);

    final destinationPos = widget.activeOrder != null
        ? LatLng(widget.activeOrder!.lat, widget.activeOrder!.lng)
        : LatLng(widget.courierLat + 0.0035, widget.courierLng + 0.0025);

    // Puntos de la ruta activa: Repartidor -> Sucursal (recogida) -> Cliente (entrega)
    final routePoints = <LatLng>[
      courierPos,
      if (widget.activeOrder != null) branchPos,
      destinationPos,
    ];

    final contentStack = Stack(
      children: [
        // ==========================================
        // 1. FLUTTER MAP CON TILES DE MAPBOX
        // ==========================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: courierPos,
                initialZoom: 14.6,
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
                  userAgentPackageName: 'pideloseguromx.io',
                  maxZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {},
                ),

                // Radio de Cobertura de 6 km (Radar en tiempo real)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: courierPos,
                      radius: 6000, // 6 km de radio
                      useRadiusInMeter: true,
                      color: RepartoColors.primaryRed.withValues(alpha: 0.04),
                      borderColor: RepartoColors.primaryRed.withValues(alpha: 0.22),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

                // Polyline de Ruta de Entrega si hay orden activa
                if (widget.activeOrder != null)
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

                // Marcadores: Repartidor, Destino y Pedidos Cercanos Disponibles
                MarkerLayer(
                  markers: [
                    // 1. Marcadores de la Entrega Activa (Sucursal de recogida y Destino del cliente)
                    if (widget.activeOrder != null) ...[
                      // Sucursal (Origen / Pick up)
                      Marker(
                        point: branchPos,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      // Destino (Cliente)
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
                    ],

                    // 2. Marcadores de Pedidos Cercanos Disponibles en el Radar (< 6 km)
                    for (final pendingOrder in widget.nearbyOrders)
                      Marker(
                        point: LatLng(pendingOrder.branchLat, pendingOrder.branchLng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => widget.onSelectOrder?.call(pendingOrder),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: RepartoColors.primaryRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RepartoColors.primaryRed.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: RepartoColors.statusDelivered,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white, width: 1.2),
                                  ),
                                  child: Text(
                                    '\$${pendingOrder.deliveryFee.toInt()}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 3. Marcador de Repartidor estilo Imagen 2 (Círculo amarillo con anillo oscuro y halo)
                    Marker(
                      point: courierPos,
                      width: 64,
                      height: 64,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Halo translúcido amarillo
                              Container(
                                width: 38 + (_pulseController.value * 22),
                                height: 38 + (_pulseController.value * 22),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEAB308)
                                      .withValues(alpha: 0.35 * (1 - _pulseController.value * 0.45)),
                                ),
                              ),
                              // Círculo sólido amarillo con anillo oscuro
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1E2024), width: 3.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E2024),
                                      shape: BoxShape.circle,
                                    ),
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

        if (widget.showOverlays) ...[
            // ==========================================
            // 2. OVERLAYS: RADAR / ESTADO Y CONTROLES
            // ==========================================

            // Banner Superior Dinámico (Ruta Activa o Radar de Pedidos)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: widget.activeOrder != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
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
                            padding: const EdgeInsets.all(5),
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
                                  'Hacia: ${widget.activeOrder!.deliveryAddress}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: RepartoColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Cliente: ${widget.activeOrder!.customerName} • ${widget.activeOrder!.distanceToCustomer(widget.courierLat, widget.courierLng).toStringAsFixed(1)} km',
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
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(12),
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
                          // Indicador de pulso verde de radar en vivo
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: RepartoColors.statusDelivered,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: RepartoColors.statusDelivered
                                          .withValues(alpha: 0.4 + (_pulseController.value * 0.4)),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.nearbyOrders.isNotEmpty
                                  ? 'Radar 6 km: ${widget.nearbyOrders.length} ${widget.nearbyOrders.length == 1 ? "pedido disponible" : "pedidos disponibles"}'
                                  : 'Radar 6 km activo • Buscando pedidos en tiempo real...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.nearbyOrders.isNotEmpty
                                    ? RepartoColors.statusDelivered
                                    : RepartoColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Botones de Control de Mapa (Recenter, Zoom +, Zoom -)
            Positioned(
              right: 10,
              bottom: 40,
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
          ],
        ],
      );

    if (widget.isFullScreen) {
      return contentStack;
    }

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
        child: contentStack,
      ),
    );
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 17,
              color: RepartoColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
