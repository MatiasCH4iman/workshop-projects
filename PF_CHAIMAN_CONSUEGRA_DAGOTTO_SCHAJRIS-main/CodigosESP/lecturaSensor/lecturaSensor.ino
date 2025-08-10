#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

Adafruit_MPU6050 mpu;

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
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  Serial.print("Acelerómetro | X: ");
  Serial.print(a.acceleration.x, 2);
  Serial.print(" Y: ");
  Serial.print(a.acceleration.y, 2);
  Serial.print(" Z: ");
  Serial.println(a.acceleration.z, 2);

  Serial.print("Giroscopio   | X: ");
  Serial.print(g.gyro.x, 2);
  Serial.print(" Y: ");
  Serial.print(g.gyro.y, 2);
  Serial.print(" Z: ");
  Serial.println(g.gyro.z, 2);

  Serial.print("Temperatura  | ");
  Serial.print(temp.temperature, 2);
  Serial.println(" °C");

  Serial.println("-----------------------------");
  delay(500);  // Tiempo entre lecturas
}
