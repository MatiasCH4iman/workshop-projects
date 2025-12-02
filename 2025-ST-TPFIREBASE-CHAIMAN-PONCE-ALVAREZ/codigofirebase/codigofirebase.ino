//GRUPO 6 PONCE CHAIMAN ALVAREZ
  //5LB
  //TP FIREBASE
  // UID FIREBASE: "0GCH3B6GYrSbBuSlZEZah2nu4Dk1"
  #include <Arduino.h>
  #include <Firebase_ESP_Client.h>
  #include <WiFi.h>
  #include <WiFiClientSecure.h>
  #include <U8g2lib.h>
  #include <DHT.h>
  #include "time.h"


  // Ajustes WiFi
  const char* ssid = "MECA-IoT";
  const char* password = "IoT$2025";
  // Ajustes Firebase
  #define Web_API_KEY "AIzaSyCPYRbjzr7HpWhPJfsLvDVi8s7kbNoINA0"
  #define DATABASE_URL "https://st-firebase-5a09c-default-rtdb.firebaseio.com/"
  #define USER_EMAIL "48115713@est.ort.edu.ar"
  #define USER_PASS "chaiFirebase"

  // Objetos Firebase_ESP_Client
  FirebaseData fbdo; //maneja conexiones
  FirebaseAuth auth; //autenticación
  FirebaseConfig config; //config

  // Ajustes NTP
  const char* ntpServer = "pool.ntp.org";
  time_t tiempoMedicion;
  // Ajustes del DHT
  #define DHTPIN 23
  #define DHTTYPE DHT11
  DHT dht(DHTPIN, DHTTYPE);

  unsigned long TiempoAhora;
  float t;
  float umbral = 24;
  // Ajustes Display
  #define SCREEN_WIDTH 128
  #define SCREEN_HEIGHT 64
  U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);
  // Definición de Botones y LED
  #define PULSADO LOW
  #define NO_PULSADO HIGH
  #define PIN_BOT1 34
  #define PIN_BOT2 35
  #define PIN_LED1 25
  // Definición de Estados de la maquina
  enum EstadoMaquina {
    INICIO,
    P1,
    CONFIRMACIONP1,
    P2,
    CONFIRMACIONP2,
    P2B1,
    P2B2,
  };

  // Devuelve un valor string en función del estado
  String estadoMaquinaToString(EstadoMaquina estado) {
    switch (estado) {
      case INICIO: return "INICIO";
      case P1: return "P1";
      case CONFIRMACIONP1: return "CONFIRMACIONP1";
      case P2: return "P2";
      case CONFIRMACIONP2: return "CONFIRMACIONP2";
      case P2B1: return "P2B1";
      case P2B2: return "P2B2";
    }
  }
  // Variable maq de estado
  EstadoMaquina estadoMaquina = INICIO;
  unsigned long estadoStartTime = 0;
  int intervaloEnvio = 30000;

  // Variables generales
  int lectura1;
  int lectura2;
  //Funciones
  void maquinaEstado();
  void actualizarPantalla();
  void funcionUmbral();
  void envioFirebase();

  void setup() {
  Serial.begin(115200);
  u8g2.begin();
  dht.begin();
  pinMode(PIN_BOT1, INPUT);
  pinMode(PIN_BOT2, INPUT);
  pinMode(PIN_LED1, OUTPUT);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectada");
  //Configuro el reloj del ESP32 mediante un server NTP, GMT en 0 (universal) y sin ajuste de horario de verano
  configTime(0, 0, ntpServer);

  // Inicializar Firebase
  config.api_key = Web_API_KEY; 
  config.database_url = DATABASE_URL;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASS;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  // Reserva 4KB de memoria RAM para manejar las respuestas de firebase
  fbdo.setResponseSize(4096);

}

  void loop() {
  //Lectura Botones y DHT
  lectura1 = digitalRead(PIN_BOT1);
  lectura2 = digitalRead(PIN_BOT2);
  t = dht.readTemperature();
  time(&tiempoMedicion);
  if (isnan(t)) {
    Serial.println("Error leyendo el sensor DHT!");
    return;
  }
    funcionUmbral();
    maquinaEstado();
    actualizarPantalla();
    envioFirebase();
  }
  void envioFirebase() {
    if (millis() - estadoStartTime >= intervaloEnvio) {
    estadoStartTime = millis();
    // Obtiene el tiempo actual (timestamp) que es el objeto now de clase time_t
    time_t now;
    time(&now);
    //Establece la ruta en la que va a guardar los datos
    String path = "/Grupo6/Registros/" + String((unsigned long)now);
    //Creo el json para ser enviado
    FirebaseJson json;
    // 4 campos json
    json.set("temperatura", t);
    json.set("umbral", umbral);
    //Convierto now a int ya que por default es tipo long
    json.set("timestamp", int(tiempoMedicion));
    json.set("intervaloEnvio",intervaloEnvio);
  //Envia los datos con setJSON a la base de datos, path.c_str() lo convierte a char en formato json
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
      Serial.println("✅ Datos enviados correctamente");
    } else {
      Serial.print("❌ Error en envío: ");
      //Muestra la razon del error
      Serial.println(fbdo.errorReason());
    }
  }
}
  void maquinaEstado(){
    switch(estadoMaquina){
      case INICIO:
        estadoMaquina = P1;
      break;
      case P1:
        if (lectura1 == PULSADO && lectura2 == PULSADO){
        estadoMaquina = CONFIRMACIONP1;
        }
      break;
      case CONFIRMACIONP1:
        if (lectura1 == NO_PULSADO && lectura2 == NO_PULSADO){
          estadoMaquina = P2;
        }
      break;
      case P2:
        if (lectura1 == PULSADO && lectura2 == PULSADO){
        estadoMaquina = CONFIRMACIONP2;
        }
        else if (lectura1 == PULSADO){
          estadoMaquina = P2B1;
        }
        else if (lectura2 == PULSADO){
          estadoMaquina = P2B2;
        }
      break;
      case CONFIRMACIONP2:
        if (lectura1 == NO_PULSADO && lectura2 == NO_PULSADO){
          estadoMaquina = P1;
        }
      break;
      case P2B1:
        if (lectura1 == NO_PULSADO){
          intervaloEnvio += 30000;
          estadoMaquina = P2;
        }
        else if (lectura2 == PULSADO) {
          estadoMaquina = CONFIRMACIONP2;
        }
      break;
      case P2B2:
        if (lectura2 == NO_PULSADO) {
          if (intervaloEnvio > 30000) {
            intervaloEnvio -= 30000;
          } 
          else {
          intervaloEnvio = 30000;
          }
        estadoMaquina = P2;
      }
        else if (lectura1 == PULSADO) {
          estadoMaquina = CONFIRMACIONP2;
        }
      break;

    }
  }
  void actualizarPantalla() {
    u8g2.clearBuffer();
    
    switch(estadoMaquina){
      case P1:
      case CONFIRMACIONP1:
        u8g2.setFont(u8g2_font_ncenB08_tr);
        u8g2.drawStr(0, 10, "Temperatura Actual:");
        
        u8g2.setFont(u8g2_font_ncenB14_tr);
        char tempBuffer[10];
        sprintf(tempBuffer, "%.1f C", t);
        u8g2.drawStr(0, 30, tempBuffer);

        u8g2.setFont(u8g2_font_ncenB08_tr);
        u8g2.drawStr(0, 50, "Umbral:");
        
        char umbralBuffer[10];
        sprintf(umbralBuffer, "%.1f C", umbral);
        u8g2.setFont(u8g2_font_ncenB14_tr);
        u8g2.drawStr(60, 50, umbralBuffer);
      break;

      case P2:
      case CONFIRMACIONP2:
      case P2B1:
      case P2B2:
        u8g2.setFont(u8g2_font_ncenB08_tr);
        u8g2.drawStr(0, 10, "Intervalo de envio:");

        u8g2.setFont(u8g2_font_ncenB14_tr);
        char intervaloBuffer[10];
        sprintf(intervaloBuffer, "%d s", intervaloEnvio / 1000);
        u8g2.drawStr(0, 35, intervaloBuffer);

        u8g2.setFont(u8g2_font_ncenB08_tr);
        u8g2.drawStr(0, 60, "SW1:+30s  SW2:-30s");
      break;
    }

    u8g2.sendBuffer();
  }

  void funcionUmbral(){
      if (t >= umbral) {
        digitalWrite(PIN_LED1, HIGH);
      }
      else{
        digitalWrite(PIN_LED1, LOW);
      }
  }
