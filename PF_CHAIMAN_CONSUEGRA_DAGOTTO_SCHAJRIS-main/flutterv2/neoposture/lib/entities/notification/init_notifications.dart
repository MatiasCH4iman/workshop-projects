// Importación de la librería de notificaciones locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Plugin global para manejar notificaciones locales en la aplicación
/// 
/// Esta instancia se usa en toda la aplicación para:
/// - Inicializar el sistema de notificaciones
/// - Mostrar notificaciones al usuario
/// - Configurar canales de notificación
/// - Manejar callbacks de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Inicializa el sistema de notificaciones locales para la plataforma Android
/// 
/// Esta función debe llamarse una vez al inicio de la aplicación, preferiblemente
/// en el método main() después de WidgetsFlutterBinding.ensureInitialized().
/// 
/// Configuración realizada:
/// - Define el icono de notificación (@mipmap/ic_launcher)
/// - Configura las opciones específicas de Android
/// - Inicializa el plugin con la configuración
/// 
/// @throws Exception si falla la inicialización (permisos, configuración inválida, etc.)
/// 
/// Nota: Esta función solo configura Android. Para una aplicación multiplataforma
/// completa, se deberían agregar configuraciones para iOS, macOS, Linux, etc.
Future<void> initNotifications() async {
  // ==================== CONFIGURACIÓN DE ANDROID ====================
  /// Configuración específica para Android
  /// 
  /// @mipmap/ic_launcher: Icono por defecto de la aplicación que se mostrará
  /// en las notificaciones. Este icono debe existir en la carpeta de recursos
  /// de Android (android/app/src/main/res/mipmap-*/)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  // ==================== CONFIGURACIÓN GENERAL ====================
  /// Configuración general que combina todas las plataformas
  /// 
  /// En este caso solo se configura Android, pero aquí se pueden agregar:
  /// - iOS: DarwinInitializationSettings()
  /// - macOS: DarwinInitializationSettings()
  /// - Linux: LinuxInitializationSettings()
  /// - Windows: WindowsInitializationSettings()
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  // ==================== INICIALIZACIÓN DEL PLUGIN ====================
  /// Inicializar el plugin con la configuración definida
  /// 
  /// Esto prepara el sistema para mostrar notificaciones y configura
  /// los canales por defecto. Si falla, puede ser por:
  /// - Permisos insuficientes
  /// - Configuración inválida
  /// - Problemas con el icono especificado
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Si llegamos aquí, la inicialización fue exitosa
}