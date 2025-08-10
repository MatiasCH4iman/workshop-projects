// Importaciones necesarias para Flutter, Riverpod, navegación y permisos
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neoposture/core/router/app_router.dart';
import 'package:neoposture/entities/notification.dart';
import 'package:neoposture/entities/notification/init_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Solicita los permisos necesarios para el funcionamiento de BLE
/// 
/// Permisos requeridos:
/// - bluetoothScan: Para escanear dispositivos BLE cercanos
/// - bluetoothConnect: Para conectarse a dispositivos BLE
/// - locationWhenInUse: Requerido por Android para BLE (ubicación aproximada)
/// 
/// Retorna [true] si todos los permisos son concedidos, [false] en caso contrario
Future<bool> requestPermissions() async {
  // Solicitar permiso para escanear dispositivos Bluetooth
  final bluetoothScan = await Permission.bluetoothScan.request();
  
  // Solicitar permiso para conectarse a dispositivos Bluetooth
  final bluetoothConnect = await Permission.bluetoothConnect.request();
  
  // Solicitar permiso de ubicación (requerido para BLE en Android)
  final location = await Permission.locationWhenInUse.request();
  
  // Retornar true solo si todos los permisos fueron concedidos
  return bluetoothScan.isGranted && bluetoothConnect.isGranted && location.isGranted;
}

/// Punto de entrada principal de la aplicación NeoPosture
/// 
/// Esta función:
/// 1. Inicializa los servicios de Flutter
/// 2. Configura las notificaciones locales
/// 3. Envuelve la app con ProviderScope para Riverpod
/// 4. Solicita permisos de notificaciones y BLE de manera asíncrona
void main() async {
  // Asegurar que Flutter esté completamente inicializado antes de continuar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar el sistema de notificaciones locales
  await initNotifications();
  
  // Iniciar el provider para las variables globales
  runApp(const ProviderScope(child: MainApp()));
  
  // Solicitar permisos de notificaciones de manera asíncrona
  requestNotificationPermission().then((granted) {
    if (granted) {
      debugPrint('Notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
  });
  
  // Solicitar permisos de Bluetooth de manera asíncrona
  requestPermissions().then((granted) {
    if (granted) {
      debugPrint('BLE permissions granted');
    } else {
      debugPrint('BLE permissions denied');
    }
  });
}


/// Configura el MaterialApp con:
/// - Router personalizado usando GoRouter
/// - Banner de debug deshabilitado para una mejor experiencia de usuario
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Configuración del router para navegación entre pantallas
      routerConfig: appRouter,
      
      // Deshabilitar el banner de debug en la esquina superior derecha
      debugShowCheckedModeBanner: false,  
    );
  }
}
