import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neo_posture/providers/ble_provider.dart';


class ConnectionScreen extends ConsumerStatefulWidget {
  static const String name = 'connection_screen';

  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  
  void _handleScanError(Object error) {
    String errorMsg = error.toString();
    
    if (errorMsg.contains('user gesture') || errorMsg.contains('Must be handling')) {
      errorMsg = '⚠️ Debes hacer click en "Buscar" para activar BLE\n\n(Chrome requiere gesto del usuario)';
    } else if (errorMsg.contains('NotSupportedError') || errorMsg.contains('HTTPS')) {
      errorMsg = '⚠️ HTTPS requerido para BLE en producción\n\nlocalhost funciona en desarrollo';
    } else if (errorMsg.contains('NotAllowedError')) {
      errorMsg = '❌ Permiso denegado por el usuario';
    } else if (errorMsg.contains('NotFoundError')) {
      errorMsg = '❌ No se encontraron dispositivos BLE';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// IMPORTANTE: Llamar DIRECTAMENTE desde onPressed (gesto del usuario)
  Future<void> _startScan() async {
    try {
      final bleNotifier = ref.read(bleProvider.notifier);
      await bleNotifier.scanForDevices();
    } catch (e) {
      _handleScanError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    final isScanning = bleState.isScanning;
    final devices = bleState.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeoPosture'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Botón PRINCIPAL para escanear (requiere gesto del usuario)
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _startScan,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(isScanning ? 'Buscando...' : 'Buscar Dispositivos'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Info para Web
                if (kIsWeb)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '💡 Modo Web (Chrome)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Haz click en "Buscar Dispositivos" para que Chrome te pida permiso de Bluetooth.',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isScanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos\n\nHaz click en "Buscar" para empezar',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index].device;
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Dispositivo ${index + 1}';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () async {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Conectando...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              await ref
                                  .read(bleProvider.notifier)
                                  .connectToDevice(device);
                              if (mounted) {
                                context.go('/print');
                              }
                            } catch (e) {
                              _handleScanError(e);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}