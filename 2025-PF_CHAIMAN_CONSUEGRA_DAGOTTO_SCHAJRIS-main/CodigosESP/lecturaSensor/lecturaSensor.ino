#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

Adafruit_MPU6050 mpu;

// Variables para cálculo de ángulos
float pitch = 0.0;
float roll = 0.0;
float dt = 0.01;          // intervalo inicial en segundos
float alpha = 0.98;       // filtro complementario
unsigned long timer;

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);  // SDA, SCL para ESP32

  Serial.println("Inicializando MPU6050...");

  if (!mpu.begin()) {
    Serial.println("❌ No se detectó el MPU6050. Verificá conexiones.");
    while (1);  // Se detiene si no encuentra el sensor
  }

  Serial.println("✅ MPU6050 detectado.");
  delay(1000);  // Espera antes de empezar lecturas
  timer = millis();
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Calcular tiempo transcurrido
  unsigned long now = millis();
  dt = (now - timer) / 1000.0; // dt en segundos
  timer = now;

  // --- Ángulos por acelerómetro ---
  float pitch_acc = atan2(a.acceleration.y, a.acceleration.z) * 180.0 / PI;
  float roll_acc  = atan2(-a.acceleration.x, sqrt(a.acceleration.y*a.acceleration.y + a.acceleration.z*a.acceleration.z)) * 180.0 / PI;

  // --- Integración giroscopio ---
  pitch += g.gyro.x * dt * 180.0 / PI; // giroscopio en rad/s → grados
  roll  += g.gyro.y * dt * 180.0 / PI;

  // --- Filtro complementario ---
  pitch = alpha * pitch + (1 - alpha) * pitch_acc;
  roll  = alpha * roll  + (1 - alpha) * roll_acc;

  // --- Imprimir resultados ---
  Serial.print("Pitch: "); Serial.print(pitch, 2);
  Serial.print("  Roll: "); Serial.println(roll, 2);


  Serial.println("-----------------------------");

  delay(10); // loop rápido para mejor integración
}
