/*
IoT Dog
Nombres: Lucas Alejandro Ponce Medina, Zafiro Álvarez Consuegra y Matías David Chaiman Hans
Curso: 5LB
Grupo: 9
*/

#include "Config.h"
#include "DisplayUI.h"
#include <Preferences.h>
#include <Adafruit_AHTX0.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include <AsyncMqttClient.h>

DisplayManager display;
Preferences preferences;
Adafruit_AHTX0 aht;

// WiFi & Telegram
WiFiClientSecure client;
UniversalTelegramBot bot(TELEGRAM_BOT_TOKEN, client);
String chat_id = TELEGRAM_CHAT_ID; // Can be updated dynamically

// MQTT
AsyncMqttClient mqttClient;
TimerHandle_t mqttReconnectTimer;
TimerHandle_t wifiReconnectTimer;
char mqtt_payload[150];

// Data Queue Structure
typedef struct {
  long time;
  float T1;  // Temp
  float H1;  // Hum
  float luz; // Light
  float G1;  // Gas A
  float G2;  // Gas B
  bool oct;  // Placeholder
  bool Alarma; // Gas Alert
} estructura;

const int valor_max_struct = 1000;
estructura datos_struct[valor_max_struct];
estructura aux2;
int indice_entra = 0;
int indice_saca = 0;
bool flag_vacio = 1;

// Task Handles
TaskHandle_t TaskTelegram;

// Mock Data
SystemState currentState = STATE_NORMAL;
SensorData currentSensorData;
ConfigData sysConfig;

// --- Button Handling Logic ---
struct ButtonState {
    int lastReading = HIGH;
    int stableState = HIGH;
    unsigned long lastDebounceTime = 0;
};

ButtonState btnA, btnB, btnC, btnD, btnE;

bool wasPressed(int pin, ButtonState &state) {
    int reading = digitalRead(pin);
    bool pressed = false;

    if (reading != state.lastReading) {
        state.lastDebounceTime = millis();
    }

    if ((millis() - state.lastDebounceTime) > 50) {
        if (reading != state.stableState) {
            state.stableState = reading;
            if (state.stableState == LOW) {
                pressed = true;
            }
        }
    }
    
    state.lastReading = reading;
    return pressed;
}

// --- EEPROM Functions ---
void loadConfigFromEEPROM() {
    preferences.begin("iotdog", false); // false = read/write mode
    
    sysConfig.tempThreshold = preferences.getFloat("tempThresh", 30.0);
    sysConfig.gasThreshold = preferences.getInt("gasThresh", 50);
    sysConfig.ldrThreshold = preferences.getInt("ldrThresh", 40);
    sysConfig.humThreshold = preferences.getFloat("humThresh", 70.0);
    sysConfig.gmtOffset = preferences.getLong("gmtOffset", -10800);
    sysConfig.mqttInterval = preferences.getULong("mqttInterval", 30000);
    
    preferences.end();
    
    Serial.println("Configuration loaded from EEPROM");
}

void saveConfigToEEPROM() {
    preferences.begin("iotdog", false);
    
    preferences.putFloat("tempThresh", sysConfig.tempThreshold);
    preferences.putInt("gasThresh", sysConfig.gasThreshold);
    preferences.putInt("ldrThresh", sysConfig.ldrThreshold);
    preferences.putFloat("humThresh", sysConfig.humThreshold);
    preferences.putLong("gmtOffset", sysConfig.gmtOffset);
    preferences.putULong("mqttInterval", sysConfig.mqttInterval);
    
    preferences.end();
    
    Serial.println("Configuration saved to EEPROM");
}

// --- MQTT Functions ---
void connectToMqtt() {
  Serial.println("Connecting to MQTT...");
  mqttClient.connect();
}

void onMqttConnect(bool sessionPresent) {
  Serial.println("Connected to MQTT.");
}

void onMqttDisconnect(AsyncMqttClientDisconnectReason reason) {
  Serial.print("Disconnected from MQTT. Reason: ");
  Serial.println((int)reason);
  if (WiFi.isConnected()) {
    xTimerStart(mqttReconnectTimer, 0);
  }
}

void onMqttPublish(uint16_t packetId) {
  Serial.print("Publish acknowledged. packetId: ");
  Serial.println(packetId);
}

