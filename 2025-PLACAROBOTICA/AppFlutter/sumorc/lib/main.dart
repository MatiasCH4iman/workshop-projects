import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const RcSumoApp());
}

class RcSumoApp extends StatelessWidget {
  const RcSumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC SUMO',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const RcSumoHome(),
    );
  }
}

class RcSumoHome extends StatefulWidget {
  const RcSumoHome({super.key});

  @override
  State<RcSumoHome> createState() => _RcSumoHomeState();
}

class _RcSumoHomeState extends State<RcSumoHome> {
  BluetoothConnection? connection;
  String robotStatus = "Desconectado";
  bool isConnecting = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// 🧩 Pide permisos de Bluetooth y ubicación
  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes otorgar permisos Bluetooth para continuar.'),
        ),
      );
    }
  }

  /// 🔹 Conecta al ESP32 por Bluetooth
  Future<void> connectToRobot() async {
    setState(() {
      isConnecting = true;
      robotStatus = "Conectando...";
    });

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();

      final espDevice = devices.firstWhere(
        (d) => d.name == "SumoBot",
        orElse: () => throw Exception("No se encontró 'SumoBot' emparejado."),
      );

      connection = await BluetoothConnection.toAddress(espDevice.address);
      setState(() {
        robotStatus = "Conectado a ${espDevice.name}";
        isConnecting = false;
        isConnected = true;
      });

      connection!.input!.listen((Uint8List data) {
        String received = utf8.decode(data);
        debugPrint('📩 Recibido: $received');
      }).onDone(() {
        setState(() {
          robotStatus = "Desconectado";
          isConnected = false;
        });
      });
    } catch (e) {
      setState(() {
        robotStatus = "Error de conexión";
        isConnecting = false;
        isConnected = false;
      });
      debugPrint("❌ Error: $e");
    }
  }

  /// 🔹 Envía comandos simples: F, B, L, R, S
  void sendCommand(String command) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(command.codeUnits));
      connection!.output.allSent;
      debugPrint("➡️ Comando enviado: $command");
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    connection = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('😎Cachafaz RC')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 Estado y conexión
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: isConnecting ? null : connectToRobot,
                    icon: const Icon(Icons.bluetooth),
                    label: Text(isConnecting
                        ? 'Conectando...'
                        : isConnected
                            ? 'Conectado'
                            : 'Conectar'),
                  ),
                  const SizedBox(height: 8),
                  Text('🔹 Estado: $robotStatus'),
                ],
              ),
            ),

            // 🎮 Joystick centrado
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 250,
                  width: 250,
                  child: Joystick(
                    mode: JoystickMode.all,
                    listener: (details) {
                      if (!isConnected) return;

                      double x = details.x;
                      double y = details.y;

                      if (y > 0.5) {
                        sendCommand("F");
                      } else if (y < -0.5) {
                        sendCommand("B");
                      } else if (x > 0.5) {
                        sendCommand("R");
                      } else if (x < -0.5) {
                        sendCommand("L");
                      } else {
                        sendCommand("S");
                      }
                    },
                  ),
                ),
              ),
            ),

            // 🔘 Flechitas direccionales
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isConnected ? () => sendCommand("F") : null,
                        child: const Icon(Icons.keyboard_arrow_up, size: 36),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isConnected ? () => sendCommand("L") : null,
                        child: const Icon(Icons.keyboard_arrow_left, size: 36),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isConnected ? () => sendCommand("S") : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Icon(Icons.stop, size: 36),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isConnected ? () => sendCommand("R") : null,
                        child: const Icon(Icons.keyboard_arrow_right, size: 36),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isConnected ? () => sendCommand("B") : null,
                        child: const Icon(Icons.keyboard_arrow_down, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
