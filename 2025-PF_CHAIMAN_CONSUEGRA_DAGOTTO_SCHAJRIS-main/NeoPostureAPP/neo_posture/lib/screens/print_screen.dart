import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../entities/multi_sensor.dart';
import '../providers/ble_provider.dart';
import '../providers/calibration_provider.dart';

final showValuesProvider = StateProvider<bool>((ref) => false);

class PrintScreen extends ConsumerStatefulWidget {
  static const String name = 'print_screen';
  const PrintScreen({super.key});

  @override
  ConsumerState<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends ConsumerState<PrintScreen> {
  // Definición de umbrales para el feedback de color
  static const double _threshold = 8; // ROJO
  static const double _minorThreshold = _threshold / 2; // AMARILLO

  // Mapeo de ID de sensor a nombre/ubicación
  // Esto asume una asignación de IDs de sensor consistente en el firmware de ESP32
  // donde ID 1 (0x69 Wire) es Hombro Derecho, ID 0 (0x68 Wire) es Cuello, etc.
  static const Map<int, String> SENSOR_LOCATIONS = {
    // Estas IDs son las que el ESP32 debe enviar.
    // Usando la convención (Bus, Dir) -> (ID):
    // ID 0 (Asumido como Wire 0x68): Cuello
    // ID 1 (Asumido como Wire 0x69): Hombro Derecho
    // ID 2 (Asumido como Wire1 0x68): Espalda Media
    // ID 3 (Asumido como Wire1 0x69): Hombro Izquierdo
    0: 'Cuello (0x68 Wire)',
    1: 'Hombro Derecho (0x69 Wire)',
    2: 'Espalda Media (0x68 Wire1)',
    3: 'Hombro Izquierdo (0x69 Wire1)',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
  }

  void _checkConnection() {
    final connectedDevice = ref.read(connectedDeviceProvider);
    if (connectedDevice == null && mounted) {
      context.go('/connection');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Dispositivo desconectado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getSensorName(int sensorId) {
    return SENSOR_LOCATIONS[sensorId] ?? 'Sensor $sensorId (Desconocido)';
  }

  // Lógica para asignar un color de postura basado en la diferencia (Pitch o Roll)
  Color getPostureColor(double diff) {
    final absDiff = diff.abs();
    if (absDiff >= _threshold) {
      return Colors.red; // Mala postura
    } else if (absDiff >= _minorThreshold) {
      return Colors.yellow[700]!; // Precaución
    } else {
      return Colors.green; // Buena postura
    }
  }

  // Se mantiene la función para la imagen principal (promedio)
  String getPostureImage(
    double pitch,
    double roll,
    double pitchCal,
    double rollCal,
  ) {
    final pitchDiff = pitch - pitchCal;
    final rollDiff = roll - rollCal;

    // Nota: El umbral usado aquí debe coincidir con los umbrales de color (_threshold)
    const threshold = _threshold;
    const minorThreshold = _minorThreshold;

    if (pitchDiff.abs() < minorThreshold && rollDiff.abs() < minorThreshold) {
      return 'images/espalda_ok.png';
    }
    if (pitchDiff.abs() > threshold && rollDiff.abs() > threshold) {
      return 'images/espalda_mal.png';
    }
    if (pitchDiff.abs() > threshold) {
      if (rollDiff > threshold) return 'images/espalda_sup_mal_inf_bien.png';
      if (rollDiff < -threshold) return 'images/espalda_sup_bien_inf_mal.png';
      return 'images/espalda_mas_o_menos.png';
    }
    if (rollDiff.abs() > threshold) {
      return rollDiff > 0
          ? 'images/espalda_derecha_mal.png'
          : 'images/espalda_izquierda_mal.png';
    }
    return 'images/espalda_mas_o_menos.png';
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final calibration = ref.watch(calibrationProvider);
    final calibrationRunning = ref.watch(calibrationRunningProvider);
    final progress = ref.watch(calibrationProgressProvider);
    final showValues = ref.watch(showValuesProvider);

    if (connectedDevice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Print Screen')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay dispositivo conectado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/connection'),
                child: const Text('Volver a Conectar'),
              ),
            ],
          ),
        ),
      );
    }

    final asyncState = ref.watch(multiSensorStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores | NeoPosture'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '✅ ${connectedDevice.platformName}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Opciones',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Calibración'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(calibrationProvider.notifier).calibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Calibración completada')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Mostrar valores Pitch/Roll'),
              value: showValues,
              onChanged: (val) =>
                  ref.read(showValuesProvider.notifier).state = val,
              secondary: const Icon(Icons.remove_red_eye),
            ),
            if (calibrationRunning)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Calibrando...'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Desconectar'),
              onTap: () {
                ref.read(bleProvider.notifier).disconnect();
                Navigator.pop(context);
                context.go('/connection');
              },
            ),
          ],
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/connection'),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.data == null)
            return const Center(child: CircularProgressIndicator());

          final multiData = state.data!;

          // Uso del promedio general (asumiendo que si se usó la calibración anterior,
          // los campos avgPitch/avgRoll del MultipleSensorData de Calibración son correctos,
          // aunque idealmente ahora se usarían los valores individuales).
          final pitchCalAvg = calibration?.avgPitch ?? 0.0;
          final rollCalAvg = calibration?.avgRoll ?? 0.0;

          final imagePath = getPostureImage(
            multiData.avgPitch,
            multiData.avgRoll,
            pitchCalAvg,
            rollCalAvg,
          );

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(imagePath, width: 350, height: 350),
                  const SizedBox(height: 16),
                  if (showValues) ...[
                    // Sección de Promedio General (sin cambios en su cálculo)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PROMEDIO DE SENSORES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pitch: ${(multiData.avgPitch - pitchCalAvg).toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Roll: ${(multiData.avgRoll - rollCalAvg).toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sensores activos: ${multiData.sensorsData.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DATOS INDIVIDUALES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tabla de Datos Individuales actualizada
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Ubicación')),
                          DataColumn(label: Text('Pitch')),
                          DataColumn(label: Text('Roll')),
                          DataColumn(label: Text('Estado')),
                        ],
                        rows: multiData.sensorsData.entries.map((e) {
                          final data = e.value;

                          // Obtener calibración individual (si existe, sino 0.0)
                          final calData =
                              calibration?.sensorsData[data.sensorId];
                          final pitchCal = calData?.pitch ?? 0.0;
                          final rollCal = calData?.roll ?? 0.0;

                          // Calcular diferencia
                          final pitchDiff = data.pitch - pitchCal;
                          final rollDiff = data.roll - rollCal;

                          // Determinar colores
                          final pitchColor = getPostureColor(pitchDiff);
                          final rollColor = getPostureColor(rollDiff);

                          // Determinar estado general (el peor de Pitch o Roll)
                          final worstColor =
                              pitchColor == Colors.red ||
                                  rollColor == Colors.red
                              ? Colors.red
                              : (pitchColor == Colors.yellow[700] ||
                                        rollColor == Colors.yellow[700]
                                    ? Colors.yellow[700]
                                    : Colors.green);

                          return DataRow(
                            cells: [
                              DataCell(Text(getSensorName(data.sensorId))),
                              DataCell(
                                Text(
                                  '${pitchDiff.toStringAsFixed(2)}°',
                                  style: TextStyle(
                                    color: pitchColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${rollDiff.toStringAsFixed(2)}°',
                                  style: TextStyle(
                                    color: rollColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Tooltip(
                                  message:
                                      'Pitch: ${pitchDiff.toStringAsFixed(1)}°, Roll: ${rollDiff.toStringAsFixed(1)}°',
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: worstColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: worstColor!.withOpacity(0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
