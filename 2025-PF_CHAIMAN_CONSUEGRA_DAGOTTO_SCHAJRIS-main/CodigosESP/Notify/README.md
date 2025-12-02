# NeoPosture - Sensor BLE para ESP32

Este directorio contiene el firmware para el sensor BLE del proyecto NeoPosture, diseñado para ejecutarse en microcontroladores ESP32.

## 📁 Archivos del Proyecto

### `Notify.ino`
Código principal del firmware Arduino que implementa:
- **Servidor BLE**: Anuncia el dispositivo como "NeoPosture"
- **Comunicación bidireccional**: Envía contador y recibe comandos
- **Control de estado**: Encendido/apagado remotamente desde Flutter
- **Notificaciones automáticas**: Envío continuo de datos del sensor

### `ci.json`
Archivo de configuración para integración continua y compilación automática.

#### Configuración de Compilación
```json
"fqbn_append": "PartitionScheme=huge_app"
```
- **Propósito**: Configura el ESP32 para usar un esquema de partición que asigna más espacio para la aplicación
- **Necesidad**: El código BLE requiere librerías adicionales que aumentan el tamaño del firmware
- **Esquema huge_app**: 3MB para aplicación / 1MB para SPIFFS

#### Requisitos de Hardware
```json
"requires": ["CONFIG_SOC_BLE_SUPPORTED=y"]
```
- **Verificación**: Asegura que el microcontrolador tenga soporte BLE habilitado
- **Compatibilidad**: Solo chips ESP32 con módulo Bluetooth funcional
- **Compilación**: Sin esta capacidad, el código no compilará correctamente

## 🔧 Configuración Técnica

### UUIDs del Protocolo BLE
- **Servicio**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Característica**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

> ⚠️ **Importante**: Estos UUIDs deben coincidir exactamente con los definidos en la aplicación Flutter.

### Protocolo de Comunicación

#### Envío (ESP32 → Flutter)
- **Formato**: 4 bytes (uint32_t)
- **Codificación**: Little-endian
- **Contenido**: Contador incrementable
- **Frecuencia**: Configurable desde Flutter (por defecto 1000ms)
- **Comportamiento**: 
  - Se incrementa solo cuando el dispositivo está encendido
  - Se resetea a 0 cuando se apaga el dispositivo
  - Se resetea a 0 en cada nueva conexión

#### Recepción (Flutter → ESP32)
- **Formato**: 5 bytes total
  - Byte 0: Estado (0 = apagado, 1 = encendido)
  - Bytes 1-4: Intervalo en milisegundos (little-endian)

### Variables de Estado
- `deviceConnected`: Indica conexión BLE activa
- `isOn`: Estado del sensor (encendido/apagado)
- `value`: Contador que se envía a Flutter
- `timeCheck`: Intervalo entre notificaciones (ms)

## 🚀 Compilación y Carga

### Requisitos
- **Hardware**: ESP32 con soporte BLE
- **IDE**: Arduino IDE 1.8+ o PlatformIO
- **Librerías**: ESP32 BLE Arduino (incluida en el core ESP32)

### Pasos de Instalación
1. Instalar el core ESP32 en Arduino IDE
2. Seleccionar placa ESP32 Dev Module
3. Configurar esquema de partición: "Huge APP (3MB No OTA/1MB SPIFFS)"
4. Compilar y cargar el código

### Verificación
- Monitor serie a 115200 baudios
- Buscar mensaje: "=== Advertising iniciado - Esperando conexión de cliente ==="
- El dispositivo debe aparecer como "NeoPosture" en escaneos BLE

## 🔍 Depuración

### Mensajes del Monitor Serie
- Conexión/desconexión de clientes
- Comandos recibidos desde Flutter
- Estado del contador y frecuencia de envío
- Errores en el protocolo de comunicación

### Troubleshooting Común
- **No aparece en escaneo**: Verificar que el ESP32 tenga BLE habilitado
- **Conexión falla**: Comprobar UUIDs entre Arduino y Flutter
- **Datos no se reciben**: Verificar formato little-endian en ambos extremos
- **Memoria insuficiente**: Usar esquema de partición "huge_app"

## 📱 Integración con Flutter

Este firmware está diseñado para trabajar con la aplicación Flutter NeoPosture:
- **Escaneo**: La app busca dispositivos con nombre "NeoPosture"
- **Conexión**: Automática al seleccionar el dispositivo
- **Control**: Envío de comandos ON/OFF y configuración de frecuencia
- **Datos**: Recepción en tiempo real del contador del sensor

---

**Equipo NeoPosture** - 2025
