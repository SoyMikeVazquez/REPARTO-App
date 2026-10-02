import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'courier/courier_main_screen.dart';
import 'client/client_dashboard_screen.dart';
import 'auth/pending_approval_screen.dart';
import 'auth/login_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Si NO está autenticado, la primera pantalla SIEMPRE es el Login
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Si es repartidor
    if (auth.isCourier) {
      if (auth.courierStatus == 'Confirmado') {
        return const CourierMainScreen();
      } else {
        return const PendingApprovalScreen();
      }
    }
    
    // Si es cliente autenticado, mostrar su dashboard de pedidos
    return const ClientDashboardScreen();
  }
}

