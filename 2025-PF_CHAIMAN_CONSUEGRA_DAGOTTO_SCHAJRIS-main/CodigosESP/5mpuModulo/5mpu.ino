/*
 * 5 sensores MPU6050 con multiplexador TCA9548A
 * Manda Pitch y Roll filtrados por BLE
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLE2901.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

// ==================== UUIDs BLE ====================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==================== MULTIPLEXADOR I2C ====================
#define TCA_ADDR 0x70
#define NUM_SENSORS 5

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
float pitch[NUM_SENSORS] = {0}, roll[NUM_SENSORS] = {0};
float alpha = 0.98;
unsigned long prevTime[NUM_SENSORS] = {0};
bool sensorDetected[NUM_SENSORS] = {false};

// ==================== FUNCIÓN MULTIPLEXADOR ====================
void tcaSelect(uint8_t channel) {
  if (channel > 7) return;
  Wire.beginTransmission(TCA_ADDR);
  Wire.write(1 << channel);
  Wire.endTransmission();
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
  Serial.println("=== Iniciando NeoPosture con 5 sensores ===");

  // Inicialización BLE
  BLEDevice::init("NeoPosture5");
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
  descriptor_2901->setDescription("5 sensores MPU6050");
  pCharacteristic->addDescriptor(descriptor_2901);
  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("=== BLE listo - Esperando conexión ===");

  // Inicialización I2C y sensores
  Wire.begin(21, 22); // SDA, SCL
  delay(100);

  for (int i = 0; i < NUM_SENSORS; i++) {
    tcaSelect(i);
    delay(50);
    
    if (mpu[i].begin()) {
      Serial.printf("✅ MPU6050 %d detectado en canal %d\n", i, i);
      mpu[i].setAccelerometerRange(MPU6050_RANGE_2_G);
      mpu[i].setGyroRange(MPU6050_RANGE_250_DEG);
      mpu[i].setFilterBandwidth(MPU6050_BAND_21_HZ);
      sensorDetected[i] = true;
    } else {
      Serial.printf("⚠️ No se detectó MPU6050 %d en canal %d\n", i, i);
      sensorDetected[i] = false;
    }
    delay(100);
  }
  Serial.println("Sensores inicializados.");
}

// ==================== FUNCIÓN LECTURA ====================
void leerMPU(uint8_t sensorIndex, float &pitchOut, float &rollOut) {
  tcaSelect(sensorIndex);
  delay(10);
  
  sensors_event_t a, g, temp;
  mpu[sensorIndex].getEvent(&a, &g, &temp);

  unsigned long now = millis();
  float dt = (now - prevTime[sensorIndex]) / 1000.0;
  prevTime[sensorIndex] = now;
  if (dt <= 0) dt = 0.01;

  // Ángulo acelerómetro
  float accPitch = atan2(a.acceleration.y, a.acceleration.z) * 180 / PI;
  float accRoll  = atan2(-a.acceleration.x, sqrt(a.acceleration.y*a.acceleration.y + a.acceleration.z*a.acceleration.z)) * 180 / PI;

  // Ángulo giroscopio
  float gyroX = g.gyro.x * 180 / PI;
  float gyroY = g.gyro.y * 180 / PI;

  // Filtro complementario
  pitch[sensorIndex] = alpha * (pitch[sensorIndex] + gyroX * dt) + (1 - alpha) * accPitch;
  roll[sensorIndex]  = alpha * (roll[sensorIndex]  + gyroY * dt) + (1 - alpha) * accRoll;

  pitchOut = pitch[sensorIndex];
  rollOut  = roll[sensorIndex];
}

// ==================== LOOP ====================
void loop() {
  if (deviceConnected && isOn) {
    float values[10] = {0}; // 5 sensores * 2 valores (pitch, roll)
    int dataIndex = 0;
    bool anyDetected = false;

    for (int i = 0; i < NUM_SENSORS; i++) {
      if (sensorDetected[i]) {
        float p, r;
        leerMPU(i, p, r);
        values[dataIndex++] = p;
        values[dataIndex++] = r;
        Serial.printf("S%d - Pitch: %.2f, Roll: %.2f | ", i, p, r);
        anyDetected = true;
      }
    }
    Serial.println();

    if (anyDetected) {
      pCharacteristic->setValue((uint8_t*)values, sizeof(values));
      pCharacteristic->notify();
    }

    delay(timeCheck);
  } else {
    delay(100);
  }

  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}