// Queue Functions
void fun_entra() {
  if (indice_entra >= valor_max_struct) {
    indice_entra = 0;
  }
  
  // Get Timestamp
  long timestamp = time(NULL);
  
  datos_struct[indice_entra].time = timestamp;
  datos_struct[indice_entra].T1 = currentSensorData.temperature;
  datos_struct[indice_entra].H1 = currentSensorData.humidity;
  datos_struct[indice_entra].luz = currentSensorData.lightLevel;
  datos_struct[indice_entra].G1 = currentSensorData.gasLevelA;
  datos_struct[indice_entra].G2 = currentSensorData.gasLevelB;
  datos_struct[indice_entra].oct = 0; // Placeholder
  datos_struct[indice_entra].Alarma = (currentSensorData.gasLevelA > sysConfig.gasThreshold || currentSensorData.gasLevelB > sysConfig.gasThreshold);

  indice_entra++;
  // Serial.print("Queue In: "); Serial.println(indice_entra);
}

void fun_saca() {
  if (indice_saca != indice_entra) {
    aux2.time = datos_struct[indice_saca].time;
    aux2.T1 = datos_struct[indice_saca].T1;
    aux2.H1 = datos_struct[indice_saca].H1;
    aux2.luz = datos_struct[indice_saca].luz;
    aux2.G1 = datos_struct[indice_saca].G1;
    aux2.G2 = datos_struct[indice_saca].G2;
    aux2.oct = datos_struct[indice_saca].oct;
    aux2.Alarma = datos_struct[indice_saca].Alarma;

    flag_vacio = 0;

    if (indice_saca >= (valor_max_struct - 1)) {
      indice_saca = 0;
    } else {
      indice_saca++;
    }
    // Serial.print("Queue Out: "); Serial.println(indice_saca);
  } else {
    flag_vacio = 1;
  }
}

void fun_envio_mqtt() {
  fun_saca();
  if (flag_vacio == 0) {
    // Format: ID&Time&Temp&Hum&Luz&Gas1&Gas2&Oct&Alarma
    snprintf(mqtt_payload, 150, "%d&%ld&%.2f&%.2f&%.2f&%.2f&%.2f&%u&%u", 
             MQTT_DEVICE_ID, aux2.time, aux2.T1, aux2.H1, aux2.luz, aux2.G1, aux2.G2, aux2.oct, aux2.Alarma);
             
    Serial.print("Publishing: "); Serial.println(mqtt_payload);
    mqttClient.publish(MQTT_PUB_TOPIC, 1, true, mqtt_payload);
  }
}

