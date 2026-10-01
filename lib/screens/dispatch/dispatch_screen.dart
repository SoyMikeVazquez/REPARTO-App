import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_button.dart';
import '../../core/widgets/reparto_badge.dart';
import '../../providers/dispatch_provider.dart';
import '../../providers/orders_provider.dart';

class DispatchScreen extends StatelessWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dispatchProv = Provider.of<DispatchProvider>(context);
    final ordersProv = Provider.of<OrdersProvider>(context);

    final readyOrders = ordersProv.orders
        .where((o) => o.status == 'ready' || o.status == 'preparing')
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Despacho & Flota',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branch Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sucursal Activa',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? RepartoColors.darkCardElevated
                        : RepartoColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? RepartoColors.darkBorder
                          : RepartoColors.lightBorder,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dispatchProv.selectedBranchId,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      dropdownColor: isDark
                          ? RepartoColors.darkCard
                          : RepartoColors.lightCard,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? RepartoColors.darkTextPrimary
                            : RepartoColors.lightTextPrimary,
                      ),
                      items: dispatchProv.branches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) dispatchProv.selectBranch(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fleet Summary Banner
            RepartoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RepartoColors.primaryRedLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.electric_moped_rounded,
                      color: RepartoColors.primaryRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dispatchProv.couriersOnlineCount} de ${dispatchProv.fleet.length} Repartidores en Servicio',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sincronizado con reparto.mx en tiempo real',
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
            const SizedBox(height: 24),

            // Orders awaiting courier assignment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedidos Listos p/ Asignar',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: RepartoColors.statusReadyBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${readyOrders.length} pendientes',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RepartoColors.statusReady,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (readyOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay pedidos pendientes de despacho.',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? RepartoColors.darkTextMuted
                          : RepartoColors.lightTextMuted,
                    ),
                  ),
                ),
              )
            else
              ...readyOrders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RepartoCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${order.id} • ${order.customerName}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            RepartoBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${order.total.toStringAsFixed(0)} MXN',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: RepartoColors.primaryRed,
                              ),
                            ),
                            RepartoButton(
                              label: 'Asignar a Flota',
                              icon: Icons.send_rounded,
                              height: 36,
                              onPressed: () {
                                _showAssignCourierDialog(
                                  context,
                                  order.id,
                                  dispatchProv,
                                  ordersProv,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Fleet Couriers List
            Text(
              'Flota de Repartidores',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            ...dispatchProv.fleet.map((courier) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RepartoCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: courier.isOnline
                            ? RepartoColors.statusDelivered.withValues(alpha: 0.2)
                            : RepartoColors.darkBorder,
                        child: Icon(
                          courier.vehicleType.contains('Bicicleta')
                              ? Icons.pedal_bike_rounded
                              : Icons.two_wheeler_rounded,
                          color: courier.isOnline
                              ? RepartoColors.statusDelivered
                              : RepartoColors.darkTextMuted,
                          size: 22,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${courier.vehicleType} • ${courier.completedToday} entregas hoy',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: courier.isOnline
                              ? RepartoColors.statusDeliveredBg
                              : RepartoColors.statusCanceledBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          courier.isOnline ? 'Disponible' : 'Desconectado',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: courier.isOnline
                                ? RepartoColors.statusDelivered
                                : RepartoColors.statusCanceled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAssignCourierDialog(
    BuildContext context,
    String orderId,
    DispatchProvider dispatchProv,
    OrdersProvider ordersProv,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Asignar Pedido #$orderId',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: dispatchProv.fleet.where((c) => c.isOnline).map((courier) {
              return ListTile(
                leading: const Icon(Icons.sports_motorsports_outlined,
                    color: RepartoColors.primaryRed),
                title: Text(courier.name),
                subtitle: Text(courier.vehicleType),
                onTap: () {
                  ordersProv.updateStatus(orderId, 'in_route');
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: RepartoColors.statusInRoute,
                      content: Text(
                          'Pedido #$orderId asignado a ${courier.name}'),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
