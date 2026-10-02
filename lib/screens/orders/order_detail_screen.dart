import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_badge.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../courier/proof_of_delivery_sheet.dart';
import '../../env.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final MapController _mapController = MapController();

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String customerName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hola $customerName, te contacto respecto a tu pedido #${widget.order.id} de Reparto.mx.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openExternalMap(double lat, double lng, String label) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProv = Provider.of<OrdersProvider>(context);

    // Encuentra el estado más actualizado de este pedido en el provider
    final currentOrder = ordersProv.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final bool isInRoute = currentOrder.status == 'in_route' || currentOrder.status == 'en_camino';
    
    // Coordenadas de prueba por defecto si driver_current_lat es nulo en BD temporalmente
    final driverLat = 25.6866; // En BD: currentOrder.driverCurrentLat 
    final driverLng = -100.3161;
    final courierLatLng = LatLng(driverLat, driverLng);
    final styleUrl = isDark
        ? 'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/{z}/{x}/{y}?access_token={accessToken}'
        : 'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token={accessToken}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pedido #${currentOrder.id.substring(0,8)}', // Mostramos ID corto
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: RepartoBadge(status: currentOrder.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vista de Tracking en vivo si está en camino
            if (isInRoute) ...[
              RepartoCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: RepartoColors.statusInRouteBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tu pedido está en camino',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: RepartoColors.statusInRoute,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: RepartoColors.statusInRoute),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ordersProv.fetchOrders(); // Actualiza coords (Polling manual)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ubicación actualizada')),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: courierLatLng,
                            initialZoom: 14.5,
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
                                Marker(
                                  point: LatLng(currentOrder.lat, currentOrder.lng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 30),
                                ),
                                Marker(
                                  point: courierLatLng,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.two_wheeler, color: RepartoColors.primaryRed, size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status Timeline Stepper
            RepartoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado del Pedido',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildStatusStepper(currentOrder.status, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Contact & Delivery Address Card
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Datos del Cliente',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RepartoColors.statusInRouteBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PIN: ${currentOrder.deliveryPin}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: RepartoColors.statusInRoute,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentOrder.customerName,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: RepartoColors.primaryRed,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          currentOrder.deliveryAddress,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentOrder.deliveryNotes != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? RepartoColors.darkBgSecondary
                            : RepartoColors.lightCardElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 16,
                            color: RepartoColors.statusPending,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nota: ${currentOrder.deliveryNotes}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Actions: Call, WhatsApp, Open Navigation
                  Row(
                    children: [
                      Expanded(
                        child: RepartoButton(
                          label: 'Llamar',
                          icon: Icons.phone_outlined,
                          type: RepartoButtonType.secondary,
                          onPressed: () =>
                              _makeCall(currentOrder.customerPhone),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RepartoButton(
                          label: 'WhatsApp',
                          icon: Icons.chat_bubble_outline,
                          type: RepartoButtonType.secondary,
                          customColor: RepartoColors.statusDelivered,
                          onPressed: () => _openWhatsApp(
                            currentOrder.customerPhone,
                            currentOrder.customerName,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => _openExternalMap(
                          currentOrder.lat,
                          currentOrder.lng,
                          currentOrder.customerName,
                        ),
                        icon: const Icon(Icons.map_outlined, size: 20),
                        tooltip: 'Abrir en Google Maps / Waze',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Branch Details Card
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sucursal de Origen',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: RepartoColors.primaryRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: RepartoColors.primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.branchName,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              currentOrder.branchAddress,
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List Card
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos del Pedido (${currentOrder.items.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...currentOrder.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? RepartoColors.darkCardElevated
                                  : RepartoColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: RepartoColors.primaryRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.notes != null)
                                  Text(
                                    item.notes!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? RepartoColors.darkTextMuted
                                          : RepartoColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Box (Inspired by reparto.mx receipt component)
            RepartoCard(
              padding: const EdgeInsets.all(16),
              customBg: isDark
                  ? const Color(0xFF0F1424)
                  : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  _buildReceiptRow('Subtotal',
                      '\$${currentOrder.subtotal.toStringAsFixed(2)} MXN'),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Costo de Envío',
                      '\$${currentOrder.deliveryFee.toStringAsFixed(2)} MXN'),
                  const SizedBox(height: 6),
                  _buildReceiptRow(
                    'Método de Pago',
                    currentOrder.paymentMethod == 'online'
                        ? 'Pagado en Línea'
                        : 'Efectivo contra entrega',
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    color: isDark
                        ? RepartoColors.darkBorder
                        : RepartoColors.lightBorder,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a Pagar',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '\$${currentOrder.total.toStringAsFixed(2)} MXN',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: RepartoColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Proof of Delivery info or Deliver action button
            if (currentOrder.status == 'delivered') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RepartoColors.statusDeliveredBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: RepartoColors.statusDelivered.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: RepartoColors.statusDelivered,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entrega completada',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: RepartoColors.statusDelivered,
                            ),
                          ),
                          Text(
                            currentOrder.proofReceivedBy ??
                                'Recibido y validado exitosamente.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: RepartoColors.statusDelivered,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              RepartoButton(
                label: 'Completar Entrega / Prueba Digital',
                icon: Icons.check_circle_outline,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProofOfDeliverySheet(
                      order: currentOrder,
                      onConfirm: (sig, rec, photo) {
                        ordersProv.registerProofOfDelivery(
                          orderId: currentOrder.id,
                          signature: sig,
                          receivedBy: rec,
                          photoUrl: photo,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: RepartoColors.statusDelivered,
                            content: Text(
                                '¡Pedido #${currentOrder.id} entregado con éxito!'),
                          ),
                        );
                      },
                    ),
                  );
                },
                width: double.infinity,
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: RepartoColors.darkTextSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStepper(String status, bool isDark) {
    final steps = ['ready', 'in_route', 'delivered'];
    final labels = ['Listo', 'En Ruta', 'Entregado'];

    int activeIndex = 0;
    if (status == 'in_route') activeIndex = 1;
    if (status == 'delivered') activeIndex = 2;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isPast = stepIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isPast
                  ? RepartoColors.primaryRed
                  : (isDark
                      ? RepartoColors.darkBorder
                      : RepartoColors.lightBorder),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isPassed = stepIndex <= activeIndex;

        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed
                    ? RepartoColors.primaryRed
                    : (isDark
                        ? RepartoColors.darkCardElevated
                        : RepartoColors.lightCardElevated),
                border: Border.all(
                  color: isPassed
                      ? RepartoColors.primaryRed
                      : (isDark
                          ? RepartoColors.darkBorder
                          : RepartoColors.lightBorder),
                  width: 2,
                ),
              ),
              child: Center(
                child: isPassed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isPassed ? FontWeight.w700 : FontWeight.w500,
                color: isPassed
                    ? RepartoColors.primaryRed
                    : (isDark
                        ? RepartoColors.darkTextMuted
                        : RepartoColors.lightTextMuted),
              ),
            ),
          ],
        );
      }),
    );
  }
}
