# README.md

# NeoPosture

NeoPosture is a Flutter application designed to manage Bluetooth Low Energy (BLE) devices, specifically focusing on the ESP32 Bluetooth device. This project aims to provide a user-friendly interface for scanning, connecting, and interacting with BLE devices.

## Project Structure

The project is organized into several directories to promote clean code and separation of concerns:

```
neoposture
├── lib
│   ├── core
│   │   └── router
│   │       └── app_router.dart
│   ├── entities
│   │   ├── ble_controller.dart
│   │   ├── esp32_device.dart
│   │   ├── notification.dart
│   │   └── device.dart
│   ├── presentation
│   │   └── screens
│   │       ├── ble_screen.dart
│   │       └── device_screen.dart
│   ├── services
│   │   └── bluetooth_service.dart
│   ├── main.dart
├── pubspec.yaml
└── README.md
```

## Features

- **BLE Device Management**: Scan, connect, and manage BLE devices.
- **ESP32 Specific Functionality**: Dedicated handling for ESP32 devices, including connection management and state handling.
- **User Interface**: Intuitive UI for interacting with BLE devices.

## Getting Started

To get started with the NeoPosture project, follow these steps:

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd neoposture
   ```

3. Install the dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## Contributing

