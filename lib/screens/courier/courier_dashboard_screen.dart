import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/route_provider.dart';
import '../orders/order_detail_screen.dart';
import 'proof_of_delivery_sheet.dart';

class CourierDashboardScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const CourierDashboardScreen({super.key, this.onNavigateTab});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String customerName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hola $customerName, soy tu repartidor de Reparto.mx, voy en camino con tu pedido.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);
    final routeProv = Provider.of<RouteProvider>(context);

    final courier = auth.courier;
    final activeOrders =
        ordersProv.orders.where((o) => o.status == 'in_route').toList();
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ordersProv.fetchOrders();
          await routeProv.fetchActiveRoute();
        },
        color: RepartoColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Courier greeting & vehicle pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${courier.name}!',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? RepartoColors.darkTextPrimary
                              : RepartoColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${courier.vehicleType} • Placas ${courier.vehiclePlate}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? RepartoColors.darkTextSecondary
                              : RepartoColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? RepartoColors.darkCardElevated
                          : RepartoColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? RepartoColors.darkBorder
                            : RepartoColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          courier.rating.toStringAsFixed(2),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shift KPIs Cards
              Row(
                children: [
                  Expanded(
                    child: RepartoCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ganancias Hoy',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? RepartoColors.darkTextSecondary
                                  : RepartoColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${courier.todayEarnings.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: RepartoColors.statusDelivered,
                            ),
                          ),
                          Text(
                            '+\$${courier.todayTips.toStringAsFixed(0)} propinas',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? RepartoColors.darkTextMuted
                                  : RepartoColors.lightTextMuted,
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
                          Text(
                            'Entregas Hoy',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? RepartoColors.darkTextSecondary
                                  : RepartoColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${courier.completedToday}',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: RepartoColors.statusInRoute,
                            ),
                          ),
                          Text(
                            '${courier.totalDeliveries} históricas',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? RepartoColors.darkTextMuted
                                  : RepartoColors.lightTextMuted,
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
                          Text(
                            'Ruta Activa',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? RepartoColors.darkTextSecondary
                                  : RepartoColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${routeProv.remainingMinutes}m',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: RepartoColors.primaryRed,
                            ),
                          ),
                          Text(
                            '${routeProv.remainingDistanceKm.toStringAsFixed(1)} km rest.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? RepartoColors.darkTextMuted
                                  : RepartoColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Delivery in Progress (Hero Card)
              if (activeOrder != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entrega Prioritaria en Curso',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? RepartoColors.darkTextPrimary
                            : RepartoColors.lightTextPrimary,
                      ),
                    ),
                    const RepartoBadge(
                      status: 'in_route',
                      customLabel: 'En Ruta',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                RepartoCard(
                  isActive: true,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID & Payment indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: RepartoColors.primaryRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${activeOrder.id}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: RepartoColors.primaryRed,
                              ),
                            ),
                          ),
                          Text(
                            activeOrder.isPaid
                                ? '✓ Pagado en línea (\$${activeOrder.total.toStringAsFixed(0)})'
                                : '⚠️ Cobrar \$${activeOrder.total.toStringAsFixed(0)} en Efectivo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: activeOrder.isPaid
                                  ? RepartoColors.statusDelivered
                                  : RepartoColors.statusPending,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Customer Name & Destination
                      Text(
                        activeOrder.customerName,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? RepartoColors.darkTextPrimary
                              : RepartoColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: RepartoColors.primaryRed,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activeOrder.deliveryAddress,
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
                      const SizedBox(height: 10),

                      // Food Delivery Restaurant Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? RepartoColors.darkBgSecondary
                              : const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: RepartoColors.primaryRed.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restaurant_rounded,
                              size: 16,
                              color: RepartoColors.primaryRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Restaurante: ${activeOrder.branchName}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: RepartoColors.primaryRed,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RepartoColors.primaryRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Mochila Térmica',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (activeOrder.deliveryNotes != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? RepartoColors.darkBgSecondary
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? RepartoColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: RepartoColors.statusInRoute,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeOrder.deliveryNotes!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? RepartoColors.darkTextSecondary
                                        : RepartoColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Touch-Friendly Action Buttons (Row 1: Navigation + Contact)
                      Row(
                        children: [
                          Expanded(
                            child: RepartoButton(
                              label: 'Navegar en Mapa',
                              icon: Icons.navigation_rounded,
                              type: RepartoButtonType.secondary,
                              height: 44,
                              onPressed: () {
                                if (onNavigateTab != null) {
                                  onNavigateTab!(1); // Go to Active Route tab
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () =>
                                _makeCall(activeOrder.customerPhone),
                            icon: const Icon(Icons.phone_outlined, size: 20),
                            tooltip: 'Llamar al cliente',
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? RepartoColors.darkCardElevated
                                  : const Color(0xFFF1F5F9),
                              foregroundColor: isDark
                                  ? RepartoColors.darkTextPrimary
                                  : RepartoColors.lightTextPrimary,
                              minimumSize: const Size(44, 44),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () => _openWhatsApp(
                              activeOrder.customerPhone,
                              activeOrder.customerName,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 20),
                            tooltip: 'Enviar WhatsApp',
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? RepartoColors.darkCardElevated
                                  : const Color(0xFFECFDF5),
                              foregroundColor: RepartoColors.statusDelivered,
                              minimumSize: const Size(44, 44),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Touch-Friendly Action Buttons (Row 2: Big Primary Delivery Completion)
                      RepartoButton(
                        label: 'Completar Entrega / Firma',
                        icon: Icons.check_circle_rounded,
                        height: 48,
                        width: double.infinity,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ProofOfDeliverySheet(
                              order: activeOrder,
                              onConfirm: (signature, receivedBy, photo) {
                                ordersProv.registerProofOfDelivery(
                                  orderId: activeOrder.id,
                                  signature: signature,
                                  receivedBy: receivedBy,
                                  photoUrl: photo,
                                );
                                routeProv.completeStop(2);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        RepartoColors.statusDelivered,
                                    content: Text(
                                      '¡Pedido #${activeOrder.id} entregado con éxito!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Assigned Orders List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedidos del Turno',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? RepartoColors.darkTextPrimary
                          : RepartoColors.lightTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(2); // Go to Orders tab
                      }
                    },
                    child: Text(
                      'Ver todos (${ordersProv.orders.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RepartoColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...ordersProv.orders.take(3).map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RepartoCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? RepartoColors.darkBgSecondary
                                : RepartoColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: RepartoColors.primaryRed,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${order.id}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${order.items.length} productos',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${order.total.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RepartoBadge(
                              status: order.status,
                              showDot: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
