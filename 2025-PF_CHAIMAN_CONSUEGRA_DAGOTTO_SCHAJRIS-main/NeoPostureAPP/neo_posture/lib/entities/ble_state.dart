import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleState {
  final bool isScanning;
  final List<ScanResult> devices;
  final BluetoothDevice? connectedDevice;
  final String? errorMessage;

  const BleState({
    this.isScanning = false,
    this.devices = const [],
    this.connectedDevice,
    this.errorMessage,
  });

  BleState copyWith({
    bool? isScanning,
    List<ScanResult>? devices,
    BluetoothDevice? connectedDevice,
    String? errorMessage,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage,
    );
  }
}
