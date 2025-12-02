// sensor_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/sensor.dart';
import 'ble_provider.dart';

/// StreamProvider que expone los datos de los sensores
final multiSensorDataProvider = StreamProvider<MultipleSensorData>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) {
    // devolver un stream inmediato vacío para que la UI no espere indefinidamente
    return Stream.value(MultipleSensorData({}));
  }

  final sensors = SensorsBle();
  return sensors.subscribeToMultipleSensors(device);
});
