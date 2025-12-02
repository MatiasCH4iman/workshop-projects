import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../providers/ble_provider.dart';
import '../providers/calibration_provider.dart';
import 'firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final posturePersistenceProvider = Provider<PosturePersistenceService>((ref) {
  return PosturePersistenceService(ref);
});

class PosturePersistenceService {
  final Ref ref;
  Timer? _timer;
  bool _isActive = false;

  PosturePersistenceService(this.ref) {
    _init();
  }

  void _init() {
    // Escuchar cambios en la conexión para iniciar/detener el guardado
    ref.listen(connectedDeviceProvider, (previous, next) {
      if (next != null && !_isActive) {
        _startSaving();
      } else if (next == null && _isActive) {
        _stopSaving();
      }
    });
  }

  void _startSaving() {
    print('💾 Iniciando guardado periódico de postura...');
    _isActive = true;
    // Guardar cada 1 minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _saveCurrentPosture();
    });
  }

  void _stopSaving() {
    print('🛑 Deteniendo guardado periódico de postura...');
    _isActive = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _saveCurrentPosture() async {
    try {
      // Obtener el valor actual del stream de datos
      final asyncData = ref.read(multiSensorDataProvider);
      // Obtener la calibración actual
      final calibrationData = ref.read(calibrationProvider);

      asyncData.when(
        data: (data) {
          if (data.sensorsData.isNotEmpty) {
            String postureState = 'Good';

            // Si tenemos calibración, comparamos
            if (calibrationData != null) {
              bool isBad = false;
              bool isWarning = false;

              for (final sensorId in data.sensorsData.keys) {
                if (calibrationData.sensorsData.containsKey(sensorId)) {
                  final current = data.sensorsData[sensorId]!;
                  final calibrated = calibrationData.sensorsData[sensorId]!;

                  final pitchDiff = (current.pitch - calibrated.pitch).abs();
                  final rollDiff = (current.roll - calibrated.roll).abs();

                  // Umbrales coincidentes con la UI (PrintScreen)
                  // > 8 grados = Mala (Rojo)
                  // > 4 grados = Regular (Amarillo)
                  if (pitchDiff > 8 || rollDiff > 8) {
                    isBad = true;
                    // No hacemos break aquí para evaluar todos,
                    // pero para el estado general 'Bad' gana.
                  } else if (pitchDiff > 4 || rollDiff > 4) {
                    isWarning = true;
                  }
                }
              }

              if (isBad) {
                postureState = 'Bad';
              } else if (isWarning) {
                postureState = 'Warning';
              }
            } else {
              postureState = 'Uncalibrated';
            }

            ref
                .read(firestoreServiceProvider)
                .savePostureData(data, postureState);
          }
        },
        error: (err, stack) =>
            print('Error obteniendo datos para guardar: $err'),
        loading: () => null, // No hay datos aún
      );
    } catch (e) {
      print('Error en _saveCurrentPosture: $e');
    }
  }
}
