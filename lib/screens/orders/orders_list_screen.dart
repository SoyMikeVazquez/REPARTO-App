import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../core/widgets/reparto_badge.dart';
import '../../providers/orders_provider.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProv = Provider.of<OrdersProvider>(context);

    final filters = [
      {'key': 'all', 'label': 'Todos (${ordersProv.orders.length})'},
      {'key': 'in_route', 'label': 'En Ruta (${ordersProv.countInRoute})'},
      {'key': 'ready', 'label': 'Listos (${ordersProv.countReady})'},
      {'key': 'delivered', 'label': 'Entregados (${ordersProv.countDelivered})'},
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestión de Pedidos',
        showLogo: false,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? RepartoColors.darkBg : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? RepartoColors.darkBorder
                      : RepartoColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => ordersProv.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID, cliente o dirección...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    suffixIcon: ordersProv.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => ordersProv.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Filters List
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = ordersProv.selectedFilter == f['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            f['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? RepartoColors.darkTextSecondary
                                      : RepartoColors.lightTextSecondary),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: RepartoColors.primaryRed,
                          backgroundColor: isDark
                              ? RepartoColors.darkCard
                              : RepartoColors.lightCardElevated,
                          side: BorderSide(
                            color: isSelected
                                ? RepartoColors.primaryRed
                                : (isDark
                                    ? RepartoColors.darkBorder
                                    : RepartoColors.lightBorder),
                          ),
                          onSelected: (_) =>
                              ordersProv.setFilter(f['key'] as String),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: ordersProv.filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: isDark
                              ? RepartoColors.darkTextMuted
                              : RepartoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay pedidos en esta categoría',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? RepartoColors.darkTextSecondary
                                : RepartoColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ordersProv.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = ordersProv.filteredOrders[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepartoCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: RepartoColors.primaryRed
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${order.id}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: RepartoColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                  RepartoBadge(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Customer & Address
                              Text(
                                order.customerName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.store_outlined,
                                    size: 14,
                                    color: RepartoColors.primaryRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.branchName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: RepartoColors.statusInRoute,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: isDark
                                    ? RepartoColors.darkBorder
                                    : RepartoColors.lightBorder,
                              ),
                              const SizedBox(height: 8),

                              // Footer with Total and Payment status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.items.length} items • ${order.paymentMethod == 'cash' ? 'Efectivo' : 'En línea'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? RepartoColors.darkTextSecondary
                                          : RepartoColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '\$${order.total.toStringAsFixed(2)} MXN',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: RepartoColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
