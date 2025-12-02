import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:neo_posture/entities/ble_controller.dart';
import 'package:neo_posture/entities/ble_state.dart';

class BleNotifier extends StateNotifier<BleState> {
  final BleController _bleController = BleController();
  StreamSubscription? _scanSubscription;

  BleNotifier() : super(const BleState());

  /// Inicia el escaneo de dispositivos BLE
  Future<void> scanForDevices() async {
    state = state.copyWith(isScanning: true, devices: []);

    try {
      final devices = await _bleController.scanNearbyDevices();

      state = state.copyWith(isScanning: false, devices: devices);
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Conecta a un dispositivo BLE
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await _bleController.connectToDevice(device);

      // --- ¡LA CORRECCIÓN ESTÁ AQUÍ! ---
      // Descubre los servicios INMEDIATAMENTE después de conectar.
      // Esto "calienta" la caché de servicios en flutter_blue_plus.
      print('🔍 Descubriendo servicios post-conexión...');
      await device.discoverServices();
      print('✅ Servicios descubiertos.');
      // --- FIN DE LA CORRECIÓN ---

      state = state.copyWith(connectedDevice: device, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Desconecta del dispositivo
  Future<void> disconnect() async {
    if (state.connectedDevice != null) {
      await state.connectedDevice!.disconnect();
      state = state.copyWith(connectedDevice: null);
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}

// ==================== Providers ====================
final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

/// Provider para el dispositivo conectado
final connectedDeviceProvider = Provider<BluetoothDevice?>((ref) {
  return ref.watch(bleProvider).connectedDevice;
});
