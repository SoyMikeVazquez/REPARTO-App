import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../providers/route_provider.dart';
import '../../providers/orders_provider.dart';
import '../../env.dart';
import 'proof_of_delivery_sheet.dart';

class ActiveRouteScreen extends StatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  State<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends State<ActiveRouteScreen> {
  final MapController _mapController = MapController();

  void _showProofOfDelivery(BuildContext context, String orderId) {
    final ordersProv = Provider.of<OrdersProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofOfDeliverySheet(
        order: ordersProv.orders.firstWhere((o) => o.id == orderId),
        onConfirm: (signature, receivedBy, photoUrl) {
          ordersProv.registerProofOfDelivery(
            orderId: orderId,
            signature: signature,
            receivedBy: receivedBy,
            photoUrl: photoUrl,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeProv = Provider.of<RouteProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);

    // Si usamos ubicación del courier
    final courierLatLng = LatLng(routeProv.courierLat, routeProv.courierLng);
    
    // Obtener las órdenes activas (en camino)
    final activeOrders = ordersProv.orders.where((o) => o.status == 'in_route' || o.status == 'en_camino').toList();
    final hasActiveOrder = activeOrders.isNotEmpty;
    final targetOrder = hasActiveOrder ? activeOrders.first : null;
    
    // Si hay pedido activo, usar su destino, de lo contrario la ruta mockeada (currentStop)
    final LatLng? targetLatLng = targetOrder != null 
        ? LatLng(targetOrder.lat, targetOrder.lng)
        : (routeProv.currentStop != null ? LatLng(routeProv.currentStop!.lat, routeProv.currentStop!.lng) : null);

    final styleUrl = isDark
        ? 'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/{z}/{x}/{y}?access_token={accessToken}'
        : 'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token={accessToken}';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ruta Optimizada',
        showLogo: false,
        actions: [
          IconButton(
            tooltip: 'Simular Avance GPS',
            icon: const Icon(Icons.speed_rounded, size: 20),
            onPressed: () {
              // Simulamos el movimiento para propósitos visuales / de desarrollo
              routeProv.simulateGpsStep(orderId: targetOrder?.id);
              _mapController.move(LatLng(routeProv.courierLat, routeProv.courierLng), _mapController.camera.zoom);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // MAPA INTERACTIVO CON MAPBOX
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courierLatLng,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: styleUrl,
                additionalOptions: {
                  'accessToken': Env.mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: [
                  // Destino del Cliente (si existe)
                  if (targetLatLng != null)
                    Marker(
                      point: targetLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on, 
                        color: Colors.blueAccent, 
                        size: 40
                      ),
                    ),
                  
                  // Marcador del Repartidor (Vehículo)
                  Marker(
                    point: courierLatLng,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: RepartoColors.primaryRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // TARJETA SUPERIOR ESTILO DIDI/UBER (Indicaciones)
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
                          targetOrder != null
                              ? 'Dirígete al punto de entrega'
                              : 'Esperando pedidos...',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          targetOrder != null
                              ? targetOrder.deliveryAddress
                              : 'No tienes rutas activas en este momento.',
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
                ],
              ),
            ),
          ),

          // BOTÓN FLOTANTE PARA CENTRAR UBICACIÓN
          Positioned(
            right: 16,
            bottom: targetOrder != null ? 140 : 30, // Sube si está la tarjeta inferior
            child: FloatingActionButton(
              heroTag: 'center_map_btn',
              onPressed: () {
                 _mapController.move(LatLng(routeProv.courierLat, routeProv.courierLng), 16.0);
              },
              backgroundColor: RepartoColors.darkCardElevated,
              foregroundColor: RepartoColors.primaryRed,
              child: const Icon(Icons.my_location),
            ),
          ),

          // TARJETA INFERIOR (Acciones de Entrega si hay pedido activo)
          if (targetOrder != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: RepartoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark
                              ? RepartoColors.darkBgSecondary
                              : Colors.grey[200],
                          radius: 20,
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                targetOrder.customerName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'A cobrar: \$${targetOrder.total.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: RepartoColors.statusReady,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                             // Acción para llamar o WhatsApp
                          },
                          icon: const Icon(Icons.phone, color: RepartoColors.primaryRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RepartoButton(
                      label: 'Registrar Entrega',
                      onPressed: () => _showProofOfDelivery(context, targetOrder.id),
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
