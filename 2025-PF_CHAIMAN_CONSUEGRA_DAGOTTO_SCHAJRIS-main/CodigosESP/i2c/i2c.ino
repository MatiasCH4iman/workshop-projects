#include <Wire.h>

void setup() {
  Serial.begin(115200);
  delay(200);

  delay(10);

  Wire.begin(22, 21);
  Wire.setClock(100000);

  delay(200);
  scanI2C();
}

void loop() {
  delay(2000);
  scanI2C();
}

void scanI2C() {
  Serial.println("Escaneando I2C (21,22) ...");
  bool found = false;
  for (uint8_t addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.printf("  Encontrado: 0x%02X\n", addr);
      found = true;
    }
  }
  if (!found) Serial.println("  Ningún dispositivo detectado");
  Serial.println("----");
}
