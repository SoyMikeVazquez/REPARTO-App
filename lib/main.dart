import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/route_provider.dart';
import 'providers/dispatch_provider.dart';
import 'providers/finances_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa almacenamiento local persistente
  await StorageService.init();

  // Inicializa Liquid Glass Widgets (pre-calentamiento de shaders e Impeller)
  try {
    await LiquidGlassWidgets.initialize();
  } catch (e) {
    debugPrint('LiquidGlassWidgets init fallback: $e');
  }

  // Inicializa Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Configura barra de estado del sistema transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    LiquidGlassWidgets.wrap(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ChangeNotifierProvider(create: (_) => RouteProvider()),
          ChangeNotifierProvider(create: (_) => DispatchProvider()),
          ChangeNotifierProvider(create: (_) => FinancesProvider()),
        ],
        child: const RepartoApp(),
      ),
    ),
  );
}

class PideloSeguroApp extends StatelessWidget {
  const PideloSeguroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Pidelo Seguro',
      debugShowCheckedModeBanner: false,
      theme: RepartoTheme.lightTheme,
      darkTheme: RepartoTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}

/// Alias para mantener compatibilidad
typedef RepartoApp = PideloSeguroApp;
