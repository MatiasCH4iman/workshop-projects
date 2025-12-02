/*
 * 1 sensor MPU6050
 * Manda Pitch y Roll filtrados por BLE
 * Nunca espera calibración
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLE2901.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#define T1 32
#define T2 33
#define T3 25
#define T4 26
#define T5 27



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
uint32_t timeCheck = 200; // intervalo por defecto en ms

// ==================== SENSOR MPU6050 ====================
Adafruit_MPU6050 mpu;
float pitch = 0, roll = 0;
float alpha = 0.98;           // filtro complementario
unsigned long prevTime = 0;
bool sensorDetected = false;  // NUEVO: bandera para detectar el sensor

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
    // Aquí solo recibimos comando binario para encender/apagar y tiempo
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
  Serial.println("=== Iniciando NeoPosture simplificado ===");
  pinMode(T2,OUTPUT);
  pinMode(T3,OUTPUT);
  pinMode(T4,OUTPUT);
  pinMode(T5,OUTPUT);
  digitalWrite(T2, HIGH);
  digitalWrite(T3, LOW);
  digitalWrite(T4, LOW);
  digitalWrite(T5, LOW);

  // Inicialización BLE
  BLEDevice::init("NeoPosture");
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
  descriptor_2901->setDescription("Pitch y Roll del MPU6050");
  pCharacteristic->addDescriptor(descriptor_2901);
  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("=== BLE listo - Esperando conexión ===");

  // Inicialización MPU6050
  Wire.begin(21, 22); // SDA, SCL
  if (!mpu.begin()) {
    Serial.println("⚠️ No se detectó el MPU6050. BLE activo sin sensor.");
    sensorDetected = false;  // NUEVO: marcar que no hay sensor
  } else {
    Serial.println("✅ MPU6050 detectado.");
    mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
    mpu.setGyroRange(MPU6050_RANGE_250_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    sensorDetected = true;   // NUEVO: marcar que hay sensor
    delay(500);
  }
}

// ==================== FUNCIONES ====================
void leerMPU(float &pitchOut, float &rollOut) {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  unsigned long now = millis();
  float dt = (now - prevTime) / 1000.0;
  prevTime = now;
  if (dt <= 0) dt = 0.01;

  // Ángulo acelerómetro
  float accPitch = atan2(a.acceleration.y, a.acceleration.z) * 180 / PI;
  float accRoll  = atan2(-a.acceleration.x, sqrt(a.acceleration.y*a.acceleration.y + a.acceleration.z*a.acceleration.z)) * 180 / PI;

  // Ángulo giroscopio
  float gyroX = g.gyro.x * 180 / PI;
  float gyroY = g.gyro.y * 180 / PI;

  // Filtro complementario
  pitch = alpha * (pitch + gyroX * dt) + (1 - alpha) * accPitch;
  roll  = alpha * (roll  + gyroY * dt) + (1 - alpha) * accRoll;

  pitchOut = pitch;
  rollOut  = roll;
}

// ==================== LOOP ====================
void loop() {
  if (deviceConnected && isOn && sensorDetected) { 
    float p, r;
    leerMPU(p, r);

    Serial.print("Pitch: "); Serial.print(p, 2);
    Serial.print("\tRoll: "); Serial.println(r, 2);

    float values[2] = {p, r};
    pCharacteristic->setValue((uint8_t*)values, sizeof(values));
    pCharacteristic->notify();

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
