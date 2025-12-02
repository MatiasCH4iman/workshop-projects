import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/sensor.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda los datos de calibración en la colección 'calibration_data'
  Future<void> saveCalibrationData(
    Map<int, PostureData> calibrationData,
  ) async {
    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      // Guardamos un documento principal con metadatos si es necesario,
      // o simplemente guardamos cada sensor como un documento o un campo.
      // Aquí guardaremos un documento por evento de calibración con un mapa de sensores.

      final docRef = _firestore
          .collection('calibration_data')
          .doc(timestamp.toIso8601String());

      final Map<String, dynamic> data = {
        'timestamp': timestamp,
        'sensors': calibrationData.map(
          (key, value) => MapEntry(key.toString(), {
            'pitch': value.pitch,
            'roll': value.roll,
            'sensorId': value.sensorId,
          }),
        ),
      };

      batch.set(docRef, data);
      await batch.commit();
      print('✅ Datos de calibración guardados en Firestore');
    } catch (e) {
      print('❌ Error guardando calibración: $e');
      rethrow;
    }
  }

  /// Guarda los datos de postura en la colección 'posture_data'
  Future<void> savePostureData(
    MultipleSensorData data,
    String postureState,
  ) async {
    if (data.sensorsData.isEmpty) return;

    try {
      final timestamp = DateTime.now();
      final docRef = _firestore
          .collection('posture_data')
          .doc(timestamp.toIso8601String());

      final Map<String, dynamic> saveData = {
        'timestamp': timestamp,
        'state': postureState, // Estado de la postura (Good/Bad)
        'sensors': data.sensorsData.map(
          (key, value) => MapEntry(key.toString(), {
            'pitch': value.pitch,
            'roll': value.roll,
            'sensorId': value.sensorId,
          }),
        ),
      };

      await docRef.set(saveData);
      print(
        '✅ Datos de postura guardados ($postureState): ${timestamp.toLocal()}',
      );
    } catch (e) {
      print('❌ Error guardando postura: $e');
      // No rethrow para no interrumpir el flujo principal si falla el guardado periódico
    }
  }

  /// Recupera la última calibración guardada
  Future<Map<int, PostureData>?> getLastCalibrationData() async {
    try {
      final snapshot = await _firestore
          .collection('calibration_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final sensorsMap = data['sensors'] as Map<String, dynamic>;

      return sensorsMap.map((key, value) {
        final sensorData = value as Map<String, dynamic>;
        final sensorId = int.parse(key);
        return MapEntry(
          sensorId,
          PostureData(
            sensorId: sensorId,
            pitch: (sensorData['pitch'] as num).toDouble(),
            roll: (sensorData['roll'] as num).toDouble(),
          ),
        );
      });
    } catch (e) {
      print('❌ Error recuperando calibración: $e');
      return null;
    }
  }
}
