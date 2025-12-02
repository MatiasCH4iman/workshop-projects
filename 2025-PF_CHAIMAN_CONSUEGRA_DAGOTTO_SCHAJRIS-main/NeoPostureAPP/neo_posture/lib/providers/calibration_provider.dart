import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/sensor.dart';
import 'ble_provider.dart';
import '../services/posture_persistence_service.dart'; // Para acceder al provider

// Estado de la calibración: promedio de los 5 sensores en las últimas 10 mediciones
final calibrationProvider =
    StateNotifierProvider<CalibrationNotifier, MultipleSensorData?>(
      (ref) => CalibrationNotifier(ref),
    );

// Providers auxiliares
final calibrationProgressProvider = StateProvider<double>((ref) => 0.0);
final calibrationRunningProvider = StateProvider<bool>((ref) => false);

class CalibrationNotifier extends StateNotifier<MultipleSensorData?> {
  final Ref ref;
  final List<MultipleSensorData> _lastTen = [];

  CalibrationNotifier(this.ref) : super(null) {
    _loadLastCalibration();
  }

  Future<void> _loadLastCalibration() async {
    try {
      final lastCalibration = await ref
          .read(firestoreServiceProvider)
          .getLastCalibrationData();
      if (lastCalibration != null) {
        state = MultipleSensorData(lastCalibration);
        print('✅ Calibración restaurada desde Firestore');
      }
    } catch (e) {
      print('⚠️ No se pudo restaurar la calibración: $e');
    }
  }

  Future<void> calibrate() async {
    final device = ref.read(connectedDeviceProvider);
    if (device == null) return;

    final sensors = SensorsBle();
    _lastTen.clear();

    ref.read(calibrationRunningProvider.notifier).state = true;

    // Recolectar 10 muestras
    await for (final data in sensors.subscribeToMultipleSensors(device)) {
      _lastTen.add(data);
      if (_lastTen.length > 10) _lastTen.removeAt(0);

      ref.read(calibrationProgressProvider.notifier).state =
          _lastTen.length / 10;

      if (_lastTen.length == 10) break;
    }

    // Calcular promedios individuales por sensor
    final Map<int, PostureData> calibrationData = {};
    if (_lastTen.isNotEmpty) {
      // Obtener todos los IDs de sensor detectados
      final allSensorIds = _lastTen.fold<Set<int>>(
        {},
        (set, data) => set..addAll(data.sensorsData.keys),
      );

      for (final sensorId in allSensorIds) {
        final pitchValues = _lastTen
            .where((data) => data.sensorsData.containsKey(sensorId))
            .map((data) => data.sensorsData[sensorId]!.pitch)
            .toList();

        final rollValues = _lastTen
            .where((data) => data.sensorsData.containsKey(sensorId))
            .map((data) => data.sensorsData[sensorId]!.roll)
            .toList();

        if (pitchValues.isNotEmpty && rollValues.isNotEmpty) {
          final avgPitch =
              pitchValues.reduce((a, b) => a + b) / pitchValues.length;
          final avgRoll =
              rollValues.reduce((a, b) => a + b) / rollValues.length;

          calibrationData[sensorId] = PostureData(
            sensorId: sensorId,
            pitch: avgPitch,
            roll: avgRoll,
          );
        }
      }
    }

    // Almacenar el resultado de la calibración (promedios individuales)
    state = MultipleSensorData(calibrationData);

    // Guardar en Firestore
    if (calibrationData.isNotEmpty) {
      try {
        await ref
            .read(firestoreServiceProvider)
            .saveCalibrationData(calibrationData);
      } catch (e) {
        print('Error al guardar calibración: $e');
        // Opcional: mostrar error al usuario
      }
    }

    ref.read(calibrationRunningProvider.notifier).state = false;
  }
}
