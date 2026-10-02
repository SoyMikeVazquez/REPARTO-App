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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa almacenamiento local persistente
  await StorageService.init();

  // Inicializa Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // anonKey está deprecado en las nuevas versiones, el correcto es publishableKey
    // aunque la librería subyacente lo puede seguir aceptando dependiendo de la subversión,
    // si el linter pide publishableKey (o el propio paquete anonKey), hay que usar anonKey si falla,
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
    MultiProvider(
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
  );
}

class RepartoApp extends StatelessWidget {
  const RepartoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Reparto.mx',
      debugShowCheckedModeBanner: false,
      theme: RepartoTheme.lightTheme,
      darkTheme: RepartoTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
