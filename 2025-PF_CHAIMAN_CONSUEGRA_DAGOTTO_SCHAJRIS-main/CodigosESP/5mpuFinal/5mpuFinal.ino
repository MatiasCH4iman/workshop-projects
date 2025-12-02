// Código avanzado con detección dinámica de MPU6050 en ambos buses I2C
// - Detecta qué sensores están realmente conectados
// - Cada sensor puede estar en Wire o Wire1 y en 0x68 o 0x69
// - El programa continúa aunque falten sensores
// - BLE transmite solo los sensores detectados

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLE2901.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include <math.h>

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define NUM_SENSORS 4

// Pines I2C (ajusta según tu ESP32)
// Wire: SDA 21, SCL 22 (por defecto, ya inicializado)
// Wire1: SDA 25, SCL 26
#define SDA_PIN_1 21
#define SCL_PIN_1 22
#define SDA_PIN_2 25
#define SCL_PIN_2 26

uint8_t possibleAddrs[2] = {0x68, 0x69};
TwoWire *buses[2] = {&Wire, &Wire1};

// Declaración de los objetos Adafruit_MPU6050
// ¡Importante! Deben ser punteros para que el objeto se inicialice correctamente en el heap
Adafruit_MPU6050 *mpu[NUM_SENSORS]; 

struct MPUInfo {
  bool detected;
  uint8_t addr;
  TwoWire *bus;
} sensorInfo[NUM_SENSORS];

float pitch[NUM_SENSORS], roll[NUM_SENSORS];
unsigned long prevTime[NUM_SENSORS];
float alpha = 0.98;

BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLE2901 *descriptor_2901 = nullptr;

bool deviceConnected = false;
bool oldDeviceConnected = false;
bool isOn = true;
uint32_t timeCheck = 500;

// --- Callbacks BLE ---
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    deviceConnected = true;
    Serial.println("Cliente BLE conectado");
  }
  void onDisconnect(BLEServer *pServer) override {
    deviceConnected = false;
    Serial.println("Cliente BLE desconectado");
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rx = pCharacteristic->getValue();
    if (rx.length() == 5) {
      // Usar rx.c_str() para acceder a los bytes
      const uint8_t* data = (const uint8_t*)rx.c_str();
      isOn = data[0] == 1; // Primer byte para ON/OFF
      // 4 bytes siguientes (Little Endian) para timeCheck
      timeCheck = data[1] | (data[2] << 8) | (data[3] << 16) | (data[4] << 24);
      Serial.printf("Configuración recibida: ON=%d, Delay=%d ms\n", isOn, timeCheck);
    }
  }
};

// --- Funciones MPU6050 ---

void detectarSensores() {
  Serial.println("=== Detectando sensores MPU6050 ===");
  int found = 0;

  // Intentar con Wire (Bus 1) y luego Wire1 (Bus 2)
  for (int i = 0; i < 2; i++) { 
    for (int j = 0; j < 2; j++) { // Intentar con Addr 0x68 y 0x69
      uint8_t addr = possibleAddrs[j];
      TwoWire *bus = buses[i];

      // CRÍTICO: Crear una nueva instancia MPU6050 en el heap
      Adafruit_MPU6050 *tempMpu = new Adafruit_MPU6050(); 
      
      if (tempMpu->begin(addr, bus)) {
        if (found < NUM_SENSORS) {
          
          // 1. Almacenar el puntero del objeto MPU
          mpu[found] = tempMpu; 
          
          // 2. Almacenar la información del sensor detectado
          sensorInfo[found].detected = true;
          sensorInfo[found].addr = addr;
          sensorInfo[found].bus = bus;

          // 3. Configurar el sensor a través del puntero
          mpu[found]->setAccelerometerRange(MPU6050_RANGE_2_G);
          mpu[found]->setGyroRange(MPU6050_RANGE_250_DEG);
          mpu[found]->setFilterBandwidth(MPU6050_BAND_21_HZ);
          
          prevTime[found] = millis();

          Serial.printf("✅ MPU %d detectado -> Addr 0x%02X en %s\n", 
                        found, 
                        addr, 
                        (bus == &Wire ? "Wire (21/22)" : "Wire1 (25/26)"));
          found++;
        } else {
          delete tempMpu; // Limpiar si ya no hay espacio
          Serial.println("⚠️ Se detectaron más de 4 sensores, ignorando.");
        }
      } else {
        delete tempMpu; // Limpiar si no se detectó
      }
    }
  }

  if (found == 0) Serial.println("⚠️ No se detectó ningún MPU6050.");
  else Serial.printf("=== %d sensores detectados ===\n", found);
}

