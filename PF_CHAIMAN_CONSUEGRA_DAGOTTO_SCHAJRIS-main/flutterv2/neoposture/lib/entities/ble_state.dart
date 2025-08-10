// Importación necesaria para los tipos de dispositivos BLE
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Modelo inmutable que representa el estado completo del sistema BLE
/// 
/// Esta clase mantiene toda la información relacionada con:
/// - Dispositivos BLE encontrados y conectados
/// - Estados de operaciones asíncronas (escaneo, conexión)
/// - Datos del sensor en tiempo real
/// - Estado del dispositivo remoto
/// 
/// Al ser inmutable, cualquier cambio genera una nueva instancia
/// usando el método copyWith(), lo que garantiza la reactividad
/// del sistema de estado y evita mutaciones accidentales.
class BleState {
  // ==================== DISPOSITIVOS Y CONEXIÓN ====================
  /// Lista de dispositivos BLE encontrados durante el escaneo
  /// Cada elemento contiene información del dispositivo y datos de advertisement
  final List<ScanResult> devices;
  
  /// Dispositivo BLE actualmente conectado
  /// null si no hay ningún dispositivo conectado
  final BluetoothDevice? connectedDevice;
  
  // ==================== ESTADOS DE OPERACIONES ====================
  /// Indica si se está ejecutando un escaneo de dispositivos
  /// true = escaneando, false = no escaneando
  final bool isScanning;
  
  /// Indica si se está estableciendo una conexión
  /// true = conectando, false = no conectando
  final bool isConnecting;
  
  // ==================== DATOS DEL SENSOR ====================
  /// Valor actual del contador recibido del sensor BLE
  ///  si no hay datos disponibles o no hay dispositivo conectados devuelve valor nulo
  final int? contador;
  
  // ==================== ESTADO DEL DISPOSITIVO REMOTO ====================
  /// Estado actual del dispositivo remoto
  /// true = encendido, false = apagado
  final bool isDeviceOn;

  // ==================== CONSTRUCTOR ====================
  /// Constructor con valores por defecto seguros
  /// 
  /// Todos los parámetros son opcionales y tienen valores por defecto
  /// que representan un estado inicial seguro (sin conexión, sin operaciones activas)
  const BleState({
    this.devices = const [],        // Lista vacía por defecto
    this.connectedDevice,           // null por defecto (sin conexión)
    this.isScanning = false,        // No escaneando por defecto
    this.isConnecting = false,      // No conectando por defecto
    this.contador,                  // null por defecto (sin datos)
    this.isDeviceOn = false,        // Apagado por defecto
  });

  // ==================== MÉTODO COPYWITH ====================
  /// Crea una nueva instancia del estado con los valores especificados cambiados
  /// 
  /// Este método es fundamental para la inmutabilidad del estado.
  /// Permite actualizar solo los campos necesarios mientras mantiene
  /// los demás valores intactos.
  /// 
  /// Parámetros especiales para limpiar valores:
  /// - [clearConnectedDevice]: Si es verdades borra el dispositivo conectado
  /// - [clearContador]: Si es verdadero borra el contador
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// // Actualizar solo la lista de dispositivos
  /// newState = state.copyWith(devices: newDevices);
  /// 
  /// // Limpiar el dispositivo conectado
  /// newState = state.copyWith(clearConnectedDevice: true);
  /// 
  /// // Actualizar múltiples campos
  /// newState = state.copyWith(
  ///   isScanning: false,
  ///   devices: foundDevices,
  /// );
  /// ```
  BleState copyWith({
    List<ScanResult>? devices,           // Nueva lista de dispositivos
    BluetoothDevice? connectedDevice,    // Nuevo dispositivo conectado
    bool? isScanning,                    // Nuevo estado de escaneo
    bool? isConnecting,                  // Nuevo estado de conexión
    int? contador,                       // Nuevo valor del contador
    bool? isDeviceOn,                    // Nuevo estado del dispositivo
    bool clearConnectedDevice = false,   // Flag para limpiar dispositivo conectado
    bool clearContador = false,          // Flag para limpiar contador
  }) {
    return BleState(
      devices: devices ?? this.devices,
      connectedDevice: clearConnectedDevice 
          ? null 
          : (connectedDevice ?? this.connectedDevice),
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      contador: clearContador 
          ? null 
          : (contador ?? this.contador),
      isDeviceOn: isDeviceOn ?? this.isDeviceOn,
    );
  }

  // ==================== MÉTODO toString ====================
  /// Representación en string del estado para debuggear

  @override
  String toString() {
    return 'BleState('
        'devices: ${devices.length}, '
        'connectedDevice: ${connectedDevice?.platformName ?? 'null'}, '
        'isScanning: $isScanning, '
        'isConnecting: $isConnecting, '
        'contador: $contador, '
        'isDeviceOn: $isDeviceOn'
        ')';
  }
}