// --- Telegram Task (Core 1) ---
void loopTaskTelegram(void * parameter) {
    Serial.print("Telegram Task running on core ");
    Serial.println(xPortGetCoreID());

    // Init MQTT Timers
    mqttReconnectTimer = xTimerCreate("mqttTimer", pdMS_TO_TICKS(2000), pdFALSE, (void*)0, reinterpret_cast<TimerCallbackFunction_t>(connectToMqtt));
    wifiReconnectTimer = xTimerCreate("wifiTimer", pdMS_TO_TICKS(2000), pdFALSE, (void*)0, reinterpret_cast<TimerCallbackFunction_t>(connectToWifi));

    // Init MQTT Client
    mqttClient.onConnect(onMqttConnect);
    mqttClient.onDisconnect(onMqttDisconnect);
    mqttClient.onPublish(onMqttPublish);
    mqttClient.setServer(MQTT_HOST, MQTT_PORT);
    mqttClient.setCredentials(MQTT_USER, MQTT_PASS);

    // Connect to WiFi
    connectToWifi();
    
    // Wait for WiFi Connection before NTP
    Serial.print("Waiting for WiFi");
    int retry = 0;
    while (WiFi.status() != WL_CONNECTED && retry < 20) {
        delay(500);
        Serial.print(".");
        retry++;
    }
    Serial.println("");
    
    // Force MQTT Connect if connected
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("WiFi Connected (Wait Loop). Attempting MQTT...");
        connectToMqtt();
    }
    
    // Init Time (NTP)
    configTime(sysConfig.gmtOffset, DAYLIGHT_OFFSET_SEC, NTP_SERVER);
    Serial.println("Waiting for time...");
    struct tm timeinfo;
    while(!getLocalTime(&timeinfo)){
        Serial.print(".");
        delay(500);
    }
    Serial.println("\nTime synchronized");
    
    client.setInsecure(); // For Telegram (skip cert validation)

    unsigned long lastMsgCheck = 0;
    unsigned long lastDataSend = 0;
    unsigned long lastQueueAdd = 0;
    bool gasAlertSent = false;
    long lastGmtOffset = sysConfig.gmtOffset;

    for(;;) {
        // 0. Check for GMT Offset Change
        if (sysConfig.gmtOffset != lastGmtOffset) {
            Serial.print("GMT Offset changed to: "); Serial.println(sysConfig.gmtOffset);
            configTime(sysConfig.gmtOffset, DAYLIGHT_OFFSET_SEC, NTP_SERVER);
            lastGmtOffset = sysConfig.gmtOffset;
            
            // Force time update
            struct tm timeinfo;
            getLocalTime(&timeinfo); 
        }

        // Helper lambda to get formatted time
        auto getTimestamp = []() -> String {
            struct tm timeinfo;
            if(!getLocalTime(&timeinfo)){
                return "[No Time]";
            }
            char timeStringBuff[20];
            strftime(timeStringBuff, sizeof(timeStringBuff), "%H:%M:%S", &timeinfo);
            return String(timeStringBuff);
        };

        // 1. Check for new messages (Telegram)
        if (millis() - lastMsgCheck > 1000) {
            int numNewMessages = bot.getUpdates(bot.last_message_received + 1);
            while (numNewMessages) {
                for (int i = 0; i < numNewMessages; i++) {
                    String from_id = bot.messages[i].chat_id;
                    String text = bot.messages[i].text;
                    String from_name = bot.messages[i].from_name;
                    
                    Serial.println("Msg from: " + from_name + " ID: " + from_id);
                    
                    // Security Check: Only allow configured Chat ID
                    if (from_id != TELEGRAM_CHAT_ID) {
                        Serial.println("Unauthorized access attempt from: " + from_id);
                        bot.sendMessage(from_id, "⛔ Acceso Denegado. Este bot es privado.", "");
                        continue; // Skip to next message
                    }

                    Serial.println("Text: " + text);
                    
                    // Update global chat_id (redundant if constant, but keeps logic consistent)
                    if (chat_id == "") {
                        chat_id = from_id;
                    }

                    if (text == "/sensor") {
                        String msg = "🕒 " + getTimestamp() + "\n";
                        msg += "🌡️ Temp: " + String(currentSensorData.temperature, 1) + "°C\n";
                        msg += "💧 Hum: " + String(currentSensorData.humidity, 0) + "%\n";
                        msg += "☀️ Luz: " + String(currentSensorData.lightLevel) + "%\n";
                        msg += "⚠️ Gas A: " + String(currentSensorData.gasLevelA) + "%\n";
                        msg += "⚠️ Gas B: " + String(currentSensorData.gasLevelB) + "%";
                        bot.sendMessage(from_id, msg, "");
                    }
                }
                numNewMessages = bot.getUpdates(bot.last_message_received + 1);
            }
            lastMsgCheck = millis();
        }

        // 2. Periodic Data Send (MQTT & Telegram)
        if (millis() - lastDataSend > sysConfig.mqttInterval) {
            
            // A. Snapshot current data to Queue (so MQTT has fresh data)
            fun_entra(); 

            // B. MQTT Publish (Flush Queue)
            if (mqttClient.connected()) {
                // Keep sending while queue has data (to clear backlog if any)
                // For now, just one send per interval as per original logic, 
                // or we can loop. Let's stick to one send to match the interval rhythm.
                fun_envio_mqtt();
            } else {
                Serial.println("MQTT not connected, data queued.");
            }

            // C. Telegram Report
            if (chat_id != "") {
                String msg = "📊 Reporte Periódico (" + getTimestamp() + "):\n";
                msg += "🌡️ Temp: " + String(currentSensorData.temperature, 1) + "°C\n";
                msg += "💧 Hum: " + String(currentSensorData.humidity, 0) + "%\n";
                msg += "☀️ Luz: " + String(currentSensorData.lightLevel) + "%\n";
                msg += "⚠️ Gas A: " + String(currentSensorData.gasLevelA) + "%\n";
                msg += "⚠️ Gas B: " + String(currentSensorData.gasLevelB) + "%";
                bot.sendMessage(chat_id, msg, "");
            }
            lastDataSend = millis();
        }

        // 4. Gas Alert
        bool gasCritical = (currentSensorData.gasLevelA > sysConfig.gasThreshold || currentSensorData.gasLevelB > sysConfig.gasThreshold);
        if (gasCritical && !gasAlertSent && chat_id != "") {
            bot.sendMessage(chat_id, "🚨 PELIGRO (" + getTimestamp() + "): Nivel de gas peligrosamente alto! 🚨", "");
            gasAlertSent = true;
        } else if (!gasCritical) {
            gasAlertSent = false; // Reset alert when levels return to normal
        }

        vTaskDelay(10 / portTICK_PERIOD_MS); // Yield
    }
}

