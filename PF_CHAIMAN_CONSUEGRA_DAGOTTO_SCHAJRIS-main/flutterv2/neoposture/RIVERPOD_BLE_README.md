# Sistema de Providers BLE con Riverpod

Este proyecto implementa un sistema de gestión de estado global para dispositivos Bluetooth Low Energy (BLE) usando **Riverpod** en Flutter.

## 🏗️ Arquitectura

### Providers Principales

#### `bleProvider` - Provider Principal
Maneja todo el estado relacionado con BLE:
- Escaneo de dispositivos
- Conexión/desconexión de dispositivos
- Suscripción a datos del sensor
- Control de encendido/apagado
- Escaneo automático cada 5 segundos

#### Providers Derivados
Estos providers te dan acceso fácil a partes específicas del estado:

```dart
// Lista de dispositivos encontrados
final devices = ref.watch(devicesProvider);

// Dispositivo actualmente conectado
final connectedDevice = ref.watch(connectedDeviceProvider);

// Valor actual del contador del sensor
final contador = ref.watch(contadorProvider);

// Estados booleanos
final isScanning = ref.watch(isScanningProvider);
final isConnecting = ref.watch(isConnectingProvider);
final isConnected = ref.watch(isConnectedProvider);
final isDeviceOn = ref.watch(isDeviceOnProvider);
```

## 🎯 Cómo Usar los Providers

### 1. En un Widget ConsumerWidget

```dart
class MiWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado
    final contador = ref.watch(contadorProvider);
    final isConnected = ref.watch(isConnectedProvider);
    
    // Obtener el notifier para acciones
    final bleNotifier = ref.read(bleProvider.notifier);
    
    return Column(
      children: [
        Text('Contador: ${contador ?? "Sin datos"}'),
        ElevatedButton(
          onPressed: isConnected ? null : () {
            bleNotifier.scanDevices();
          },
          child: Text('Buscar dispositivos'),
        ),
      ],
    );
  }
}
```

### 2. En un StatefulWidget con Consumer

```dart
class MiWidget extends StatefulWidget {
  @override
  _MiWidgetState createState() => _MiWidgetState();
}

class _MiWidgetState extends State<MiWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final contador = ref.watch(contadorProvider);
        final bleNotifier = ref.read(bleProvider.notifier);
        
        return Text('Contador: ${contador ?? "Sin datos"}');
      },
    );
  }
}
```

### 3. Usando Consumer para partes específicas

```dart
// Solo se reconstruye cuando cambia el contador
Consumer(
  builder: (context, ref, _) {
    final contador = ref.watch(contadorProvider);
    return Text('Contador: $contador');
  },
)
```

## 🎬 Acciones Disponibles

### Escanear Dispositivos
```dart
final bleNotifier = ref.read(bleProvider.notifier);
await bleNotifier.scanDevices();
```

### Conectar/Desconectar Dispositivo
```dart
final bleNotifier = ref.read(bleProvider.notifier);
await bleNotifier.connectOrDisconnect(device);
```

### Encender/Apagar Dispositivo
```dart
final bleNotifier = ref.read(bleProvider.notifier);
await bleNotifier.toggleDevice(timeCheck: 5000); // timeCheck opcional
```

### Desconectar Dispositivo Actual
```dart
final bleNotifier = ref.read(bleProvider.notifier);
await bleNotifier.disconnectDevice();
```

## 🧩 Widgets Reutilizables

### ContadorWidget
Muestra el valor del contador en tiempo real:

```dart
ContadorWidget(
  showDeviceInfo: true,  // Mostrar info del dispositivo
  fontSize: 32,          // Tamaño de fuente
)
```

### DeviceListWidget
Lista todos los dispositivos encontrados:

```dart
DeviceListWidget(
  onDeviceSelected: (deviceName) {
    print('Conectado a $deviceName');
  },
)
```

## 📱 Pantallas de Ejemplo

### DashboardScreen
Pantalla principal que muestra:
- Estado del contador en tiempo real
- Lista de dispositivos
- Controles de conexión y escaneo
- Navegación entre pantallas

### BleScreen
Pantalla original adaptada para usar Riverpod:
- Lista de dispositivos con estado de conexión
- Botones de escaneo y control
- Notificaciones de estado

### ConfigScreen
Pantalla de configuración que demuestra:
- Acceso al estado global desde cualquier pantalla
- Información detallada del dispositivo
- Controles de gestión

## 🚀 Beneficios del Sistema

### ✅ Estado Global
- El estado del BLE es accesible desde cualquier pantalla
- No necesitas pasar datos entre widgets
- Estado consistente en toda la aplicación

### ✅ Reactividad Automática
- Los widgets se actualizan automáticamente cuando cambia el estado
- No necesitas gestionar manualmente setState()
- Actualizaciones granulares (solo se reconstruye lo necesario)

### ✅ Reutilización
- Widgets reutilizables para mostrar datos del BLE
- Lógica de negocio centralizada
- Fácil mantenimiento y testing

### ✅ Gestión de Recursos
- Limpieza automática de suscripciones
- Gestión eficiente de conexiones BLE
- Escaneo automático inteligente

## 🔧 Configuración Inicial

1. **Asegurar ProviderScope en main.dart:**
```dart
void main() {
  runApp(const ProviderScope(child: MainApp()));
}
```

2. **Usar ConsumerWidget o Consumer:**
```dart
class MiPantalla extends ConsumerWidget {
  // Tu código aquí
}
```

3. **Acceder a los providers:**
```dart
// Para observar cambios
final valor = ref.watch(miProvider);

// Para acciones (no reconstruye el widget)
final notifier = ref.read(miProvider.notifier);
```

## 📝 Ejemplo Completo

```dart
class EjemploCompleto extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar múltiples estados
    final contador = ref.watch(contadorProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final devices = ref.watch(devicesProvider);
    
    // Obtener notifier para acciones
    final bleNotifier = ref.read(bleProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(title: Text('Estado BLE')),
      body: Column(
        children: [
          // Mostrar contador si está disponible
          if (contador != null)
            Text('Contador: $contador', style: TextStyle(fontSize: 24)),
          
          // Estado de conexión
          Text('Estado: ${isConnected ? "Conectado" : "Desconectado"}'),
          
          // Lista de dispositivos
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index].device;
                return ListTile(
                  title: Text(device.platformName),
                  onTap: () => bleNotifier.connectOrDisconnect(device),
                );
              },
            ),
          ),
          
          // Botones de control
          Row(
            children: [
              ElevatedButton(
                onPressed: () => bleNotifier.scanDevices(),
                child: Text('Escanear'),
              ),
              if (isConnected)
                ElevatedButton(
                  onPressed: () => bleNotifier.toggleDevice(),
                  child: Text('Toggle Device'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Con este sistema, puedes acceder a todos los datos del BLE desde cualquier pantalla de tu aplicación de manera reactiva y eficiente. 🎉
