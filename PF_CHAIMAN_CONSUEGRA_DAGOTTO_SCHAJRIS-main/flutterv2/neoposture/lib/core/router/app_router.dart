// Importaciones necesarias para la navegación y las pantallas
import 'package:go_router/go_router.dart';                                    // Sistema de navegación GoRouter
import 'package:neoposture/presentation/screens/config_screen.dart';          // Pantalla de configuración
import 'package:neoposture/presentation/screens/dashboard_screen.dart';       // Pantalla dashboard principal

/// Configuración principal de navegación de la aplicación
/// 
/// Este router define todas las rutas disponibles en la aplicación
/// y maneja la navegación entre pantallas usando GoRouter.
/// 
/// Características:
/// - Navegación declarativa basada en rutas nombradas
/// - Ruta inicial configurada al dashboard
/// - Soporte para navegación programática y por URL
/// - Integración automática con el botón "atrás" del sistema
/// 
/// Rutas disponibles:
/// - /dashboard: Pantalla principal con resumen del estado BLE
/// - /ble: Pantalla de control directo de dispositivos BLE
/// - /config: Pantalla de configuración y gestión avanzada
final appRouter = GoRouter(
  // ==================== CONFIGURACIÓN INICIAL ====================
  /// Ruta inicial que se muestra al abrir la aplicación
  /// 
  /// Se configura al dashboard porque:
  /// - Proporciona una vista general del estado
  /// - Incluye acceso rápido a todas las funciones
  /// - Mejor experiencia de usuario inicial
  initialLocation: '/dashboard',
  
  // ==================== DEFINICIÓN DE RUTAS ====================
  /// Lista de todas las rutas disponibles en la aplicación
  /// 
  /// Cada ruta define:
  /// - name: Identificador único para navegación programática
  /// - path: URL/ruta que representa la pantalla
  /// - builder: Función que construye el widget de la pantalla
  routes: <RouteBase>[
    // ==================== RUTA DEL DASHBOARD ====================
    /// Pantalla principal con vista general del estado BLE
    /// 
    /// Características:
    /// - Muestra estado del contador en tiempo real
    /// - Lista de dispositivos disponibles
    /// - Controles rápidos de conexión
    /// - Navegación a otras pantallas
    GoRoute(
      name: DashboardScreen.name,           // 'dashboard'
      path: '/dashboard',                   // URL: /dashboard
      builder: (context, state) => const DashboardScreen(),
    ),
    
    // ==================== RUTA DE CONFIGURACIÓN ====================
    /// Pantalla de configuración y gestión avanzada
    /// 
    /// Características:
    /// - Información detallada del dispositivo conectado
    /// - Controles de gestión del estado
    /// - Configuraciones avanzadas
    /// - Herramientas de diagnóstico
    GoRoute(
      name: ConfigScreen.name,              // 'config'
      path: '/config',                      // URL: /config
      builder: (context, state) => const ConfigScreen(),
    ),
  ],
);