# Reparto.mx - Aplicación Móvil (Extensión Oficial)

<p align="center">
  <img src="assets/images/reparto_logo.png" width="90" alt="Reparto.mx Logo" />
</p>

Aplicación móvil desarrollada en **Flutter** para la plataforma [Reparto.mx](https://reparto.mx), diseñada como la extensión operativa en tiempo real para **repartidores en campo** y **despachadores de sucursales**.

---

## 🎨 Sistema de Diseño (Inspirado en reparto.mx)

La aplicación implementa fielmente la identidad visual de la web oficial de reparto.mx:

- **Colores de Marca:**
  - Rojo Principal: `#E53E3E` (hover `#C53030`, fondo suave `#FFF5F5`, glow `#E53E3E40`)
  - Modo Oscuro: Fondos `#090A0F` / `#0B0F19`, tarjetas `#12131A`, bordes `#FFFFFF14`
  - Modo Claro: Fondos `#FFFFFF`, tarjetas `#F8FAFC`, bordes `#E2E8F0`
- **Estatus Operativos:**
  - 🔵 **En Ruta:** `#38BDF8` (Sky blue)
  - 🟢 **Entregado:** `#10B981` (Mint / Emerald)
  - 🟡 **Pendiente / Preparando:** `#F59E0B` (Amber)
  - 🔴 **Incidencias / Cancelado:** `#EF4444` (Coral red)
- **Tipografía Oficial:**
  - **Titulares y Botones:** `Outfit` (Bold / Extrabold)
  - **Cuerpo y Datos:** `Inter` (Regular / Medium / Semi-bold)
- **Logotipo Oficial:** Rayo energético con punto rojo corporativo (`Reparto.mx`).

---

## 🚀 Características Principales

### 🛵 Modo Repartidor (Courier en Campo)
1. **Control de Turno:**
   - Switch de conexión en tiempo real ("En línea" / "Pausado").
   - Telemetría en background sincronizada con los servidores de reparto.mx.
2. **Dashboard Operativo:**
   - KPIs del turno: Ganancias de hoy, entregas completadas, propinas acumuladas.
   - Tarjeta de **Entrega Prioritaria** con accesos rápidos:
     - 📞 Llamada telefónica directa al cliente en 1 tap.
     - 💬 Mensaje directo pre-redactado en WhatsApp.
     - 🗺️ Navegación GPS hacia el punto de entrega.
     - ✅ Finalización de entrega con prueba digital.
3. **Ruta Optimizada por IA:**
   - Mapa interactivo con avenidas, punto de origen de sucursal, waypoints de paradas numeradas y marcador en vivo con pulso de animación para el repartidor.
   - Botón de **Simulación de Avance GPS** para pruebas inmediatas.
   - Indicador de giro a giro ("En 250m gira a la derecha"), distancia y tiempo estimado (ETA).
   - Panel inferior deslizable con la lista secuencial de paradas de entrega.
4. **Prueba de Entrega Digital (Proof of Delivery):**
   - **Canvas de firma digital interactiva** con el dedo en pantalla.
   - **Captura fotográfica** simulada del paquete o fachada.
   - **Código PIN de 4 dígitos** para validación contra fraude.
   - Registro del nombre de quien recibe.

### 🏪 Modo Sucursal / Negocio (Companion de Despacho)
1. **Selector de Sucursal Multitienda** (ej. Roma Norte, Polanco, Condesa).
2. **Monitoreo de Flota en Vivo:**
   - Cantidad de repartidores activos vs desconectados.
   - Vehículos (Moto, Bici eléctrica, etc.) y entregas completadas.
3. **Cola de Despacho:**
   - Asignación rápida de pedidos listos hacia repartidores disponibles con 1 tap.

### 📊 Métricas & Analítica
- Historial semanal de ingresos con gráfico de barras personalizadas.
- Métricas de eficiencia: Tasa de puntualidad (98.6%), tiempo promedio por entrega (21 min), kilómetros recorridos.
- Calificación media de satisfacción del cliente.

### ⚙️ Ajustes & Conexión
- Cambio dinámico entre **Modo Repartidor** y **Modo Sucursal**.
- Configuración de Slug de negocio (`[slug].reparto.mx`).
- Cambio instantáneo de tema: **Oscuro** o **Claro**.
- Monitor de latencia del servidor (18ms) y enlace a la web oficial.

---

## 📁 Estructura del Código

```
lib/
├── main.dart                          # Punto de entrada MultiProvider & inicialización
├── env.dart                           # Credenciales de Supabase, Mapbox y Resend
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # URLs de reparto.mx, claves de sesión, estatus
│   ├── network/
│   │   ├── api_service.dart           # Cliente HTTP hacia reparto.mx con fallback offline
│   │   └── mock_data.dart             # Datos realistas de pedidos, rutas y flota en CDMX
│   ├── services/
│   │   ├── location_service.dart      # Cálculo de distancias Haversine, tiempo y formateo
│   │   └── storage_service.dart       # Persistencia local con SharedPreferences
│   ├── theme/
│   │   ├── app_colors.dart            # Paleta oficial extraída del CSS de reparto.mx
│   │   ├── app_theme.dart             # Definición de ThemeData Oscuro y Claro
│   │   └── app_typography.dart        # Fuentes Outfit & Inter
│   └── widgets/
│       ├── custom_app_bar.dart        # Barra superior con estado en línea y toggle de tema
│       ├── reparto_badge.dart         # Pills de estado (.status-route, .status-done, etc.)
│       ├── reparto_button.dart        # Botones .btn-primary, .btn-secondary con glow
│       ├── reparto_card.dart          # Tarjetas modernas con bordes sutiles
│       └── reparto_logo.dart          # Logo corporativo con rayo y punto rojo
├── models/
│   ├── branch_model.dart              # Sucursales de negocio
│   ├── courier_model.dart             # Perfil y estado del repartidor
│   ├── order_model.dart               # Modelo de pedido, items y prueba de entrega
│   └── route_stop_model.dart          # Paradas secuenciales de la ruta optimizada
├── providers/
│   ├── auth_provider.dart             # Sesión, rol (repartidor/despacho), conexión online
│   ├── dispatch_provider.dart         # Gestión de flota y asignación de órdenes
│   ├── orders_provider.dart           # Ciclo de vida y filtros de pedidos
│   ├── route_provider.dart            # Navegación y simulación GPS
│   └── theme_provider.dart            # Modo Oscuro / Modo Claro
└── screens/
    ├── auth/
    │   └── login_screen.dart          # Inicio de sesión y enlace a reparto.mx
    ├── courier/
    │   ├── active_route_screen.dart   # Mapa de ruta interactivo y paradas
    │   ├── courier_dashboard_screen.dart # Dashboard de turno del repartidor
    │   └── proof_of_delivery_sheet.dart  # Modal de firma digital y foto
    ├── dispatch/
    │   └── dispatch_screen.dart       # Tablero de despacho para la tienda
    ├── main_navigation_screen.dart    # Barra de navegación adaptable según rol
    ├── metrics/
    │   └── metrics_screen.dart        # Gráfico semanal y analítica
    ├── orders/
    │   ├── order_detail_screen.dart   # Detalle, recibo y comunicación con cliente
    │   └── orders_list_screen.dart    # Lista con filtros y búsqueda
    ├── settings/
    │   └── settings_screen.dart       # Ajustes, slug de tienda y tema
    └── splash/
        └── splash_screen.dart         # Pantalla de carga con rayo pulsante
```

---

## 🛠️ Ejecución del Proyecto

1. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

2. **Verificar análisis de código:**
   ```bash
   flutter analyze
   ```

3. **Ejecutar pruebas automatizadas:**
   ```bash
   flutter test
   ```

4. **Correr en dispositivo o simulador:**
   ```bash
   flutter run
   ```
