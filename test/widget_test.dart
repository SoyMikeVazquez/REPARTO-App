import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reparto_app/core/services/storage_service.dart';
import 'package:reparto_app/core/theme/app_theme.dart';
import 'package:reparto_app/providers/theme_provider.dart';
import 'package:reparto_app/providers/auth_provider.dart';
import 'package:reparto_app/providers/orders_provider.dart';
import 'package:reparto_app/providers/route_provider.dart';
import 'package:reparto_app/providers/dispatch_provider.dart';
import 'package:reparto_app/screens/main_navigation_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('Reparto Navigation Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ChangeNotifierProvider(create: (_) => RouteProvider()),
          ChangeNotifierProvider(create: (_) => DispatchProvider()),
        ],
        child: MaterialApp(
          theme: RepartoTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Entrega en Curso'), findsOneWidget);
    expect(find.text('Ruta GPS Mapbox en Vivo'), findsOneWidget);
    expect(find.text('Pedidos del Turno'), findsOneWidget);
    expect(find.text('Ganancias Hoy'), findsOneWidget);
  });
}
