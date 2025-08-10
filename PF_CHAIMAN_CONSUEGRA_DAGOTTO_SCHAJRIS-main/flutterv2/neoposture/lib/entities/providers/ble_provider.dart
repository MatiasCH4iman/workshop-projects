// Importaciones necesarias para la gestión de estado BLE
import 'dart:async';                              // Para Timer y StreamSubscription
import 'package:flutter_riverpod/flutter_riverpod.dart';  // Sistema de providers
import 'package:flutter_blue_plus/flutter_blue_plus.dart';  // API de Bluetooth Low Energy
import 'package:neoposture/entities/ble_state.dart';        // Modelo de estado BLE
import 'package:neoposture/entities/ble_controller.dart';   // Controlador de operaciones BLE
import 'package:neoposture/entities/ble_com/get_ble.dart';  // Receptor de datos BLE
import 'package:neoposture/entities/ble_com/send_ble.dart'; // Emisor de comandos BLE

/// Notifier principal que maneja todo el estado relacionado con BLE
/// 
/// Esta clase extiende [StateNotifier] y gestiona:
/// - Escaneo automático y manual de dispositivos
/// - Conexión y desconexión de dispositivos BLE
/// - Suscripción a datos del sensor (contador)
/// - Control remoto del dispositivo (encender/apagar)
/// - Limpieza de recursos y suscripciones
/// 
/// El estado se mantiene en un objeto [BleState] inmutable que se
/// actualiza mediante el método copyWith() para garantizar la reactividad.
class BleNotifier extends StateNotifier<BleState> {
  /// Constructor: inicializa con estado vacío y arranca el escaneo automático
  BleNotifier() : super(const BleState()) {
    _startAutoScan();
  }

  // ==================== CONTROLADORES Y SERVICIOS ====================
  /// Controlador para operaciones básicas de BLE (escaneo, conexión)
  final BleController _controller = BleController();
  
  /// Servicio para recibir datos del dispositivo BLE (suscripciones)
  final GetBle _getBle = GetBle();
  
  /// Servicio para enviar comandos al dispositivo BLE
  final BleSender _bleSender = BleSender();
  
  // ==================== GESTIÓN DE RECURSOS ====================
  /// Timer para escaneo automático cada 5 segundos
  Timer? _autoScanTimer;
  
  /// Suscripción al stream del contador del sensor
  /// Se cancela automáticamente al cambiar de dispositivo
  StreamSubscription<int>? _contadorSubscription;

