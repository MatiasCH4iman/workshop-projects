// ==========================================================
// Archivo: app_router.dart
// Descripción: Configuración principal de rutas con GoRouter
// Proyecto: NeoPosture
// ==========================================================

// ==================== IMPORTACIONES ====================
import 'package:go_router/go_router.dart';
import 'screens/permission_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/print_screen.dart';

/// ==========================================================
/// Configuración principal de navegación de la aplicación
/// ==========================================================
///
/// Este router define la navegación entre pantallas.
/// En esta versión simplificada, solo existe una pantalla:
/// - `/permission`: Pantalla principal de configuración BLE
///
final appRouter = GoRouter(
  // ==================== CONFIGURACIÓN INICIAL ====================
  /// Pantalla inicial al abrir la app
  initialLocation: '/permission',

  // ==================== DEFINICIÓN DE RUTAS ====================
  routes: [
    GoRoute(
      path: '/permission',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/connection',
      builder: (context, state) => const ConnectionScreen(),
    ),
    GoRoute(
      path: '/print',
      builder: (context, state) => const PrintScreen(),
    ),
  ],
);
