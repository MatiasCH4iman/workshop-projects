import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const RcSumoApp());

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
    requestBluetoothPermissions();
  }

  // 🔐 Pedir permisos de Bluetooth (Android 12+)
  Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location
    ].request();
  }

  // 🔌 Conectar al robot
  Future<void> connectToRobot() async {
    setState(() {
      isConnecting = true;
      robotStatus = "Conectando...";
    });

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final espDevice = devices.firstWhere(
        (d) => d.name == "RC_SUMO",
        orElse: () => devices.isNotEmpty ? devices.first : throw Exception("No se encontraron dispositivos."),
      );

      connection = await BluetoothConnection.toAddress(espDevice.address);
      setState(() {
        robotStatus = "Conectado a ${espDevice.name}";
        isConnecting = false;
        isConnected = true;
      });

      connection!.input!.listen((Uint8List data) {
        String received = String.fromCharCodes(data);
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

  // 🚀 Enviar comandos
  void sendCommand(String command) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList("$command\n".codeUnits));
      connection!.output.allSent;
      debugPrint("➡️ Comando enviado: $command");
    } else {
      debugPrint("⚠️ No conectado");
      setState(() => robotStatus = "No conectado");
    }
  }

  // 🎯 Botones de dirección
  Widget directionButton(IconData icon, String command) {
    return ElevatedButton(
      onPressed: isConnected ? () => sendCommand(command) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(28),
        shape: const CircleBorder(),
      ),
      child: Icon(icon, size: 36),
    );
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
      appBar: AppBar(title: const Text('RC SUMO')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isConnecting ? null : connectToRobot,
              child: Text(isConnecting
                  ? 'Conectando...'
                  : isConnected
                      ? 'Conectado'
                      : 'Conectar'),
            ),
            const SizedBox(height: 10),
            Text('🔹 Estado: $robotStatus'),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      directionButton(Icons.arrow_upward, "F"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          directionButton(Icons.arrow_back, "L"),
                          const SizedBox(width: 20),
                          directionButton(Icons.arrow_forward, "R"),
                        ],
                      ),
                      directionButton(Icons.arrow_downward, "B"),
                    ],
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                    ),
                    child: const Center(child: Text('Joystick')),
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
