import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neoposture/entities/providers/ble_provider.dart';

/// Pantalla de configuración que demuestra cómo acceder al estado del BLE
/// desde cualquier parte de la aplicación usando Riverpod
class ConfigScreen extends ConsumerWidget {
  static const String name = 'config';
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accedemos a todos los datos del BLE desde los providers
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final contador = ref.watch(contadorProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final isScanning = ref.watch(isScanningProvider);
    final isDeviceOn = ref.watch(isDeviceOnProvider);
    final devices = ref.watch(devicesProvider);
    final bleNotifier = ref.read(bleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              GoRouter.of(context).pushReplacementNamed('dashboard');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del dispositivo conectado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del Dispositivo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Conectado: ${isConnected ? "Sí" : "No"}'),
                    if (connectedDevice != null) ...[
                      Text('Dispositivo: ${connectedDevice.platformName.isNotEmpty ? connectedDevice.platformName : "Sin nombre"}'),
                      Text('ID: ${connectedDevice.remoteId}'),
                      Text('Estado: ${isDeviceOn ? "Encendido" : "Apagado"}'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Datos del sensor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del Sensor',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (contador != null)
                      Text(
                        'Contador actual: $contador',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      )
                    else
                      const Text('No hay datos del sensor disponibles'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Estado del escaneo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del Escaneo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Escaneando: ${isScanning ? "Sí" : "No"}'),
                    Text('Dispositivos encontrados: ${devices.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de control
            if (isConnected) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await bleNotifier.toggleDevice();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isDeviceOn 
                                ? 'Dispositivo apagado' 
                                : 'Dispositivo encendido'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeviceOn ? Colors.red : Colors.green,
                  ),
                  child: Text(
                    isDeviceOn ? 'Apagar Dispositivo' : 'Encender Dispositivo',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await bleNotifier.disconnectDevice();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dispositivo desconectado')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Desconectar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isScanning ? null : () async {
                    try {
                      await bleNotifier.scanDevices();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escaneando dispositivos...')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isScanning ? 'Escaneando...' : 'Buscar Dispositivos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
