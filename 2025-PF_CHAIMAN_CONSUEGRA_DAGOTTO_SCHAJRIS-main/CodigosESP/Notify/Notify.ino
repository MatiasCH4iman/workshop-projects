/*
 * NeoPosture - Sensor BLE para Monitoreo de Postura
 * 
 * Este código implementa un servidor BLE (Bluetooth Low Energy) para ESP32
 * que funciona como sensor de postura para la aplicación móvil NeoPosture.
 * 
 * Funcionalidades principales:
 * - Servidor BLE con identificación "NeoPosture"
 * - Envío de contador incrementable via notificaciones BLE
 * - Recepción de comandos desde la app móvil (ON/OFF y frecuencia)
 * - Control de estado del sensor (encendido/apagado)
 * - Configuración dinámica del intervalo de notificaciones
 * 
 * Protocolo de comunicación:
 * - Envío: Contador de 32 bits (4 bytes) en formato little-endian
 * - Recepción: 5 bytes (1 byte estado + 4 bytes tiempo en ms)
 * 
 * Hardware objetivo: ESP32 con capacidades BLE
 * Autor: Equipo NeoPosture
 * Fecha: 2025
 */

// ==================== LIBRERÍAS BLE ====================
#include <BLEDevice.h>    // Biblioteca principal para BLE en ESP32
#include <BLEServer.h>    // Servidor BLE para anunciar servicios
#include <BLEUtils.h>     // Utilidades adicionales para BLE
#include <BLE2902.h>      // Descriptor para notificaciones/indicaciones
#include <BLE2901.h>      // Descriptor p ara descripción de características

// ==================== IDENTIFICADORES UUID ====================
/// UUID del servicio principal del dispositivo NeoPosture
/// Este UUID debe coincidir exactamente con el definido en Flutter
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"

/// UUID de la característica del contador
/// Característica bidireccional que envía el contador y recibe comandos
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==================== OBJETOS GLOBALES BLE ====================
/// Servidor BLE principal que gestiona las conexiones
BLEServer *pServer = NULL;

/// Característica principal para comunicación bidireccional
BLECharacteristic *pCharacteristic = NULL;

/// Descriptor para proporcionar descripción legible de la característica
BLE2901 *descriptor_2901 = NULL;

// ==================== VARIABLES DE ESTADO ====================
/// Indica si hay un cliente BLE conectado
bool deviceConnected = false;

/// Estado anterior de conexión para detectar cambios
bool oldDeviceConnected = false;

/// Estado del sensor recibido desde Flutter (true = encendido, false = apagado)
bool isOn = true; 

/// Intervalo de tiempo entre notificaciones en milisegundos
/// Valor por defecto: 1000ms (1 segundo)
/// Este valor se actualiza dinámicamente desde la aplicación Flutter
uint32_t timeCheck = 1000;

// ==================== DEFINICIÓN DE CLASE Y VARIABLES DE SENSORES ====================
class MPU6050Sensor {
  public:
    int numeroSensor;
    float accX, accY, accZ;
    float gyroX, gyroY, gyroZ;
    MPU6050Sensor() {}
    MPU6050Sensor(float ax, float ay, float az, float gx, float gy, float gz) {
      accX = ax;
      accY = ay;
      accZ = az;
      gyroX = gx;
      gyroY = gy;
      gyroZ = gz;
    }
};

const int cantidadSensores = 4;
const int pinesTransistores[cantidadSensores] = {};
MPU6050Sensor listaSensores[cantidadSensores];

// ==================== CALLBACKS DEL SERVIDOR BLE ====================
/**
 * Clase que maneja los eventos de conexión y desconexión del servidor BLE
 * 
 * Esta clase hereda de BLEServerCallbacks y se encarga de:
 * - Detectar cuando un cliente se conecta al servidor
 * - Detectar cuando un cliente se desconecta del servidor
 * - Actualizar las variables de estado correspondientes
 */
class MyServerCallbacks : public BLEServerCallbacks {
  /**
   * Callback ejecutado cuando un cliente BLE se conecta
   * @param pServer Puntero al servidor BLE que recibió la conexión
   */
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Cliente BLE conectado");
  }
  
  /**
   * Callback desconexión BLE
   * @param pServer Puntero al servidor BLE que perdió la conexión
   */
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Cliente BLE desconectado"); 
  }
};

// ==================== CALLBACKS DE LA CARACTERÍSTICA ====================
/**
 * Clase que maneja la recepción de datos desde la aplicación Flutter
 * 
 * Esta clase procesa los comandos enviados desde la app móvil:
 * - Formato de datos recibidos: [estado][tiempo_byte1][tiempo_byte2][tiempo_byte3][tiempo_byte4]
 * - Estado: 1 byte (0 = apagado, 1 = encendido)
 * - Tiempo: 4 bytes en formato little-endian (intervalo en milisegundos)
 */
