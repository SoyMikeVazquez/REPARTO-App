import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/reparto_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../orders/order_detail_screen.dart';
import '../../core/widgets/reparto_badge.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrdersProvider>(context, listen: false).fetchClientOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProv = Provider.of<OrdersProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mis Pedidos',
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProv.logout();
            },
          )
        ],
      ),
      body: ordersProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: RepartoColors.primaryRed))
          : ordersProv.orders.isEmpty
              ? Center(
                  child: Text(
                    'No tienes pedidos activos',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordersProv.orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = ordersProv.orders[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
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
                                  'Pedido #${order.id.substring(0, 8)}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${order.total.toStringAsFixed(2)} MXN',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: RepartoColors.primaryRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            RepartoBadge(status: order.status),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