  // ==================== ESCANEO AUTOMÁTICO ====================
  /// Inicia el escaneo automático cada 5 segundos si no hay dispositivo conectado
  /// 
  /// Esta función:
  /// 1. Cancela cualquier timer anterior para evitar duplicados
  /// 2. Crea un timer periódico que ejecuta cada 5 segundos
  /// 3. Solo escanea si no hay dispositivo conectado y no se está escaneando/conectando
  /// 
  /// Propósito: Mantener la lista de dispositivos actualizada automáticamente
  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Solo escanear si no hay conexión activa y no hay operaciones en curso
      if (state.connectedDevice == null && !state.isScanning && !state.isConnecting) {
        scanDevices();
      }
    });
  }

  // ==================== ESCANEO MANUAL ====================
  /// Escanea dispositivos BLE cercanos de forma manual
  /// 
  /// Esta función:
  /// 1. Verifica que no se esté escaneando ya (evita escaneos duplicados)
  /// 2. Actualiza el estado a "escaneando"
  /// 3. Ejecuta el escaneo usando el controlador BLE
  /// 4. Actualiza la lista de dispositivos encontrados
  /// 5. Maneja errores y actualiza el estado final
  /// 
  /// @throws Exception si ocurre un error durante el escaneo
  Future<void> scanDevices() async {
    // Evitar escaneos múltiples 
    if (state.isScanning) return;

    // Marcar como escaneando para actualizar la parte visual
    state = state.copyWith(isScanning: true);
    
    try {
      // Ejecutar escaneo usando el controlador BLE
      final results = await _controller.scanNearbyDevices();
      // Actualizar estado con dispositivos encontrados y finalizar escaneo
      state = state.copyWith(devices: results, isScanning: false);
    } catch (e) {
      // En caso de error, solo actualizar el estado de escaneo
      state = state.copyWith(isScanning: false);
      rethrow; // Propagar el error para que lo maneje la interfaz
    }
  }

  // ==================== CONEXIÓN A DISPOSITIVO ====================
  /// Conecta a un dispositivo BLE específico
  /// 
  /// Proceso de conexión:
  /// 1. Verifica que no haya una conexión en progreso
  /// 2. Marca el estado como "conectando"
  /// 3. Establece la conexión BLE
  /// 4. Cancela cualquier suscripción anterior al contador
  /// 5. Se suscribe al contador del nuevo dispositivo
  /// 6. Actualiza el estado con el dispositivo conectado
  /// 
  /// @param device El dispositivo BLE al que conectarse
  /// @throws Exception si falla la conexión o suscripción
  Future<void> connectToDevice(BluetoothDevice device) async {
    // Evitar conexiones múltiples simultáneas
    if (state.isConnecting) return;

    // Marcar como conectando para deshabilitar botones en la UI
    state = state.copyWith(isConnecting: true);

    try {
      // Establecer conexión BLE física
      await _controller.connectToDevice(device);
      
      // ==================== GESTIÓN DE SUSCRIPCIONES ====================
      // Cancelar suscripción anterior si existe (limpieza de recursos)
      _contadorSubscription?.cancel();
      
      // Suscribirse al stream del contador del dispositivo conectado
      final stream = _getBle.subscribeToCounter(device);
      _contadorSubscription = stream.listen((valor) {
        // Actualizar el contador en tiempo real cuando lleguen nuevos datos
        state = state.copyWith(contador: valor);
      });

      // ==================== ACTUALIZACIÓN FINAL DEL ESTADO ====================
      state = state.copyWith(
        connectedDevice: device,     // Guardar referencia al dispositivo
        isConnecting: false,         // Finalizar estado de conexión
        clearContador: true,         // Limpiar valor anterior del contador
      );
    } catch (e) {
      // En caso de error, solo actualizar el estado de conexión
      state = state.copyWith(isConnecting: false);
      rethrow; // Propagar el error para manejo en la UI
    }
  }

  // ==================== DESCONEXIÓN ====================
  /// Desconecta el dispositivo actual
  /// 
  /// Proceso de desconexión:
  /// 1. Verifica que haya un dispositivo conectado
  /// 2. Ejecuta la desconexión BLE
  /// 3. Cancela la suscripción al contador
  /// 4. Limpia el estado (dispositivo, contador, estado del dispositivo)
  /// 
  /// @throws Exception si falla la desconexión
  Future<void> disconnectDevice() async {
    // Verificar que hay algo que desconectar
    if (state.connectedDevice == null) return;

    try {
      // Desconectar el dispositivo BLE
      await state.connectedDevice!.disconnect();
      
      // Limpiar suscripción al contador
      _contadorSubscription?.cancel();
      
      // Resetear estado a desconectado
      state = state.copyWith(
        clearConnectedDevice: true,  // Limpiar dispositivo conectado
        clearContador: true,         // Limpiar datos del contador
        isDeviceOn: false,          // Resetear estado del dispositivo
      );
    } catch (e) {
      rethrow; // Propagar error para manejo en la UI
    }
  }

  // ==================== CONEXIÓN/DESCONEXIÓN INTELIGENTE ====================
  /// Conecta o desconecta según el estado actual del dispositivo
  /// 
  /// Esta función de conveniencia:
  /// - Si el dispositivo ya está conectado -> lo desconecta
  /// - Si el dispositivo no está conectado -> lo conecta
  /// 
  /// @param device El dispositivo BLE a conectar/desconectar
  /// @throws Exception si falla la operación
  Future<void> connectOrDisconnect(BluetoothDevice device) async {
    if (state.connectedDevice?.remoteId == device.remoteId) {
      // El dispositivo ya está conectado, desconectarlo
      await disconnectDevice();
    } else {
      // El dispositivo no está conectado, conectarlo
      await connectToDevice(device);
    }
  }

  // ==================== CONTROL DEL DISPOSITIVO ====================
  /// Enciende o apaga el dispositivo remotamente
  /// 
  /// Esta función:
  /// 1. Verifica que haya un dispositivo conectado
  /// 2. Determina el nuevo estado (opuesto al actual)
  /// 3. Crea el comando con el estado y tiempo de verificación
  /// 4. Envía el comando al dispositivo vía BLE
  /// 5. Actualiza el estado local si el envío es exitoso
  /// 
  /// @param timeCheck Tiempo en milisegundos para verificación (por defecto 5000ms)
  /// @throws Exception si no hay dispositivo conectado o falla el envío
  Future<void> toggleDevice({int timeCheck = 5000}) async {
    // Verificar que hay un dispositivo conectado
    if (state.connectedDevice == null) return;

    // Determinar el nuevo estado (toggle: opuesto al actual)
    final newState = !state.isDeviceOn;
    
    try {
      // ==================== CREACIÓN Y ENVÍO DEL COMANDO ====================
      /// Crear objeto de comando con:
      /// - connected: nuevo estado del dispositivo (true = encender, false = apagar)
      /// - timeCheck: intervalo de verificación en milisegundos
      final sendData = SendBle(
        connected: newState,
        timeCheck: timeCheck,
      );
      
      // Enviar comando al dispositivo vía característica BLE
      await _bleSender.sendData(state.connectedDevice!, sendData);
      
      // ==================== RESETEO DEL CONTADOR Y ESTADO ====================
      /// Resetear el contador después del envío exitoso
      /// - Al encender: comienza desde 0 limpio
      /// - Al apagar: se resetea a 0 y se detiene
      state = state.copyWith(
        isDeviceOn: newState,
        contador: 0,  // Resetear contador después del envío exitoso
      );
    } catch (e) {
      rethrow; // Propagar error para manejo en la UI
    }
  }

  // ==================== LIMPIEZA DE RECURSOS ====================
  /// Limpia todos los recursos al destruir el notifier
  /// 
  /// Esta función se llama automáticamente cuando el provider
  /// se destruye y cancela:
  /// - Timer de escaneo automático
  /// - Suscripción al contador del dispositivo
  /// 
  /// Esto previene memory leaks y operaciones en objetos destruidos.
  @override
  void dispose() {
    _autoScanTimer?.cancel();        // Cancelar escaneo automático
    _contadorSubscription?.cancel(); // Cancelar suscripción al contador
    super.dispose();
  }
}

