import 'package:flutter/material.dart';
import 'courier/courier_single_screen.dart';

/// Punto de entrada a la experiencia de Pantalla Única para Repartidores de Comida
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourierSingleScreen();
  }
}

