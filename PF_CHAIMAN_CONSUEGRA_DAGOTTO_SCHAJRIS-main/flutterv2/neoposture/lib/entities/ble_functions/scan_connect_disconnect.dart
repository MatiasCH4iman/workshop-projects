import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:neoposture/entities/ble_controller.dart';
import 'package:neoposture/entities/ble_com/get_ble.dart';

// Método para escanear dispositivos BLE cercanos
Future<void> scanNearbyDevices({
  required BleController controller,
  required Function(List<ScanResult>) onResults,
  required BuildContext context,
  required Function(bool) onScanning,
}) async {
  onScanning(true);
  try {
    final results = await controller.scanNearbyDevices();
    onResults(results);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
  onScanning(false);
}

// Método para conectar o desconectar un dispositivo BLE
Future<void> connectOrDisconnect({
  required BluetoothDevice device,
  required BluetoothDevice? connectedDevice,
  required BleController controller,
  required GetBle getBle,
  required Function(BluetoothDevice?) onConnectedDevice,
  required Function(int?) onContador,
  required StreamSubscription<int>? contadorSub,
  required Function(StreamSubscription<int>?) onContadorSub,
  required BuildContext context,
  required Function(bool) onConnecting,
}) async {
  if (connectedDevice?.remoteId == device.remoteId) {
    // Si ya está conectado, desconecta
    await device.disconnect();
    onConnectedDevice(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Desconectado de ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}')),
    );
    return;
  }

  onConnecting(true);
  try {
    await controller.connectToDevice(device); // Intenta conectar al dispositivo
    onConnectedDevice(device);
    contadorSub?.cancel();
    onContador(null);
    final stream = getBle.subscribeToCounter(device);
    final sub = stream.listen((valor) {
      onContador(valor);
    });
    onContadorSub(sub);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Conectado a ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al conectar: $e')),
    );
  }
  onConnecting(false);
}