// lib/entities/multi_sensor.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';

import 'package:neo_posture/providers/ble_provider.dart';

/// Datos de un sensor individual
class PostureData {
  final int sensorId;
  final double pitch;
  final double roll;

  PostureData({required this.sensorId, required this.pitch, required this.roll});
}

/// Datos de múltiples sensores
class MultipleSensorData {
  final Map<int, PostureData> sensorsData;
  MultipleSensorData(this.sensorsData);

  double get avgPitch => sensorsData.isNotEmpty
      ? sensorsData.values.map((s) => s.pitch).reduce((a, b) => a + b) / sensorsData.length
      : 0.0;

  double get avgRoll => sensorsData.isNotEmpty
      ? sensorsData.values.map((s) => s.roll).reduce((a, b) => a + b) / sensorsData.length
      : 0.0;
}

/// Estado de los sensores con loading/error opcional
class MultiSensorState {
  final MultipleSensorData? data;
  final bool loading;
  final String? error;

  MultiSensorState({this.data, this.loading = false, this.error});

  @override
  String toString() => 'MultiSensorState(data: $data, loading: $loading, error: $error)';
}

/// Clase que se conecta al BLE y devuelve un stream de MultipleSensorData
class SensorsBle {
  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String _charUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  Stream<MultipleSensorData> subscribeToMultipleSensors(BluetoothDevice device) async* {
    try {
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase(),
        orElse: () => throw Exception("Servicio BLE no encontrado"),
      );

      final char = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == _charUuid.toLowerCase(),
        orElse: () => throw Exception("Característica BLE no encontrada"),
      );

      try {
        await char.setNotifyValue(true).timeout(const Duration(seconds: 8));
      } catch (_) {}

      yield* char.lastValueStream.map((value) {
        final sensorsData = <int, PostureData>{};
        if (value.isEmpty) return MultipleSensorData(sensorsData);

        final bd = ByteData.sublistView(Uint8List.fromList(value));
        final len = value.length;

        // Formato 8 bytes/sensor (pitch + roll)
        if (len % 8 == 0) {
          final num = len ~/ 8;
          for (int i = 0; i < num; i++) {
            final off = i * 8;
            final pitch = bd.getFloat32(off, Endian.little);
            final roll = bd.getFloat32(off + 4, Endian.little);
            sensorsData[i] = PostureData(sensorId: i, pitch: pitch, roll: roll);
          }
          return MultipleSensorData(sensorsData);
        }

        // Formato 12 bytes/sensor (id + pitch + roll)
        if (len % 12 == 0) {
          final num = len ~/ 12;
          for (int i = 0; i < num; i++) {
            final off = i * 12;
            final sensorId = bd.getFloat32(off, Endian.little).toInt();
            final pitch = bd.getFloat32(off + 4, Endian.little);
            final roll = bd.getFloat32(off + 8, Endian.little);
            sensorsData[sensorId] = PostureData(sensorId: sensorId, pitch: pitch, roll: roll);
          }
          return MultipleSensorData(sensorsData);
        }

        // Legacy single-sensor (8 bytes)
        if (len == 8) {
          final pitch = bd.getFloat32(0, Endian.little);
          final roll = bd.getFloat32(4, Endian.little);
          sensorsData[0] = PostureData(sensorId: 0, pitch: pitch, roll: roll);
          return MultipleSensorData(sensorsData);
        }

        return MultipleSensorData(sensorsData);
      });
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider unificado de MultiSensorState
final multiSensorStateProvider = StreamProvider<MultiSensorState>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return Stream.value(MultiSensorState(loading: false, data: null));

  final sensors = SensorsBle();
  return sensors.subscribeToMultipleSensors(device).map((data) => MultiSensorState(data: data));
});
