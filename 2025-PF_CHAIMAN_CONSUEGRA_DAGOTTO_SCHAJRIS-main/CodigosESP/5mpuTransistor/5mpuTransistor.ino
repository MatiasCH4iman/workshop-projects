/*
 * 5 sensores MPU6050 con multiplexador TCA9548A
 * Enciende/apaga cada sensor con transistores T2-T5
 * Manda Pitch y Roll + número de sensor por BLE
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLE2901.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

// ==================== PINES TRANSISTORES ====================
#define T1 32
#define T2 33
#define T3 25
#define T4 26
#define T5 27

// ==================== MULTIPLEXADOR I2C ====================
#define TCA_ADDR 0x70
#define NUM_SENSORS 5

// ==================== UUIDs BLE ====================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==================== OBJETOS BLE ====================
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLE2901 *descriptor_2901 = nullptr;

// ==================== VARIABLES ====================
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool isOn = true;
uint32_t timeCheck = 200;

// ==================== SENSORES MPU6050 ====================
Adafruit_MPU6050 mpu[NUM_SENSORS];
float pitch[NUM_SENSORS] = {0};
float roll[NUM_SENSORS] = {0};
float alpha = 0.98;
unsigned long prevTime[NUM_SENSORS] = {0};
bool sensorDetected[NUM_SENSORS] = {false};

// Array con los pines de transistor para cada sensor
uint8_t transistorPins[NUM_SENSORS] = {T2, T3, T4, T5, T1};

// ==================== FUNCIÓN MULTIPLEXADOR ====================
void tcaSelect(uint8_t channel) {
  if (channel > 7) return;
  Wire.beginTransmission(TCA_ADDR);
  Wire.write(1 << channel);
  Wire.endTransmission();
}

// ==================== FUNCIÓN CONTROL TRANSISTORES ====================
void activarSensor(uint8_t sensorIndex) {
  // Apagar todos los sensores primero
  for (int i = 0; i < NUM_SENSORS; i++) {
    digitalWrite(transistorPins[i], HIGH); // HIGH = apagado
  }
  delay(100);  // ✅ AUMENTAR: Esperar a que se apaguen completamente
  
  // Encender solo el sensor solicitado
  digitalWrite(transistorPins[sensorIndex], LOW); // LOW = encendido
  delay(150);  // ✅ AUMENTAR: Esperar a que se encienda completamente y se estabilice
}

void apagarTodosSensores() {
  for (int i = 0; i < NUM_SENSORS; i++) {
    digitalWrite(transistorPins[i], HIGH); // HIGH = apagado
  }
  delay(50);  // ✅ AGREGAR: Asegurar que se apagan
}

// ==================== CALLBACKS BLE ====================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    deviceConnected = true;
    Serial.println("✅ Cliente BLE conectado");
  }
  void onDisconnect(BLEServer *pServer) override {
    deviceConnected = false;
    Serial.println("❌ Cliente BLE desconectado");
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    String rx = pCharacteristic->getValue();
    if (rx.length() >= 5) {
      isOn = rx[0] == 1;
      timeCheck = (uint8_t)rx[1] |
                  ((uint8_t)rx[2] << 8) |
                  ((uint8_t)rx[3] << 16) |
                  ((uint8_t)rx[4] << 24);
      Serial.print("Comando recibido - Estado: ");
      Serial.print(isOn ? "ENCENDIDO" : "APAGADO");
      Serial.print(", Intervalo: ");
      Serial.print(timeCheck);
      Serial.println(" ms");
    }
  }
};

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("=== Iniciando NeoPosture con 5 sensores y transistores ===");
  
  // Configurar pines de transistores como salida
  pinMode(T1, OUTPUT);
  pinMode(T2, OUTPUT);
  pinMode(T3, OUTPUT);
  pinMode(T4, OUTPUT);
  pinMode(T5, OUTPUT);
  
  // Apagar todos los sensores al inicio
  apagarTodosSensores();

  // Inicialización BLE
  BLEDevice::init("NeoPosture5");  // ← Cambiar aquí si es necesario
  BLEDevice::setMTU(517); // Aumentar MTU para más datos
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->addDescriptor(new BLE2902());
  descriptor_2901 = new BLE2901();
  descriptor_2901->setDescription("5 sensores MPU6050 con transistores");
  pCharacteristic->addDescriptor(descriptor_2901);
  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  
  // Mejorar advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("=== BLE listo - Esperando conexión ===");

  // Inicialización I2C
  Wire.begin(21, 22); // SDA, SCL
  delay(100);

  // Detectar sensores
  for (int i = 0; i < NUM_SENSORS; i++) {
    activarSensor(i);
    tcaSelect(i);
    delay(100);
    
    if (mpu[i].begin()) {
      Serial.printf("✅ MPU6050 %d detectado (Pin T%d)\n", i, i+2);
      mpu[i].setAccelerometerRange(MPU6050_RANGE_2_G);
      mpu[i].setGyroRange(MPU6050_RANGE_250_DEG);
      mpu[i].setFilterBandwidth(MPU6050_BAND_21_HZ);
      sensorDetected[i] = true;
    } else {
      Serial.printf("⚠️ No se detectó MPU6050 %d\n", i);
      sensorDetected[i] = false;
    }
    delay(100);
  }
  
  apagarTodosSensores();
  Serial.println("Inicialización completada.");
}

// ==================== FUNCIÓN LECTURA ====================
void leerMPU(uint8_t sensorIndex, float &pitchOut, float &rollOut) {
  activarSensor(sensorIndex);
  tcaSelect(sensorIndex);
  delay(200);  // ✅ AUMENTAR de 10ms a 200ms - Tiempo de estabilización completo
  
  sensors_event_t a, g, temp;
  mpu[sensorIndex].getEvent(&a, &g, &temp);

  unsigned long now = millis();
  float dt = (now - prevTime[sensorIndex]) / 1000.0;
  prevTime[sensorIndex] = now;
  if (dt <= 0) dt = 0.01;

  // Ángulo acelerómetro
  float accPitch = atan2(a.acceleration.y, a.acceleration.z) * 180 / PI;
  float accRoll = atan2(-a.acceleration.x, sqrt(a.acceleration.y*a.acceleration.y + a.acceleration.z*a.acceleration.z)) * 180 / PI;

  // Ángulo giroscopio
  float gyroX = g.gyro.x * 180 / PI;
  float gyroY = g.gyro.y * 180 / PI;

  // Filtro complementario
  pitch[sensorIndex] = alpha * (pitch[sensorIndex] + gyroX * dt) + (1 - alpha) * accPitch;
  roll[sensorIndex] = alpha * (roll[sensorIndex] + gyroY * dt) + (1 - alpha) * accRoll;

  pitchOut = pitch[sensorIndex];
  rollOut = roll[sensorIndex];
}

// ==================== LOOP ====================
void loop() {
  if (deviceConnected && isOn) {
    float values[15] = {0};
    int dataIndex = 0;
    int activeSensors = 0;

    // Contar sensores activos
    for (int i = 0; i < NUM_SENSORS; i++) {
      if (sensorDetected[i]) activeSensors++;
    }

    // Solo enviar si hay al menos 1 sensor
    if (activeSensors > 0) {
      for (int i = 0; i < NUM_SENSORS; i++) {
        if (sensorDetected[i]) {
          float p, r;
          leerMPU(i, p, r);
          
          values[dataIndex++] = (float)i;
          values[dataIndex++] = p;
          values[dataIndex++] = r;
          
          Serial.printf("Sensor %d - Pitch: %.2f, Roll: %.2f | ", i, p, r);
        }
        delay(100);  // ✅ AGREGAR: Delay entre lecturas de sensores
      }
      Serial.println();

      int bytesToSend = activeSensors * 12;
      pCharacteristic->setValue((uint8_t*)values, bytesToSend);
      pCharacteristic->notify();
    }

    apagarTodosSensores();
    delay(timeCheck);  // ✅ AUMENTAR: timeCheck debería ser >= 1000ms mínimo
  } else {
    apagarTodosSensores();
    delay(5000);  // ✅ AUMENTAR de 100 a 500
  }

  // Reiniciar advertising si se desconectó
  if (!deviceConnected && oldDeviceConnected) {
    delay(5000);
    BLEDevice::startAdvertising();
    Serial.println("📡 Advertising reiniciado");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}