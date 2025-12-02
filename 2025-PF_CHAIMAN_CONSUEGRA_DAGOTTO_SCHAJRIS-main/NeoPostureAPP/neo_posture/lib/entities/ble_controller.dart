import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleController {
  // UUID del servicio BLE que usa NeoPosture
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String STATUS_UUID = "12345678-1234-5678-1234-56789abcdef0";

  Future<List<ScanResult>> scanNearbyDevices() async {
    List<ScanResult> devices = [];

    try {
      // Detener scan anterior si existe
      await FlutterBluePlus.stopScan();
      
      // Iniciar nuevo scan SIN allowDuplicates (parámetro no existe en versión actual)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
        // withServices: opcional, pero recomendado para Web
        withServices: [
          Guid(SERVICE_UUID),
        ],
      );

      // Escuchar resultados durante el scan
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        devices = results;
      });

      // Esperar a que termine el scan
      await Future.delayed(const Duration(seconds: 6));
      
      subscription.cancel();
      await FlutterBluePlus.stopScan();
      
      return devices;
    } catch (e) {
      print('❌ Error en scanNearbyDevices: $e');
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔗 Conectando a ${device.platformName}...');
      await device.connect(
        timeout: const Duration(seconds: 10),
      );
      print('✅ Conectado a ${device.platformName}');
    } catch (e) {
      print('❌ Error conectando: $e');
      rethrow;
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      print('✅ Desconectado');
    } catch (e) {
      print('❌ Error desconectando: $e');
      rethrow;
    }
  }
}
