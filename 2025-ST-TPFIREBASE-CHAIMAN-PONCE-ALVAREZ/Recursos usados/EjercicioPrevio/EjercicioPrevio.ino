//Grupo5_Kalik_Padovani_Rubinstein_Chaiman

//Librerias
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "DHT.h"
#include <ESP32Time.h>
#include <WiFi.h>
#include "time.h"

//Ajustes de la pantalla
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

//Ajustes del Tiempo
ESP32Time rtc;
int GMT;

//Ajustes del DHT
#define DHTPIN 23
#define DHTTYPE DHT11
unsigned long TiempoUltimoCambio = 0;
const long Intervalo = 2500;
DHT dht(DHTPIN, DHTTYPE);
unsigned long TiempoAhora;
float t;

//Ajuestes de WIFI
const char* ssid = "ORT-IoT";
const char* password = "NuevaIOT$25";
int currentGMT = -3;

//Definicion de estados de la maquina
#define PANTALLA1 1
#define ESTADO_CONFIRMACION1 2
#define ESTADO_CONFIRMACION2 3
#define PANTALLA2 4
#define BAJAR_GMT 5
#define SUBIR_GMT 6

//Definicion de PINES y estado del boton
void MAQUINA_DE_ESTADOS();
#define PULSADO 0
#define NO_PULSADO 1
#define BOTON1 35
#define BOTON2 34

//Variables generales
int lectura1;
int lectura2;
int estado = 1;
int contador1;

void setup() {
  Serial.begin(115200);

  //inicio del DHT
  dht.begin();

  //Defunicion de PINES
  pinMode(BOTON1, INPUT);
  pinMode(BOTON2, INPUT);

  //Inicio de la pantalla
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
  }

  //Conectar con el WIFI
  connectToWiFi();
  syncTimeWithGMT(currentGMT);

  //Ajuestes de la pantalla
  delay(2000);
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 10);
  display.display();
}

void loop() {
  //Lectura de botones
  lectura1 = digitalRead(BOTON1);
  lectura2 = digitalRead(BOTON2);

  //Maquina de estados
  MAQUINA_DE_ESTADOS();
}

void MAQUINA_DE_ESTADOS() {
  t = dht.readTemperature();  //Lectura del DHT
  TiempoAhora = millis();     //Se cuentan los millis

  switch (estado) {
    case PANTALLA1:

      if (TiempoAhora - TiempoUltimoCambio >= Intervalo)  //delay sin bloqueo
      {
        TiempoUltimoCambio = TiempoAhora;  // importante actualizar el tiempo
        //Mostrar los datos en pantallas
        display.clearDisplay();

        display.setCursor(0, 25);
        display.print("Hora: ");
        display.print(rtc.getTime("%H:%M"));  //Obtiene la hora del wifi y la actualiza

        display.setCursor(0, 40);
        display.print("Temp: ");
        display.print(t);
        display.print("°C ");
        display.display();
      }

      //Lectura para pasar de Estado
      if (lectura1 == PULSADO && lectura2 == PULSADO) {
        estado = ESTADO_CONFIRMACION1;
      }
      break;

    case ESTADO_CONFIRMACION1:
      if (lectura1 == NO_PULSADO && lectura2 == NO_PULSADO) {
        estado = PANTALLA2;
      }
      break;

    case PANTALLA2:
      //Se imprime la hotra y el GMT
      display.clearDisplay();
      display.setCursor(10, 25);
      display.print("Hora: ");
      display.print(rtc.getTime("%H:%M:%S"));  //Obtiene la hora del wifi y la actualiza

      display.setCursor(10, 40);
      display.print("GMT acutal: ");
      display.print(currentGMT);
      display.display();

      //Cambiar al estado de confirmacion 2
      if (lectura1 == PULSADO && lectura2 == PULSADO) {
        estado = ESTADO_CONFIRMACION2;
      }

      //Cambiar al estado de BAJAR
      if (lectura1 == PULSADO) {
        contador1 = 1;
        estado = BAJAR_GMT;
      }

      //Cambiar al estado de SUBIR
      if (lectura2 == PULSADO) {
        contador1 = 1;
        estado = SUBIR_GMT;
      }
      break;

    case ESTADO_CONFIRMACION2:
      if (lectura1 == NO_PULSADO && lectura2 == NO_PULSADO) {
        estado = PANTALLA1;
      }
      break;

    case SUBIR_GMT:
      //Si los dos botones estan apretados se va al estado de confirmacion 2
      if (lectura1 == PULSADO) {
        estado = ESTADO_CONFIRMACION2;
      }

      if (lectura2 == NO_PULSADO) {
        if (contador1 == 1) {
          currentGMT += 1;
          if (currentGMT > 12) currentGMT = -12;
          if (currentGMT < -12) currentGMT = 12;
          syncTimeWithGMT(currentGMT);  //Actualiza la hora con el nuevo GMT
          contador1 = 0;
        }
        estado = PANTALLA2;
      }
      break;

    case BAJAR_GMT:
      //Si los dos botones estan apretados se va al estado de confirmacion 2
      if (lectura2 == PULSADO) {
        estado = ESTADO_CONFIRMACION2;
      }

      if (lectura1 == NO_PULSADO) {
        if (contador1 == 1) {
          currentGMT -= 1;
          if (currentGMT > 12) currentGMT = -12;
          if (currentGMT < -12) currentGMT = 12;
          syncTimeWithGMT(currentGMT);  //Actualiza la hora con el nuevo GMT
          contador1 = 0;
        }
        estado = PANTALLA2;
      }
      break;
  }
}

//Ajuestes del WIFI
void connectToWiFi() {
  Serial.print("Conectando a WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConectado al WiFi");
}

//Sincronizacion del tiempo con internet
void syncTimeWithGMT(int gmtOffsetHours) {
  long gmtOffset_sec = gmtOffsetHours * 3600;
  configTime(gmtOffset_sec, 0, "pool.ntp.org");

  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    rtc.setTimeStruct(timeinfo);  // Ajusta la hora en el ESP32Time
    Serial.println("Hora sincronizada desde NTP");
  } else {
    Serial.println("Fallo al obtener la hora desde NTP");
  }
}