class MyCallbacks : public BLECharacteristicCallbacks {
  /**
   * Callback ejecutado cuando se reciben datos desde Flutter
   * @param pCharacteristic Característica que recibió los datos
   */
  void onWrite(BLECharacteristic *pCharacteristic) {
    // Obtener los datos recibidos como string
    String rxValue = pCharacteristic->getValue();
    
    // Verificar que se recibieron al menos 5 bytes (1 estado + 4 tiempo)
    if (rxValue.length() >= 5) {
      // ==================== PROCESAMIENTO DEL ESTADO ====================
      /// Primer byte indica si el sensor debe estar encendido (1) o apagado (0)
      isOn = rxValue[0] == 1;
      
      // ==================== PROCESAMIENTO DEL TIEMPO ====================
      /// Bytes 1-4 contienen el intervalo de tiempo en formato little-endian
      /// Little-endian: el byte menos significativo va primero
      timeCheck = (uint8_t)rxValue[1]                     // Bits 0-7
                  ((uint8_t)rxValue[2] << 8) |             // Bits 8-15
                  ((uint8_t)rxValue[3] << 16) |            // Bits 16-23
                  ((uint8_t)rxValue[4] << 24);             // Bits 24-31
      
      // ==================== LOGGING DE DEPURACIÓN ====================
      Serial.print("Comando recibido - Estado: ");
      Serial.print(isOn ? "ENCENDIDO" : "APAGADO");
      Serial.print(", Intervalo: ");
      Serial.print(timeCheck);
      Serial.println(" ms");
    } else {
      // Mensaje de error si no se recibieron suficientes datos
      Serial.println("Error: Datos recibidos insuficientes");
    }
  }
};

// ==================== CONFIGURACIÓN INICIAL (SETUP) ====================
/**
 * Función de configuración inicial del ESP32
 * 
 * Esta función se ejecuta una sola vez al inicio y configura:
 * 1. Comunicación serie para depuración
 * 2. Inicialización del dispositivo BLE
 * 3. Creación del servidor BLE
 * 4. Configuración del servicio y característica
 * 5. Configuración de descriptores y callbacks
 * 6. Inicio del advertising (anuncio) BLE
 */
void setup() {
  // ==================== INICIALIZACIÓN SERIE ====================
  /// Configurar comunicación serie a 115200 baudios para depuración
  Serial.begin(115200);
  Serial.println("=== Iniciando servidor BLE NeoPosture ===");
  
  // ==================== INICIALIZACIÓN BLE ====================
  /// Inicializar el dispositivo BLE con el nombre "NeoPosture"
  /// Este nombre será visible para la aplicación Flutter durante el escaneo
  BLEDevice::init("NeoPosture");
  Serial.println("Dispositivo BLE inicializado como 'NeoPosture'");
  
  // ==================== CREACIÓN DEL SERVIDOR ====================
  /// Crear el servidor BLE que manejará las conexiones
  pServer = BLEDevice::createServer();
  
  /// Asignar los callbacks para eventos de conexión/desconexión
  pServer->setCallbacks(new MyServerCallbacks());
  
  // ==================== CREACIÓN DEL SERVICIO ====================
  /// Crear el servicio principal usando el UUID definido
  BLEService *pService = pServer->createService(SERVICE_UUID);
  Serial.println("Servicio BLE creado con UUID: " SERVICE_UUID);

  // ==================== CONFIGURACIÓN DE LA CARACTERÍSTICA ====================
  /// Crear la característica principal con múltiples propiedades:
  /// - READ: Permite leer el valor actual
  /// - WRITE: Permite escribir comandos desde Flutter
  /// - NOTIFY: Permite enviar notificaciones automáticas a Flutter
  /// - INDICATE: Permite indicaciones con confirmación
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |      // Lectura del contador
    BLECharacteristic::PROPERTY_WRITE |     // Escritura de comandos
    BLECharacteristic::PROPERTY_NOTIFY |    // Notificaciones automáticas
    BLECharacteristic::PROPERTY_INDICATE    // Indicaciones con ACK
  );
  Serial.println("Característica creada con UUID: " CHARACTERISTIC_UUID);

  // ==================== CONFIGURACIÓN DE DESCRIPTORES ====================
  /// Agregar descriptor 2902 para habilitar notificaciones/indicaciones
  /// Este descriptor es estándar y requerido para notificaciones BLE
  pCharacteristic->addDescriptor(new BLE2902());
  
  /// Crear y configurar descriptor 2901 para descripción legible
  descriptor_2901 = new BLE2901();
  descriptor_2901->setDescription("NeoPosture contador y control de estado");
  descriptor_2901->setAccessPermissions(ESP_GATT_PERM_READ);  // Solo lectura
  pCharacteristic->addDescriptor(descriptor_2901);

  // ==================== ASIGNACIÓN DE CALLBACKS ====================
  /// Asignar los callbacks para manejar escrituras desde Flutter
  pCharacteristic->setCallbacks(new MyCallbacks());

  // ==================== INICIO DEL SERVICIO ====================
  /// Iniciar el servicio BLE para que esté disponible
  pService->start();
  Serial.println("Servicio BLE iniciado");
  
  // ==================== CONFIGURACIÓN DEL ADVERTISING ====================
  /// Configurar el advertising (anuncio) para que el dispositivo sea detectable
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  
  /// Agregar el UUID del servicio al anuncio para filtrado
  pAdvertising->addServiceUUID(SERVICE_UUID);
  
  /// Configurar parámetros del advertising
  pAdvertising->setScanResponse(false);    // No usar scan response
  pAdvertising->setMinPreferred(0x0);      // Usar valores por defecto
  
  /// Iniciar el advertising para que Flutter pueda encontrar el dispositivo
  BLEDevice::startAdvertising();
  
  Serial.println("=== Advertising iniciado - Esperando conexión de cliente ===");
}

