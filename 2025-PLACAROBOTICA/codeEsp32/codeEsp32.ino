#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

// ====== Pines BTS7960 ======
#define R_PWM_UP   17  // Motor derecho - PWM arriba
#define R_PWM_DOWN 16  // Motor derecho - PWM abajo
#define L_PWM_UP    9  // Motor izquierdo - PWM arriba
#define L_PWM_DOWN  8  // Motor izquierdo - PWM abajo

// ====== Configuración ======
const int motorSpeed = 200;  // 0–255 (ajustá según potencia)

void setup() {
  Serial.begin(115200);
  SerialBT.begin("SumoBot");  // Nombre Bluetooth visible desde la app
  Serial.println("✅ Bluetooth SumoBot listo. Esperando conexión...");

  pinMode(R_PWM_UP, OUTPUT);
  pinMode(R_PWM_DOWN, OUTPUT);
  pinMode(L_PWM_UP, OUTPUT);
  pinMode(L_PWM_DOWN, OUTPUT);

  stopMotors();
}

void loop() {
  if (SerialBT.available()) {
    char c = SerialBT.read();
    Serial.print("Comando recibido: ");
    Serial.println(c);

    switch (c) {
      case 'F': forward(); break;
      case 'B': backward(); break;
      case 'L': turnLeft(); break;
      case 'R': turnRight(); break;
      case 'S': stopMotors(); break;
      default:  Serial.println("Comando desconocido"); break;
    }
  }
}

// ====== Funciones de movimiento ======

void forward() {
  analogWrite(R_PWM_UP, motorSpeed);
  analogWrite(R_PWM_DOWN, 0);
  analogWrite(L_PWM_UP, motorSpeed);
  analogWrite(L_PWM_DOWN, 0);
}

void backward() {
  analogWrite(R_PWM_UP, 0);
  analogWrite(R_PWM_DOWN, motorSpeed);
  analogWrite(L_PWM_UP, 0);
  analogWrite(L_PWM_DOWN, motorSpeed);
}

void turnLeft() {
  analogWrite(R_PWM_UP, motorSpeed);
  analogWrite(R_PWM_DOWN, 0);
  analogWrite(L_PWM_UP, 0);
  analogWrite(L_PWM_DOWN, motorSpeed);
}

void turnRight() {
  analogWrite(R_PWM_UP, 0);
  analogWrite(R_PWM_DOWN, motorSpeed);
  analogWrite(L_PWM_UP, motorSpeed);
  analogWrite(L_PWM_DOWN, 0);
}

void stopMotors() {
  ana
