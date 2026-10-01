import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_badge.dart';
import '../../core/widgets/reparto_logo.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mapbox_delivery_map.dart';
import '../auth/login_screen.dart';
import 'proof_of_delivery_sheet.dart';

/// Pantalla Única para Repartidores de Comida (Estilo Minimalista Blanco Estpay).
/// Todo el flujo operativo del repartidor vive en esta única pantalla.
class CourierSingleScreen extends StatefulWidget {
  const CourierSingleScreen({super.key});

  @override
  State<CourierSingleScreen> createState() => _CourierSingleScreenState();
}

class _CourierSingleScreenState extends State<CourierSingleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey();

  bool _isMapExpanded = false;
  String? _expandedOrderId;

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String customerName, String orderId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hola $customerName, soy tu repartidor de comida de Reparto.mx con tu pedido #$orderId.',
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

  void _scrollToMap() {
    Scrollable.ensureVisible(
      _mapKey.currentContext ?? context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _openProofOfDelivery(OrderModel order) {
    final ordersProv = Provider.of<OrdersProvider>(context, listen: false);
    final routeProv = Provider.of<RouteProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofOfDeliverySheet(
        order: order,
        onConfirm: (signature, receivedBy, photo) {
          ordersProv.registerProofOfDelivery(
            orderId: order.id,
            signature: signature,
            receivedBy: receivedBy,
            photoUrl: photo,
          );
          routeProv.completeStop(2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: RepartoColors.statusDelivered,
              content: Text('¡Pedido #${order.id} entregado con éxito!'),
            ),
          );
        },
      ),
    );
  }

  void _openProfileSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    final courier = auth.courier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? RepartoColors.darkBgSecondary : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? RepartoColors.darkBorder : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: RepartoColors.primaryRed,
                      child: Text(
                        courier.name.isNotEmpty ? courier.name[0] : 'R',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courier.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Repartidor de Comida • ${courier.email}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            courier.rating.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),

                // Vehículo y Mochila
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? RepartoColors.darkCard : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? RepartoColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler_rounded,
                              color: RepartoColors.primaryRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vehículo: ${courier.vehicleType.toUpperCase()} (Honda Cargo 150)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: RepartoColors.statusDelivered, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.backpack_rounded,
                              color: RepartoColors.primaryRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mochila Térmica: Activa y verificada',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: RepartoColors.statusDelivered, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Theme switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modo Oscuro',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Switch.adaptive(
                      value: themeProv.isDarkMode,
                      activeTrackColor: RepartoColors.primaryRed,
                      onChanged: (_) {
                        themeProv.toggleTheme();
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Soporte Reparto
                RepartoButton(
                  label: 'Contactar a Soporte Reparto',
                  icon: Icons.support_agent_rounded,
                  type: RepartoButtonType.secondary,
                  onPressed: () => _openWhatsApp(
                    '5512345678',
                    'Soporte Reparto',
                    courier.id,
                  ),
                ),
                const SizedBox(height: 10),

                // Logout
                RepartoButton(
                  label: 'Cerrar Sesión',
                  icon: Icons.logout_rounded,
                  type: RepartoButtonType.outline,
                  customColor: RepartoColors.statusCanceled,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _settleCash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Liquidación de Efectivo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Deseas registrar la entrega de \$150.00 MXN en efectivo recolectado en tu sucursal o base?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RepartoColors.statusDelivered,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: RepartoColors.statusDelivered,
                  content: Text('✓ Efectivo liquidado y registrado correctamente.'),
                ),
              );
            },
            child: const Text('Confirmar Entrega'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);
    final routeProv = Provider.of<RouteProvider>(context);
    final courier = auth.courier;

    // Pedido activo en curso
    final OrderModel? activeOrder = ordersProv.orders.isEmpty
        ? null
        : ordersProv.orders.firstWhere(
            (o) => o.status == 'in_route' || o.status == 'ready',
            orElse: () => ordersProv.orders.first,
          );

    return Scaffold(
      backgroundColor: isDark ? RepartoColors.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 1. TOP HEADER (Estilo Estpay Blanco Minimal)
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? RepartoColors.darkBg : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? RepartoColors.darkBorder : const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const RepartoLogo(size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'reparto',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : RepartoColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '.mx',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: RepartoColors.primaryRed,
                    ),
                  ),
                  const Spacer(),

                  // Online / Pausa Status Chip
                  GestureDetector(
                    onTap: () => auth.toggleOnlineStatus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: auth.isOnline
                            ? (isDark ? RepartoColors.statusDeliveredBg : const Color(0xFFECFDF5))
                            : (isDark ? RepartoColors.statusCanceledBg : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: auth.isOnline
                              ? RepartoColors.statusDelivered.withValues(alpha: 0.35)
                              : RepartoColors.statusCanceled.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: auth.isOnline
                                      ? RepartoColors.statusDelivered
                                      : RepartoColors.statusCanceled,
                                  boxShadow: auth.isOnline
                                      ? [
                                          BoxShadow(
                                            color: RepartoColors.statusDelivered
                                                .withValues(alpha: 0.6),
                                            blurRadius: 4 * _pulseController.value + 2,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            auth.isOnline ? 'En línea' : 'Pausa',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: auth.isOnline
                                  ? RepartoColors.statusDelivered
                                  : RepartoColors.statusCanceled,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Profile & Settings Avatar Button
                  GestureDetector(
                    onTap: () => _openProfileSheet(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? RepartoColors.darkCardElevated : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? RepartoColors.darkBorder : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          courier.name.isNotEmpty ? courier.name[0] : 'R',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: RepartoColors.primaryRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // CONTENIDO SCROLLABLE EN UNA SOLA PANTALLA
            // ==========================================
            Expanded(
              child: RefreshIndicator(
                color: RepartoColors.primaryRed,
                onRefresh: () async {
                  await ordersProv.fetchOrders();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==========================================
                      // 2. RESUMEN DE GANANCIAS & TURNO (Estpay Strip)
                      // ==========================================
                      Row(
                        children: [
                          Expanded(
                            child: RepartoCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ganancias Hoy',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${courier.todayEarnings.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: RepartoColors.statusDelivered,
                                    ),
                                  ),
                                  Text(
                                    '+\$${courier.todayTips.toStringAsFixed(0)} propinas',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isDark
                                          ? RepartoColors.darkTextMuted
                                          : RepartoColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RepartoCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entregas',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${courier.completedToday}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'completadas',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isDark
                                          ? RepartoColors.darkTextMuted
                                          : RepartoColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RepartoCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Efectivo Cobrado',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$150',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: RepartoColors.statusPending,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _settleCash,
                                    child: Text(
                                      'Liquidar ›',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: RepartoColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ==========================================
                      // 3. TARJETA HERO: ENTREGA DE COMIDA EN CURSO
                      // ==========================================
                      if (activeOrder != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: RepartoColors.primaryRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Entrega en Curso',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? RepartoColors.darkTextPrimary
                                        : RepartoColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            RepartoBadge(
                              status: activeOrder.status,
                              customLabel: activeOrder.status == 'in_route'
                                  ? 'En Ruta al Cliente'
                                  : 'Listo para Recoger',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        RepartoCard(
                          isActive: true,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ID de Pedido y Método de Cobro
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: RepartoColors.primaryRedLight,
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
                              const SizedBox(height: 12),

                              // Cliente y Destino
                              Text(
                                activeOrder.customerName,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? RepartoColors.darkTextPrimary
                                      : RepartoColors.lightTextPrimary,
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

                              // Restaurante y Mochila Térmica
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? RepartoColors.darkBgSecondary
                                      : const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(8),
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

                              // Items del Pedido
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? RepartoColors.darkBgSecondary
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: activeOrder.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${item.quantity}x',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: RepartoColors.primaryRed,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: GoogleFonts.inter(fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            '\$${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Notas de Entrega
                              if (activeOrder.deliveryNotes != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.sticky_note_2_outlined,
                                        size: 14, color: RepartoColors.statusPending),
                                    const SizedBox(width: 6),
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
                              ],
                              const SizedBox(height: 14),

                              // Fila 1: Navegación + Contacto
                              Row(
                                children: [
                                  Expanded(
                                    child: RepartoButton(
                                      label: 'Navegar en Mapa',
                                      icon: Icons.navigation_rounded,
                                      type: RepartoButtonType.secondary,
                                      height: 42,
                                      onPressed: _scrollToMap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () => _makeCall(activeOrder.customerPhone),
                                    icon: const Icon(Icons.phone_outlined, size: 20),
                                    tooltip: 'Llamar al cliente',
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark
                                          ? RepartoColors.darkCardElevated
                                          : const Color(0xFFF1F5F9),
                                      foregroundColor: isDark
                                          ? RepartoColors.darkTextPrimary
                                          : RepartoColors.lightTextPrimary,
                                      minimumSize: const Size(42, 42),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () => _openWhatsApp(
                                      activeOrder.customerPhone,
                                      activeOrder.customerName,
                                      activeOrder.id,
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                    tooltip: 'Enviar WhatsApp',
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark
                                          ? RepartoColors.darkCardElevated
                                          : const Color(0xFFECFDF5),
                                      foregroundColor: RepartoColors.statusDelivered,
                                      minimumSize: const Size(42, 42),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Fila 2: Botón Grande de Entrega y Firma
                              RepartoButton(
                                label: 'Completar Entrega / Firma',
                                icon: Icons.check_circle_rounded,
                                height: 48,
                                width: double.infinity,
                                onPressed: () => _openProofOfDelivery(activeOrder),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: RepartoColors.statusDelivered,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Entrega en Curso',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? RepartoColors.darkTextPrimary
                                    : RepartoColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RepartoCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.delivery_dining_rounded,
                                size: 44,
                                color: RepartoColors.primaryRed,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sin entregas activas por ahora',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Permanece en línea para recibir asignaciones automáticas de restaurantes cercanos.',
                                textAlign: TextAlign.center,
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
                      const SizedBox(height: 20),

                      // ==========================================
                      // 4. MAPA GPS EN VIVO (Integrado en pantalla)
                      // ==========================================
                      Row(
                        key: _mapKey,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 18,
                                color: RepartoColors.primaryRed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ruta GPS Mapbox en Vivo',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: RepartoColors.primaryRed,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _isMapExpanded = !_isMapExpanded;
                              });
                            },
                            icon: Icon(
                              _isMapExpanded
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _isMapExpanded ? 'Reducir' : 'Expandir',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Mapa por Defecto de Mapbox
                      SizedBox(
                        height: _isMapExpanded ? 360 : 215,
                        child: MapboxDeliveryMap(
                          courierLat: routeProv.courierLat,
                          courierLng: routeProv.courierLng,
                          activeOrder: activeOrder,
                          stops: routeProv.stops,
                          isExpanded: _isMapExpanded,
                          onToggleExpand: () {
                            setState(() {
                              _isMapExpanded = !_isMapExpanded;
                            });
                          },
                          onSimulateGps: () => routeProv.simulateGpsStep(),
                          onOpenExternalNav: () {
                            if (activeOrder != null) {
                              _openExternalMap(
                                activeOrder.lat,
                                activeOrder.lng,
                                activeOrder.customerName,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sin entrega activa para navegar.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ==========================================
                      // 5. COLA DE PEDIDOS ASIGNADOS DEL TURNO
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pedidos del Turno',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? RepartoColors.darkTextPrimary
                                  : RepartoColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${ordersProv.orders.length} pedidos hoy',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? RepartoColors.darkTextMuted
                                  : RepartoColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ...ordersProv.orders.map((order) {
                        final isExpanded = _expandedOrderId == order.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RepartoCard(
                            onTap: () {
                              setState(() {
                                _expandedOrderId = isExpanded ? null : order.id;
                              });
                            },
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? RepartoColors.darkBgSecondary
                                            : const Color(0xFFFFF5F5),
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '#${order.id}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '•  ${order.branchName}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? RepartoColors.darkTextSecondary
                                                        : RepartoColors.lightTextSecondary,
                                                  ),
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
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${order.total.toStringAsFixed(0)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
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

                                // Detalles expandibles inline (sin salir de la pantalla única)
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Productos a entregar:',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...order.items.map((it) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${it.quantity}x ${it.name}',
                                              style: GoogleFonts.inter(fontSize: 12),
                                            ),
                                            Text(
                                              '\$${(it.unitPrice * it.quantity).toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                  if (order.status != 'delivered') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RepartoButton(
                                            label: 'Llamar Cliente',
                                            icon: Icons.phone_outlined,
                                            type: RepartoButtonType.secondary,
                                            height: 38,
                                            onPressed: () =>
                                                _makeCall(order.customerPhone),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RepartoButton(
                                            label: 'Entregar Pedido',
                                            icon: Icons.check_circle_outline,
                                            height: 38,
                                            onPressed: () =>
                                                _openProofOfDelivery(order),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // Footer minimalista
                      Center(
                        child: Text(
                          'Reparto.mx • App de Repartidores de Comida • v${AppConstants.appVersion}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? RepartoColors.darkTextMuted
                                : RepartoColors.lightTextMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