// Helper for WiFi connection (used by timer)
void connectToWifi() {
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(WIFI_SSID_DEFAULT, WIFI_PASS_DEFAULT);
}

void WiFiEvent(WiFiEvent_t event) {
    Serial.printf("[WiFi-event] event: %d\n", event);
    switch(event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
        Serial.println("WiFi connected");
        Serial.println("IP address: ");
        Serial.println(WiFi.localIP());
        connectToMqtt();
        break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
        Serial.println("WiFi lost connection");
        xTimerStop(mqttReconnectTimer, 0); // ensure we don't reconnect to MQTT while reconnecting to Wi-Fi
        xTimerStart(wifiReconnectTimer, 0);
        break;
    }
}
// -----------------------------

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Display Test...");

  // Register WiFi Event Handler
  WiFi.onEvent(WiFiEvent);

  // Init LEDs
  pinMode(PIN_LED_A, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);
  pinMode(PIN_LED_C, OUTPUT);
  
  // Turn OFF LEDs as requested (initially)
  digitalWrite(PIN_LED_A, LOW);
  digitalWrite(PIN_LED_B, LOW);
  digitalWrite(PIN_LED_C, LOW);

  // Init Buttons
  pinMode(PIN_BOT_A, INPUT_PULLUP); // Menu Toggle
  pinMode(PIN_BOT_B, INPUT_PULLUP); // Next
  pinMode(PIN_BOT_C, INPUT_PULLUP); // Increase
  pinMode(PIN_BOT_D, INPUT_PULLUP); // Unused / Conflict
  pinMode(PIN_BOT_E, INPUT_PULLUP); // Decrease (New)

  // Init Sensors
  pinMode(PIN_LDR, INPUT);
  pinMode(PIN_MQ_A, INPUT);
  pinMode(PIN_MQ_B, INPUT);

  // Initialize Mock Data
  currentSensorData.temperature = 0.0; // Will be updated by sensor
  currentSensorData.humidity = 0.0;    // Will be updated by sensor
  currentSensorData.lightLevel = 30; // 30% (below 40% threshold)
  currentSensorData.gasLevelA = 30; // 30% (below 50% threshold)
  currentSensorData.gasLevelB = 35; // 35%
  currentSensorData.timestamp = "12:00:00";

  // Init AHT10
  if (!aht.begin()) {
    Serial.println("Could not find AHT10? Check wiring");
  } else {
    Serial.println("AHT10 found");
  }

  // Load configuration from EEPROM (or use defaults if first time)
  loadConfigFromEEPROM();
  
  // Init Display
  display.begin();
  Serial.println("Display Initialized.");

  // Create Telegram Task on Core 1
  xTaskCreatePinnedToCore(
      loopTaskTelegram,   /* Task function. */
      "TaskTelegram",     /* name of task. */
      10000,              /* Stack size of task */
      NULL,               /* parameter of the task */
      1,                  /* priority of the task */
      &TaskTelegram,      /* Task handle to keep track of created task */
      1);                 /* pin task to core 1 */
}


