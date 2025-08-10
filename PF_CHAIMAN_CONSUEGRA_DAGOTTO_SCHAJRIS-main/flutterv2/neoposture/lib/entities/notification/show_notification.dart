// Importación de la librería de notificaciones locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Plugin global para manejar notificaciones locales
/// 
/// Esta instancia debe ser la misma que se usa en init_notifications.dart
/// para mantener la consistencia de configuración en toda la aplicación.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Muestra una notificación simple al usuario
/// 
/// Esta función crea y muestra una notificación local con título y contenido
/// personalizados. La notificación aparece en la barra de notificaciones
/// del sistema operativo.
/// 
/// Configuración de la notificación:
/// - Importancia: Máxima (aparece como heads-up notification)
/// - Prioridad: Alta (se muestra prominentemente)
/// - Canal: 'default_channel_id' (canal por defecto)
/// - ID: 0 (se sobrescribe si se envía otra notificación)
/// 
/// @param title Título de la notificación (línea principal)
/// @param body Contenido de la notificación (texto descriptivo)
/// @throws Exception si falla el envío de la notificación
/// 
/// Ejemplo de uso:
/// ```dart
/// await showSimpleNotification(
///   "NeoPosture", 
///   "Dispositivo conectado exitosamente"
/// );
/// ```
Future<void> showSimpleNotification(String title, String body) async {
  // ==================== CONFIGURACIÓN DE ANDROID ====================
  /// Configuración específica para notificaciones Android
  /// 
  /// Parámetros importantes:
  /// - 'default_channel_id': Identificador único del canal de notificación
  /// - 'Default': Nombre visible del canal en configuración del sistema
  /// - Importance.max: Notificación de máxima importancia (heads-up)
  /// - Priority.high: Prioridad alta para mostrar prominentemente
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'default_channel_id',           // ID del canal
    'Default',                      // Nombre del canal
    importance: Importance.max,     // Importancia máxima
    priority: Priority.high,        // Prioridad alta
  );
  
  // ==================== CONFIGURACIÓN MULTIPLATAFORMA ====================
  /// Configuración que combina todas las plataformas soportadas
  /// 
  /// En este caso solo se setea android
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  
  // ==================== ENVÍO DE LA NOTIFICACIÓN ====================
  /// Mostrar la notificación usando el plugin configurado
  /// 
  /// Parámetros:
  /// - 0: ID de la notificación (usar 0 sobrescribe notificaciones anteriores)
  /// - title: Título que aparece en negrita
  /// - body: Contenido de la notificación
  /// - platformChannelSpecifics: Configuración de presentación
  /// 
  /// Si se quieren múltiples notificaciones simultáneas, usar IDs diferentes.
  await flutterLocalNotificationsPlugin.show(
    0,                              // ID único de la notificación
    title,                          // Título de la notificación
    body,                           // Contenido de la notificación
    platformChannelSpecifics,       // Configuración de plataforma
  );
  
  // Si llegamos aquí, la notificación se envió correctamente
}