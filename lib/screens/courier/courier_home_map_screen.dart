import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_card.dart';
import '../../providers/route_provider.dart';
import '../../providers/orders_provider.dart';
import '../../env.dart';
import 'active_route_screen.dart';

class CourierHomeMapScreen extends StatefulWidget {
  const CourierHomeMapScreen({super.key});

  @override
  State<CourierHomeMapScreen> createState() => _CourierHomeMapScreenState();
}

class _CourierHomeMapScreenState extends State<CourierHomeMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeProv = Provider.of<RouteProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);

    final courierLatLng = LatLng(routeProv.courierLat, routeProv.courierLng);

    final styleUrl = isDark
        ? 'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/{z}/{x}/{y}?access_token={accessToken}'
        : 'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token={accessToken}';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Mapa de Fondo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courierLatLng,
              initialZoom: 15.0,
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
                  // Marcador del Repartidor
                  Marker(
                    point: courierLatLng,
                    width: 48,
                    height: 48,
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
                      child: const Icon(
                        Icons.motorcycle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Marcadores de Pedidos Disponibles
                  ...ordersProv.orders.where((o) => o.status == 'listo_para_entregar').map((order) {
                    return Marker(
                      point: LatLng(order.lat, order.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          _mapController.move(LatLng(order.lat, order.lng), 16.0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: RepartoColors.statusReady,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.fastfood, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Controles Superiores (Simulación GPS y Botón Centrar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'sim_gps_home',
                  mini: true,
                  backgroundColor: isDark ? RepartoColors.darkBgSecondary : Colors.white,
                  child: Icon(Icons.speed_rounded, color: isDark ? Colors.white : Colors.black),
                  onPressed: () {
                    routeProv.simulateGpsStep();
                    _mapController.move(LatLng(routeProv.courierLat, routeProv.courierLng), _mapController.camera.zoom);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center_gps_home',
                  mini: true,
                  backgroundColor: isDark ? RepartoColors.darkBgSecondary : Colors.white,
                  child: const Icon(Icons.my_location, color: RepartoColors.primaryRed),
                  onPressed: () {
                    _mapController.move(courierLatLng, 16.0);
                  },
                ),
              ],
            ),
          ),

          // 3. Panel Inferior (Pedidos Disponibles)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: isDark ? RepartoColors.darkBg : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Pedidos Cercanos (Radio 6km)',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ordersProv.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ordersProv.orders.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay pedidos listos cerca de ti',
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: ordersProv.orders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = ordersProv.orders[index];
                                  if (order.status != 'listo_para_entregar') return const SizedBox.shrink();
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ActiveRouteScreen(),
                                        ),
                                      );
                                    },
                                    child: RepartoCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Pedido #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Cliente: ${order.customerName}',
                                                style: GoogleFonts.inter(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          const Icon(Icons.chevron_right, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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