// ==================== FUNCIÓN DE SEMÁFORO Y LECTURA DE SENSORES ====================
void leerSensores() {
  for (int i = 0; i < cantidadSensores; i++) {
    digitalWrite(pinesTransistores[i], HIGH); // Activar transistor
    // Aquí deberías seleccionar el sensor i en el bus I2C si es necesario
    // Lee los valores del sensor i
    float ax = mpu.getAccelerationX();
    float ay = mpu.getAccelerationY();
    float az = mpu.getAccelerationZ();
    float gx = mpu.getRotationX();
    float gy = mpu.getRotationY();
    float gz = mpu.getRotationZ();
    listaSensores[i] = MPU6050Sensor(ax, ay, az, gx, gy, gz);
    digitalWrite(pinesTransistores[i], LOW); // Apagar transistor
    delay(10); // Pequeña espera para estabilidad
  }
}

// ==================== SERIALIZACIÓN DE DATOS DE SENSORES ====================
void serializarSensores(uint8_t* buffer) {
  for (int i = 0; i < cantidadSensores; i++) {
    memcpy(buffer + i * sizeof(MPU6050Sensor), &listaSensores[i], sizeof(MPU6050Sensor));
  }
}

// ==================== BUCLE PRINCIPAL (LOOP) ====================
/**
 * Función de bucle principal que se ejecuta continuamente
 * 
 * Esta función maneja:
 * 1. Envío de notificaciones del contador cuando el sensor está encendido
 * 2. Incremento automático del contador
 * 3. Control del intervalo de notificaciones
 * 4. Gestión de reconexiones automáticas
 * 5. Detección de cambios en el estado de conexión
 */
void loop() {
  // ==================== ENVÍO DE NOTIFICACIONES ====================
  /// Solo enviar notificaciones si hay cliente conectado Y el sensor está encendido
  if (deviceConnected && isOn) {
    leerSensores(); // Actualiza listaSensores
    uint8_t buffer[cantidadSensores * sizeof(MPU6050Sensor)];
    serializarSensores(buffer);
    pCharacteristic->setValue(buffer, sizeof(buffer));
    pCharacteristic->notify();
    delay(timeCheck);
  } else {
    // ==================== MODO INACTIVO ====================
    /// Si no hay conexión o el sensor está apagado, esperar poco tiempo
    /// Esto evita consumo innecesario de CPU mientras se mantiene la responsividad
    delay(100);
  }
  
  // ==================== GESTIÓN DE RECONEXIÓN ====================
  /// Detectar cuando un cliente se desconecta y reiniciar el advertising
  if (!deviceConnected && oldDeviceConnected) {
    Serial.println("Cliente desconectado - Reiniciando advertising");
    
    /// Pequeña pausa para estabilizar la desconexión
    delay(500);
    
    /// Reiniciar el advertising para permitir nuevas conexiones
    pServer->startAdvertising();
    Serial.println("Advertising reiniciado - Listo para nueva conexión");
    
    /// Actualizar el estado anterior para evitar bucles
    oldDeviceConnected = deviceConnected;
  }
  
  // ==================== DETECCIÓN DE NUEVA CONEXIÓN ====================
  /// Detectar cuando se establece una nueva conexión
  if (deviceConnected && !oldDeviceConnected) {
    Serial.println("Nueva conexión establecida");
    
    /// Actualizar el estado anterior
    oldDeviceConnected = deviceConnected;
  }
}
