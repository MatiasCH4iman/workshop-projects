import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neoposture/entities/providers/ble_provider.dart';

/// Widget reutilizable que muestra el estado actual del contador
/// Puede usarse en cualquier pantalla para mostrar datos del sensor en tiempo real
class ContadorWidget extends ConsumerWidget {
  final bool showDeviceInfo;
  final double fontSize;
  
  const ContadorWidget({
    super.key,
    this.showDeviceInfo = false,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado del contador, conexión y dispositivo
    final contador = ref.watch(contadorProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final isDeviceOn = ref.watch(isDeviceOnProvider);
    final isConnected = connectedDevice != null;
    
    // ==================== LÓGICA DE VISIBILIDAD ====================
    // Solo mostrar el contador si:
    // 1. Hay un dispositivo conectado
    // 2. El dispositivo está encendido
    // 3. Hay datos del contador disponibles
    if (!isConnected || !isDeviceOn || contador == null) {
      return const SizedBox.shrink(); // No mostrar nada
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono del sensor
            Icon(
              Icons.sensors,
              size: 32,
              color: isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            
            // Valor del contador
            Text(
              'Contador: $contador',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.black : Colors.grey,
              ),
            ),
            
            // Información adicional del dispositivo (opcional)
            if (showDeviceInfo) ...[
              const SizedBox(height: 8),
              Text(
                'Dispositivo: ${connectedDevice.platformName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Estado: ${isDeviceOn ? "Encendido" : "Apagado"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDeviceOn ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget que muestra una lista de todos los dispositivos encontrados
/// Útil para crear pantallas de selección de dispositivos
class DeviceListWidget extends ConsumerWidget {
  final Function(String)? onDeviceSelected;
  
  const DeviceListWidget({
    super.key,
    this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final isScanning = ref.watch(isScanningProvider);
    final isConnecting = ref.watch(isConnectingProvider);
    final bleNotifier = ref.read(bleProvider.notifier);

    if (devices.isEmpty && !isScanning) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No hay dispositivos disponibles'),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Dispositivos BLE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          ...devices.map((result) {
            final name = result.advertisementData.advName.isNotEmpty
                ? result.advertisementData.advName
                : result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : "Dispositivo desconocido";
            final isConnected = connectedDevice?.remoteId == result.device.remoteId;
            
            return ListTile(
              leading: Icon(
                Icons.bluetooth,
                color: isConnected ? Colors.green : Colors.blue,
              ),
              title: Text(name),
              subtitle: Text(result.device.remoteId.toString()),
              trailing: isConnected 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: (isConnecting || isScanning) ? null : () async {
                try {
                  await bleNotifier.connectOrDisconnect(result.device);
                  onDeviceSelected?.call(name);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
