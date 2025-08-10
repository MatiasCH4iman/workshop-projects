// Importaciones necesarias para operaciones BLE
import 'package:flutter_blue_plus/flutter_blue_plus.dart';  // API principal de BLE
import 'dart:async';                                        // Para StreamSubscription

/// Controlador principal para manejar operaciones de Bluetooth Low Energy
/// 
/// Esta clase encapsula las operaciones básicas de BLE:
/// - Escaneo de dispositivos cercanos con filtrado por nombre
/// - Conexión a dispositivos específicos
/// - Gestión del estado del adaptador Bluetooth
/// 
/// Actúa como una capa de abstracción sobre flutter_blue_plus,
/// proporcionando métodos más específicos para la aplicación NeoPosture.
class BleController {
  // ==================== PROPIEDADES ====================
  /// Lista interna de resultados de escaneo BLE encontrados
  /// Se actualiza dinámicamente durante el proceso de escaneo
  final List<ScanResult> scanResults = [];
  
  /// Suscripción al stream de resultados de escaneo
  /// Se usa para cancelar la suscripción cuando sea necesario
  StreamSubscription? _scanSubscription; 



  // ==================== ESCANEO DE DISPOSITIVOS ====================
  /// Escanea dispositivos BLE cercanos filtrados por nombre "NeoPosture"
  /// 
  /// Proceso de escaneo:
  /// 1. Limpia los resultados anteriores
  /// 2. Espera a que el adaptador Bluetooth esté encendido
  /// 3. Cancela cualquier escaneo anterior para evitar conflictos
  /// 4. Se suscribe al stream de resultados y filtra por nombre
  /// 5. Ejecuta el escaneo durante el tiempo especificado
  /// 6. Espera a que termine y limpia la suscripción
  /// 7. Retorna la lista de dispositivos encontrados
  /// 
  /// @param timeout Duración máxima del escaneo (por defecto 10 segundos)
  /// @return Lista de dispositivos BLE que coinciden con el filtro
  /// @throws Exception si el Bluetooth no está disponible o hay errores
  Future<List<ScanResult>> scanNearbyDevices({
    Duration timeout = const Duration(seconds: 10)
  }) async {
    // Limpiar resultados de escaneos anteriores
    scanResults.clear();
    
    // ==================== VERIFICACIÓN DEL ADAPTADOR ====================
    /// Esperar hasta que el adaptador Bluetooth esté encendido
    /// Esto previene errores si el usuario tiene Bluetooth desactivado
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    // ==================== PREPARACIÓN DEL ESCANEO ====================
    /// Cancelar cualquier suscripción anterior para evitar memory leaks
    /// y conflictos con escaneos simultáneos
    _scanSubscription?.cancel();
    
    // ==================== FILTRADO DE RESULTADOS ====================
    /// Suscribirse al stream de resultados y filtrar por nombre del dispositivo
    /// Se buscan dispositivos con nombre "NeoPosture" en:
    /// - advName: Nombre anunciado en el advertisement
    /// - platformName: Nombre del dispositivo en la plataforma
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final filtered = results.where((result) {
        final advName = result.advertisementData.advName;
        final platformName = result.device.platformName;
        return advName == "NeoPosture" || platformName == "NeoPosture";
      }).toList();
      
      // Actualizar la lista de resultados con los dispositivos filtrados
      scanResults
        ..clear()           // Limpiar lista anterior
        ..addAll(filtered); // Agregar dispositivos filtrados
    });

    // ==================== EJECUCIÓN DEL ESCANEO ====================
    /// Iniciar el escaneo BLE con el timeout especificado
    await FlutterBluePlus.startScan(timeout: timeout);
    
    /// Esperar hasta que el escaneo termine completamente
    /// Esto garantiza que todos los resultados se hayan procesado
    await FlutterBluePlus.isScanning
        .where((scanning) => scanning == false)
        .first;
    
    // ==================== LIMPIEZA ====================
    /// Cancelar la suscripción para liberar recursos
    await _scanSubscription?.cancel();
    
    // Retornar una copia de la lista para evitar modificaciones externas
    return List<ScanResult>.from(scanResults);
  }

  // ==================== CONEXIÓN A DISPOSITIVO ====================
  /// Establece conexión con un dispositivo BLE específico
  /// 
  /// Esta función maneja la conexión física al dispositivo BLE.
  /// Una vez conectado, el dispositivo estará disponible para:
  /// - Descubrimiento de servicios
  /// - Lectura/escritura de características
  /// - Suscripción a notificaciones
  /// 
  /// @param device El dispositivo BLE al que conectarse
  /// @throws Exception si la conexión falla (dispositivo fuera de rango,
  ///                  ya conectado a otro cliente, error de emparejamiento, etc.)
  /// 
  /// Notas importantes:
  /// - La conexión puede fallar si el dispositivo está fuera de rango
  /// - Algunos dispositivos requieren emparejamiento antes de conectar
  /// - La conexión se mantiene hasta que se desconecte explícitamente
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Intentar establecer la conexión BLE
      await device.connect();
      
      // Si llegamos aquí, la conexión fue exitosa
      // El dispositivo ahora está disponible para operaciones BLE
    } catch (e) {
      // Propagar la excepción para que sea manejada por el código llamador
      // Esto permite a la UI mostrar mensajes de error específicos
      rethrow;
    }
  }
}
