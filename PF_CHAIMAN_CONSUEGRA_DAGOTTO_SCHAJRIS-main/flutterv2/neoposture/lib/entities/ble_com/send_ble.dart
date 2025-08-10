// Importación de la API de Bluetooth Low Energy
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Modelo de datos para comandos enviados al dispositivo BLE
/// 
/// Esta clase representa un comando que se puede enviar al dispositivo
/// NeoPosture para controlar su estado y configuración.
/// 
/// Estructura del comando:
/// - connected: Estado deseado del dispositivo (true = ON, false = OFF)
/// - timeCheck: Intervalo de verificación en milisegundos
class SendBle {
  /// Estado deseado del dispositivo
  /// - true: Encender el dispositivo
  /// - false: Apagar el dispositivo
  final bool connected;
  
  /// Tiempo de verificación en milisegundos
  /// 
  /// Este valor determina cada cuánto tiempo el dispositivo
  /// debe verificar su estado o realizar mediciones.
  /// 
  /// Valores típicos:
  /// - 1000ms = 1 segundo (frecuencia alta)
  /// - 5000ms = 5 segundos (frecuencia media)
  /// - 10000ms = 10 segundos (frecuencia baja)
  final int timeCheck;

  /// Constructor que requiere ambos parámetros
  /// 
  /// @param connected Estado del dispositivo a establecer
  /// @param timeCheck Intervalo de verificación en milisegundos
  SendBle({
    required this.connected,
    required this.timeCheck,
  });
}

/// Clase para enviar comandos a dispositivos BLE
/// 
/// Esta clase maneja el envío de comandos de control al dispositivo
/// NeoPosture. Se encarga de:
/// - Descubrir servicios y características
/// - Convertir los datos del comando a formato binario
/// - Enviar los datos a la característica correcta
/// - Manejar errores de comunicación
class BleSender {
  /// Envía los datos de SendBle a una característica BLE
  /// 
  /// Proceso de envío:
  /// 1. Descubre todos los servicios del dispositivo conectado
  /// 2. Busca el servicio específico por UUID
  /// 3. Busca la característica de control dentro del servicio
  /// 4. Convierte los datos del comando a formato binario
  /// 5. Envía los datos al dispositivo
  /// 
  /// Formato de los datos enviados (5 bytes total):
  /// - Byte 0: Estado del dispositivo (1 = ON, 0 = OFF)
  /// - Bytes 1-4: Tiempo de verificación como int32 little-endian
  /// 
  /// @param device Dispositivo BLE conectado al cual enviar el comando
  /// @param data Objeto SendBle con los datos del comando
  /// @throws Exception si no se encuentra el servicio/característica o falla el envío
  Future<void> sendData(BluetoothDevice device, SendBle data) async {
    // ==================== DESCUBRIMIENTO DE SERVICIOS ====================
    /// Descubrir todos los servicios disponibles en el dispositivo
    final services = await device.discoverServices();
    
    // ==================== BÚSQUEDA DEL SERVICIO ====================
    /// Buscar el servicio principal del dispositivo NeoPosture
    final service = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b",
      orElse: () => throw Exception(
        "Servicio no encontrado. Verifica que el dispositivo sea compatible."
      ),
    );
    
    // ==================== BÚSQUEDA DE LA CARACTERÍSTICA ====================
    /// Buscar la característica de control que acepta comandos
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == "beb5483e-36e1-4688-b7f5-ea07361b26a8",
      orElse: () => throw Exception(
        "Característica de control no encontrada. Verifica el firmware del dispositivo."
      ),
    );

    // ==================== PREPARACIÓN DE DATOS ====================
    /// Convertir el comando a formato binario que entiende el dispositivo
    /// 
    /// Estructura de 5 bytes:
    /// - Byte 0: Estado (1 byte) - 1 para encender, 0 para apagar
    /// - Bytes 1-4: Tiempo (4 bytes) - int32 en formato little-endian
    /// 
    /// Little-endian significa que el byte menos significativo va primero:
    /// Por ejemplo, 5000 (0x1388) se envía como: 0x88, 0x13, 0x00, 0x00
    final bytes = <int>[
      // Byte 0: Estado del dispositivo
      data.connected ? 1 : 0,
      
      // Bytes 1-4: Tiempo como int32 little-endian
      data.timeCheck & 0xFF,          // Byte menos significativo (bits 0-7)
      (data.timeCheck >> 8) & 0xFF,   // Segundo byte (bits 8-15)
      (data.timeCheck >> 16) & 0xFF,  // Tercer byte (bits 16-23)
      (data.timeCheck >> 24) & 0xFF,  // Byte más significativo (bits 24-31)
    ];

    // ==================== ENVÍO DE DATOS ====================
    /// Escribir los datos a la característica del dispositivo
    /// 
    /// withoutResponse: false significa que esperamos confirmación
    /// del dispositivo de que recibió los datos correctamente
    await characteristic.write(bytes, withoutResponse: false);
    
    // Si llegamos aquí, el comando se envió exitosamente
  }
}