// ==================== PROVIDERS PRINCIPALES ====================

/// Provider principal para el estado del BLE
/// 
/// Este es el provider central que mantiene todo el estado relacionado
/// con Bluetooth Low Energy. Otros widgets pueden:
/// - Observar cambios: ref.watch(bleProvider)
/// - Realizar acciones: ref.read(bleProvider.notifier)
/// 
/// El estado se mantiene de forma inmutable y se actualiza reactivamente.
final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

// ==================== PROVIDERS DERIVADOS ====================
// Estos providers extraen partes específicas del estado principal
// para optimizar las reconstrucciones de widgets (solo se reconstruyen
// cuando cambia la parte del estado que observan)

/// Provider que expone solo la lista de dispositivos encontrados
/// 
/// Uso: final devices = ref.watch(devicesProvider);
/// Se reconstruye solo cuando cambia la lista de dispositivos
final devicesProvider = Provider<List<ScanResult>>((ref) {
  return ref.watch(bleProvider).devices;
});

/// Provider que expone solo el dispositivo conectado actual
/// 
/// Uso: final device = ref.watch(connectedDeviceProvider);
/// Se reconstruye solo cuando se conecta/desconecta un dispositivo
final connectedDeviceProvider = Provider<BluetoothDevice?>((ref) {
  return ref.watch(bleProvider).connectedDevice;
});

/// Provider que expone solo el valor del contador del sensor
/// 
/// Uso: final contador = ref.watch(contadorProvider);
/// Se reconstruye solo cuando cambia el valor del contador
final contadorProvider = Provider<int?>((ref) {
  return ref.watch(bleProvider).contador;
});

/// Provider que expone solo el estado de escaneo
/// 
/// Uso: final isScanning = ref.watch(isScanningProvider);
/// Se reconstruye solo cuando inicia/termina un escaneo
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(bleProvider).isScanning;
});

/// Provider que expone solo el estado de conexión
/// 
/// Uso: final isConnecting = ref.watch(isConnectingProvider);
/// Se reconstruye solo cuando inicia/termina una conexión
final isConnectingProvider = Provider<bool>((ref) {
  return ref.watch(bleProvider).isConnecting;
});

/// Provider que expone solo el estado del dispositivo (ON/OFF)
/// 
/// Uso: final isOn = ref.watch(isDeviceOnProvider);
/// Se reconstruye solo cuando el dispositivo se enciende/apaga
final isDeviceOnProvider = Provider<bool>((ref) {
  return ref.watch(bleProvider).isDeviceOn;
});

/// Provider derivado que indica si hay un dispositivo conectado
/// 
/// Uso: final isConnected = ref.watch(isConnectedProvider);
/// Conveniencia para verificar conexión sin acceder al dispositivo completo
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(bleProvider).connectedDevice != null;
});
