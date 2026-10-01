import '../../env.dart';

class AppConstants {
  static const String appName = 'Reparto.mx';
  static const String appTagline = 'Gestión y Optimización de Entregas';
  static const String appVersion = '1.0.0';

  // Reparto.mx Infrastructure & Services
  static const String supabaseUrl = Env.supabaseUrl;
  static const String supabaseAnonKey = Env.supabaseAnonKey;
  static const String mapboxAccessToken = Env.mapboxAccessToken;
  static const String resendFromEmail = Env.resendFromEmail;

  // Base URLs
  static const String repartoBaseUrl = 'https://reparto.mx';
  static const String repartoApiBaseUrl = 'https://reparto.mx/api/v1';

  // Storage Keys
  static const String keyAuthToken = 'reparto_auth_token';
  static const String keyUserRole = 'reparto_user_role'; // courier | dispatcher
  static const String keyBusinessSlug = 'reparto_business_slug';
  static const String keyCourierId = 'reparto_courier_id';
  static const String keyThemeMode = 'reparto_theme_mode'; // dark | light
  static const String keyIsOnline = 'reparto_courier_is_online';

  // Order Status Keys
  static const String statusPending = 'pending';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusInRoute = 'in_route';
  static const String statusDelivered = 'delivered';
  static const String statusCanceled = 'canceled';

  // Status Names in Spanish
  static const Map<String, String> statusNames = {
    statusPending: 'Pendiente',
    statusPreparing: 'En Preparación',
    statusReady: 'Listo p/ Recolectar',
    statusInRoute: 'En Ruta',
    statusDelivered: 'Entregado',
    statusCanceled: 'Cancelado',
  };

  // Payment Methods
  static const String payCash = 'cash';
  static const String payCard = 'card';
  static const String payOnline = 'online';

  static const Map<String, String> paymentMethodNames = {
    payCash: 'Efectivo',
    payCard: 'Terminal / Tarjeta',
    payOnline: 'Pagado en línea',
  };
}