void leerMPU(int i, float &pitchOut, float &rollOut) {
  if (!mpu[i]) return; //Verificar si sigue funcioanndo el sensor

  sensors_event_t a, g, temp;
  
  // CRÍTICO: Acceder al método del sensor a través del puntero ->
  mpu[i]->getEvent(&a, &g, &temp); 

  unsigned long now = millis();
  float dt = (now - prevTime[i]) / 1000.0;
  prevTime[i] = now;
  // Si dt=0 se establece como 0.01
  if (dt <= 0) dt = 0.01; 

  // Cálculo de Ángulos (Acelerómetro)
  float accPitch = atan2(a.acceleration.y, a.acceleration.z) * 180.0 / PI;
  float accRoll = atan2(-a.acceleration.x, sqrt(a.acceleration.y * a.acceleration.y + a.acceleration.z * a.acceleration.z)) * 180.0 / PI;

  // Lectura de Gyroscopio (velocidad angular)
  float gyroX = g.gyro.x * 180.0 / PI;
  float gyroY = g.gyro.y * 180.0 / PI;

  // Filtro Complementario
  pitch[i] = alpha * (pitch[i] + gyroX * dt) + (1.0 - alpha) * accPitch;
  roll[i] = alpha * (roll[i] + gyroY * dt) + (1.0 - alpha) * accRoll;

  pitchOut = pitch[i];
  rollOut = roll[i];
  
  // DEBUGGING: Imprimir los valores leídos para el sensor 'i'
  Serial.printf("S%d (0x%02X): Pitch=%.2f | Roll=%.2f\n", 
                i, 
                sensorInfo[i].addr, 
                pitchOut, 
                rollOut);
}

// --- Setup y Loop ---

void setup() {
  Serial.begin(115200);
  Serial.println("=== NeoPosture con detección automática v2.0 ===");

  // Inicializar Wire y Wire1 con sus respectivos pines
  Wire.begin(SDA_PIN_1, SCL_PIN_1); 
  Wire.setClock(400000);
  
  // Wire1.begin() debe usarse con sus pines definidos (25/26)
  Wire1.begin(SDA_PIN_2, SCL_PIN_2);
  Wire1.setClock(400000);

  for (int i = 0; i < NUM_SENSORS; i++) sensorInfo[i].detected = false;

  detectarSensores();

  // --- Configuración BLE ---
  BLEDevice::init("NeoPosture-Auto");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->addDescriptor(new BLE2902());
  descriptor_2901 = new BLE2901();
  descriptor_2901->setDescription("Postura con sensores auto-detectados");
  pCharacteristic->addDescriptor(descriptor_2901);
  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMaxPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.println("🚀 BLE Advertising iniciado");
}

void loop() {
  int active = 0;
  for (int i = 0; i < NUM_SENSORS; i++) if (sensorInfo[i].detected) active++;

  if (deviceConnected && isOn && active > 0) {
    // float values[active * 2]; // Opcional: usar vector para mayor seguridad
    static float values[NUM_SENSORS * 2]; // Usar static para evitar stack overflow potencial
    int idx = 0;

    for (int i = 0; i < NUM_SENSORS; i++) {
      if (!sensorInfo[i].detected) continue;

      float p, r;
      leerMPU(i, p, r); // Lee y actualiza pitch/roll para el sensor 'i'

      values[idx++] = p;
      values[idx++] = r;
    }

    // Transmitir solo la parte de la matriz que contiene datos de sensores activos
    pCharacteristic->setValue((uint8_t *)values, active * 2 * sizeof(float));
    pCharacteristic->notify();

    delay(timeCheck);
  }

  // Lógica de reconexión/re-advertencia (sin cambios)
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    BLEDevice::startAdvertising();
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}