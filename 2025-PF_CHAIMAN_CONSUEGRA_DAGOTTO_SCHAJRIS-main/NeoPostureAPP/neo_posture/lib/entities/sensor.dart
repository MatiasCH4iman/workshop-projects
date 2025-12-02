import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import 'dart:async';

class PostureData {
  final int sensorId;
  final double pitch;
  final double roll;

  PostureData({
    required this.sensorId,
    required this.pitch,
    required this.roll,
  });
}

class MultipleSensorData {
  final Map<int, PostureData> sensorsData;
  MultipleSensorData(this.sensorsData);

  double get avgPitch {
    if (sensorsData.isEmpty) return 0;
    final sum = sensorsData.values.fold<double>(0, (p, d) => p + d.pitch);
    return sum / sensorsData.length;
  }

  double get avgRoll {
    if (sensorsData.isEmpty) return 0;
    final sum = sensorsData.values.fold<double>(0, (p, d) => p + d.roll);
    return sum / sensorsData.length;
  }
}

class SensorsBle {
  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String _charUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  Stream<MultipleSensorData> subscribeToMultipleSensors(BluetoothDevice device) async* {
    try {
      print('🔍 Descubriendo servicios...');
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase(),
        orElse: () => throw Exception("Servicio BLE no encontrado"),
      );

      final char = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == _charUuid.toLowerCase(),
        orElse: () => throw Exception("Característica BLE no encontrada"),
      );

      // Intentar activar notificaciones (no fatal si falla)
      try {
        await char.setNotifyValue(true).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('⚠️ setNotifyValue failed (continuando con stream): $e');
      }

      yield* char.lastValueStream.map((value) {
        final sensorsData = <int, PostureData>{};
        if (value.isEmpty) return MultipleSensorData(sensorsData);

        final bd = ByteData.sublistView(Uint8List.fromList(value));
        final len = value.length;

        // Formato actual preferido: 8 bytes/sensor => [p1,r1,p2,r2,...]
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

        // Formato con ID: 12 bytes/sensor => [id,pitch,roll,...]
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

        // Legacy single-sensor (8 bytes) handled arriba, pero por seguridad:
        if (len == 8) {
          final pitch = bd.getFloat32(0, Endian.little);
          final roll = bd.getFloat32(4, Endian.little);
          sensorsData[0] = PostureData(sensorId: 0, pitch: pitch, roll: roll);
          return MultipleSensorData(sensorsData);
        }

        print('⚠️ Datos con tamaño inesperado: $len bytes');
        return MultipleSensorData(sensorsData);
      });
    } catch (e) {
      print('❌ Error en subscribeToMultipleSensors: $e');
      rethrow;
    }
  }
}
