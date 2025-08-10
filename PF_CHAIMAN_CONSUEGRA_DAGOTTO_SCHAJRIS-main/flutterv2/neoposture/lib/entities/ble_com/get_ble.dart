// Importación de la API de Bluetooth Low Energy
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Clase para recibir datos desde dispositivos BLE
/// 
/// Esta clase maneja la suscripción a características BLE que envían
/// notificaciones con datos del sensor. Específicamente se encarga de:
/// - Descubrir servicios y características del dispositivo
/// - Habilitar notificaciones en la característica del contador
/// - Convertir los datos binarios recibidos a valores enteros
/// - Proporcionar un Stream reactivo para el contador
class GetBle {
  // ==================== UUIDS DEL PROTOCOLO BLE ====================
  /// UUID del servicio principal del dispositivo NeoPosture
  /// Este servicio contiene todas las características de la aplicación
  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  
  /// UUID de la característica del contador
  /// Esta característica envía notificaciones con el valor del contador del sensor
  static const String _counterCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  /// Se suscribe a una característica notificada y devuelve un stream del contador
  /// 
  /// Proceso de suscripción:
  /// 1. Descubre todos los servicios disponibles en el dispositivo
  /// 2. Busca el servicio específico por UUID
  /// 3. Busca la característica del contador dentro del servicio
  /// 4. Habilita las notificaciones para esa característica
  /// 5. Mapea los datos binarios recibidos a valores enteros
  /// 6. Retorna un Stream que emite cada nuevo valor del contador
  /// 
  /// @param device Dispositivo BLE conectado del cual recibir datos
  /// @return Stream`<int>` que emite el valor del contador cada vez que se actualiza
  /// @throws Exception si no se encuentra el servicio o característica
  Stream<int> subscribeToCounter(BluetoothDevice device) async* {
    // ==================== DESCUBRIMIENTO DE SERVICIOS ====================
    /// Descubrir todos los servicios disponibles en el dispositivo conectado
    /// Esto puede tomar algunos segundos la primera vez
    final services = await device.discoverServices();
    
    // ==================== BÚSQUEDA DEL SERVICIO ====================
    /// Buscar el servicio específico del dispositivo NeoPosture por UUID
    /// Si no se encuentra, lanza una excepción descriptiva
    final service = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == _serviceUuid,
      orElse: () => throw Exception(
        "Servicio no encontrado. UUID esperado: $_serviceUuid"
      ),
    );
    
    // ==================== BÚSQUEDA DE LA CARACTERÍSTICA ====================
    /// Buscar la característica del contador dentro del servicio
    /// Esta característica debe soportar notificaciones
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == _counterCharacteristicUuid,
      orElse: () => throw Exception(
        "Característica del contador no encontrada. UUID esperado: $_counterCharacteristicUuid"
      ),
    );

    // ==================== HABILITACIÓN DE NOTIFICACIONES ====================
    /// Habilitar las notificaciones para recibir datos automáticamente
    /// Esto le dice al dispositivo que queremos recibir actualizaciones
    await characteristic.setNotifyValue(true);

    // ==================== PROCESAMIENTO DE DATOS ====================
    /// Retornar un stream que convierte los datos binarios a enteros
    /// 
    /// El dispositivo envía el contador como 4 bytes (int32) en formato little-endian:
    /// - Byte 0: bits 0-7
    /// - Byte 1: bits 8-15  
    /// - Byte 2: bits 16-23
    /// - Byte 3: bits 24-31
    /// 
    /// La conversión reconstructa el valor entero original
    yield* characteristic.lastValueStream.map((value) {
      // Verificar que tenemos al menos 4 bytes para un int32
      if (value.length >= 4) {
        // Reconstruir el entero de 32 bits desde los bytes (little-endian)
        return value[0] |           // Bits 0-7
               (value[1] << 8) |    // Bits 8-15
               (value[2] << 16) |   // Bits 16-23
               (value[3] << 24);    // Bits 24-31
      }
      // Si no hay suficientes datos, retornar 0 como valor por defecto
      return 0;
    });
  }
}