void loop() {
  
  // 1. Handle Buttons
  
  // Individual Buttons
  if (wasPressed(PIN_BOT_A, btnA)) {
      // Toggle Menu
      if (currentState != STATE_MENU) {
          currentState = STATE_MENU;
      } else {
          // Exiting menu - save to EEPROM
          saveConfigToEEPROM();
          currentState = STATE_NORMAL;
      }
      Serial.println("Button A Pressed: Toggle Menu");
  }

  if (currentState == STATE_MENU) {
      if (wasPressed(PIN_BOT_B, btnB)) {
          display.handleMenuInput(1, sysConfig); // Next item
          Serial.println("Button B Pressed: Next");
      }
      
      if (wasPressed(PIN_BOT_C, btnC)) {
          display.handleMenuInput(2, sysConfig); // Increase
          Serial.println("Button C Pressed: Increase");
      }

      if (wasPressed(PIN_BOT_D, btnD)) {
          display.handleMenuInput(3, sysConfig); // Decrease
          Serial.println("Button D Pressed: Decrease");
      }
  }

  // 2. Update Data (Sensor Reading)
  static unsigned long lastUpdate = 0;
  if (millis() - lastUpdate > 2000) {
      lastUpdate = millis();
      
      sensors_event_t humidity, temp;
      aht.getEvent(&humidity, &temp);
      
      currentSensorData.temperature = temp.temperature;
      currentSensorData.humidity = humidity.relative_humidity;
      
      Serial.print("Temp: "); Serial.print(currentSensorData.temperature);
      Serial.print(" Hum: "); Serial.println(currentSensorData.humidity);
      
      // Read LDR
      int ldrRaw = analogRead(PIN_LDR);
      // Map 0-4095 to 0-100%
      // Note: LDR wiring usually gives lower value for more light or vice-versa depending on pull-up/down.
      // Assuming standard: High light -> Low resistance -> Voltage change.
      // Let's map directly for now: 0 = Dark, 4095 = Bright (or inverted, user can adjust)
      currentSensorData.lightLevel = map(ldrRaw, 0, 4095, 0, 100);
      
      Serial.print("LDR Raw: "); Serial.print(ldrRaw);
      Serial.print(" Light %: "); Serial.println(currentSensorData.lightLevel);
      
      // Simulate Gas Sensors (User requested simulation)
      // Simple sine wave simulation for "alive" look
      float simVal = (sin(millis() / 2000.0) + 1.0) * 20.0 + 10.0; // Oscillates between 10% and 50%
      currentSensorData.gasLevelA = (int)simVal;
      currentSensorData.gasLevelB = (int)simVal + 5;
      
      Serial.print("Gas A (Sim): "); Serial.print(currentSensorData.gasLevelA);
      Serial.print("% Gas B (Sim): "); Serial.println(currentSensorData.gasLevelB);
  }

  // 3. Update Display
  display.update(currentState, currentSensorData, sysConfig);

  // 4. Alert Logic (LEDs)
  
  // LED B is now free (or can be used for something else)
  digitalWrite(PIN_LED_B, LOW);

  // Temperature & Light Alert -> LED A
  // Priority: Light (Blink) > Temperature (Steady)
  
  bool tempAlert = (currentSensorData.temperature > sysConfig.tempThreshold);
  bool lightAlert = (currentSensorData.lightLevel > sysConfig.ldrThreshold);
  
  if (lightAlert) {
      // Blink LED A for Light Alert
      if ((millis() / 250) % 2 == 0) {
          digitalWrite(PIN_LED_A, HIGH);
      } else {
          digitalWrite(PIN_LED_A, LOW);
      }
  } else if (tempAlert) {
      // Steady ON for Temperature Alert
      digitalWrite(PIN_LED_A, HIGH);
  } else {
      digitalWrite(PIN_LED_A, LOW);
  }

  // Gas & Humidity Alert -> LED C
  // Priority: Gas (Steady - Critical) > Humidity (Blink - Warning)
  
  bool gasAlert = (currentSensorData.gasLevelA > sysConfig.gasThreshold || currentSensorData.gasLevelB > sysConfig.gasThreshold);
  bool humAlert = (currentSensorData.humidity > sysConfig.humThreshold);

  if (gasAlert) {
      // Steady ON for Gas Alert (Critical)
      digitalWrite(PIN_LED_C, HIGH);
  } else if (humAlert) {
      // Blink LED C for Humidity Alert
      if ((millis() / 250) % 2 == 0) {
          digitalWrite(PIN_LED_C, HIGH);
      } else {
          digitalWrite(PIN_LED_C, LOW);
      }
  } else {
      digitalWrite(PIN_LED_C, LOW);
  }
  
  delay(10);
}
