import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../metrics/metrics_screen.dart';
import 'courier_home_map_screen.dart';

class CourierMainScreen extends StatefulWidget {
  const CourierMainScreen({super.key});

  @override
  State<CourierMainScreen> createState() => _CourierMainScreenState();
}

class _CourierMainScreenState extends State<CourierMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      // 0: Mapa y Pedidos (Home)
      const CourierHomeMapScreen(),
      // 1: Historial
      const Center(child: Text("Historial de Pedidos")),
      // 2: Finanzas
      const MetricsScreen(),
      // 3: Perfil
      const Center(child: Text("Perfil del Repartidor")),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? RepartoColors.darkBgSecondary : Colors.white,
        selectedItemColor: RepartoColors.primaryRed,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

