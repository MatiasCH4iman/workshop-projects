import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neoposture/presentation/widgets/ble_widgets.dart';
import 'package:neoposture/entities/providers/ble_provider.dart';

/// Pantalla de dashboard
class DashboardScreen extends ConsumerWidget {
  static const String name = 'dashboard';
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);
    final isDeviceOn = ref.watch(isDeviceOnProvider);
    final bleNotifier = ref.read(bleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await bleNotifier.scanDevices();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.lightGreen,
              ),
              child: Text(
                'NeoPosture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).pushNamed('config');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget del contador
            const ContadorWidget(
              showDeviceInfo: true,
              fontSize: 32,
            ),
            
            // Mensaje cuando el dispositivo está apagado
            if (isConnected && !isDeviceOn)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Dispositivo apagado',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Información rápida del estado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusItem(
                      icon: Icons.bluetooth,
                      label: 'BLE',
                      value: isConnected ? 'Conectado' : 'Desconectado',
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isScanning = ref.watch(isScanningProvider);
                        return _StatusItem(
                          icon: Icons.search,
                          label: 'Escaneo',
                          value: isScanning ? 'Activo' : 'Inactivo',
                          color: isScanning ? Colors.blue : Colors.grey,
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isDeviceOn = ref.watch(isDeviceOnProvider);
                        return _StatusItem(
                          icon: Icons.power_settings_new,
                          label: 'Dispositivo',
                          value: isConnected ? (isDeviceOn ? 'ON' : 'OFF') : 'N/A',
                          color: isConnected 
                              ? (isDeviceOn ? Colors.green : Colors.orange)
                              : Colors.grey,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de dispositivos - Solo mostrar cuando hay dispositivos disponibles
            Consumer(
              builder: (context, ref, _) {
                final devices = ref.watch(devicesProvider);
                final isScanning = ref.watch(isScanningProvider);
                
                final shouldShowList = (!isConnected && (devices.isNotEmpty || isScanning)) || 
                                      isScanning;
                
                if (shouldShowList) {
                  return Expanded(
                    child: Column(
                      children: [
                        // Título de la lista
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            isScanning 
                                ? 'Buscando dispositivos...' 
                                : 'Dispositivos encontrados (${devices.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Lista de dispositivos
                        Expanded(
                          child: DeviceListWidget(
                            onDeviceSelected: (deviceName) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Conectado a $deviceName')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Espacio flexible cuando no hay lista
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isConnected) ...[
                            const Icon(
                              Icons.bluetooth_connected,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'NeoPosture está conectado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Usa "Configuración" para gestionar la conexión',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Icon(
                              Icons.bluetooth_searching,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay dispositivos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Presiona "Buscar Dispositivos" para encontrar dispositivos BLE',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botón de búsqueda solo cuando no está conectado
            if (!isConnected) ...[
              SizedBox(
                width: double.infinity,
                child: Consumer(
                  builder: (context, ref, _) {
                    final isScanning = ref.watch(isScanningProvider);
                    return ElevatedButton.icon(
                      onPressed: isScanning ? null : () async {
                        await bleNotifier.scanDevices();
                      },
                      icon: Icon(isScanning ? Icons.hourglass_empty : Icons.search),
                      label: Text(isScanning ? 'Escaneando...' : 'Buscar Dispositivos'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }
}
