// Importaciones necesarias para manejo de permisos y notificaciones
import 'package:permission_handler/permission_handler.dart';      // Gestión de permisos del sistema
import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // API de notificaciones locales

/// Solicita permiso del usuario para mostrar notificaciones
/// 
/// En Android 13 (API 33) y versiones posteriores, las aplicaciones
/// necesitan solicitar explícitamente permiso para mostrar notificaciones.
/// Esta función maneja esa solicitud de forma asíncrona.
/// 
/// Proceso:
/// 1. Solicita el permiso de notificación al sistema
/// 2. El sistema muestra un diálogo al usuario
/// 3. El usuario puede aceptar o rechazar
/// 4. Retorna el resultado de la decisión del usuario
/// 
/// @return `Future<bool>` true si el permiso fue concedido, false si fue denegado
/// 
/// Casos de uso:
/// - Llamar al inicio de la aplicación (en main())
/// - Llamar antes de mostrar notificaciones importantes
/// - Llamar en configuración para verificar permisos
/// 
/// Ejemplo:
/// ```dart
/// final granted = await requestNotificationPermission();
/// if (granted) {
///   // Mostrar notificaciones
/// } else {
///   // Manejar caso sin permisos
/// }
/// ```
Future<bool> requestNotificationPermission() async {
  // Solicitar el permiso de notificación y obtener el estado resultante
  final status = await Permission.notification.request();
  
  // Verificar si el permiso fue concedido
  // isGranted retorna true solo si el usuario aceptó explícitamente
  return status.isGranted;
}

/// Plugin global de notificaciones locales para toda la aplicación
/// 
/// Esta instancia singleton se usa en toda la aplicación para:
/// - Inicializar el sistema de notificaciones
/// - Mostrar notificaciones al usuario
/// - Configurar canales y callbacks
/// - Manejar interacciones del usuario con notificaciones
/// 
/// Importante: Esta debe ser la misma instancia usada en:
/// - init_notifications.dart (para inicialización)
/// - show_notification.dart (para mostrar notificaciones)
/// 
/// Esto garantiza consistencia en la configuración y estado.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();