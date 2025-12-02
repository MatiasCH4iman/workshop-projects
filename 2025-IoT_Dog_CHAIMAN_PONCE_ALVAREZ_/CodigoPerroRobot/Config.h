/*
IoT Dog
Nombres: Lucas Alejandro Ponce Medina, Zafiro Álvarez Consuegra y Matías David Chaiman Hans
Curso: 5LB
Grupo: 9
*/
#ifndef CONFIG_H
#define CONFIG_H
#include <Arduino.h>

// ==========================================
// PIN DEFINITIONS
// ==========================================

// I2C
#define PIN_I2C_SDA 21
#define PIN_I2C_SCL 22

// LEDs
#define PIN_LED_A 23
#define PIN_LED_B 32
#define PIN_LED_C 33

// Buttons (Internal Pull-up)
#define PIN_BOT_A 18
#define PIN_BOT_B 19
#define PIN_BOT_C 25
#define PIN_BOT_D 26
#define PIN_BOT_E 27

// Sensors (Analog / Digital)
#define PIN_LDR 34
#define PIN_MQ_A 13 // ADC2 - Requires WiFi OFF
#define PIN_MQ_B 14 // ADC2 - Requires WiFi OFF

// Actuators
#define PIN_TRANSISTOR 16 // Relay control
#define PIN_OPTO 17

// ==========================================
// CONSTANTS & DEFAULTS
// ==========================================

// WiFi & MQTT
#define WIFI_SSID_DEFAULT "Fibertel2025"
#define WIFI_PASS_DEFAULT "Diciembre2026$"
#define MQTT_HOST IPAddress(192, 168, 5, 123)
#define MQTT_PORT 1884
#define MQTT_USER "esp32"
#define MQTT_PASS "mirko15"
#define MQTT_PUB_TOPIC "/esp32/datos_sensores"
#define MQTT_DEVICE_ID 29 // Group 5B -> 29

// Telegram
#define TELEGRAM_BOT_TOKEN "8488803162:AAEuwBxhIMxLEEbiUOoIrTwfNidTyJszk9k"
// Chat ID will be discovered or set manually
#define TELEGRAM_CHAT_ID "7692130234" 


// Time
#define NTP_SERVER "south-america.pool.ntp.org"
#define GMT_OFFSET_SEC -10800 // -3 hours
#define DAYLIGHT_OFFSET_SEC 0

// Timing
#define DEFAULT_MQTT_INTERVAL 30000
#define DEFAULT_READ_INTERVAL 60000

// Threshold Defaults (Can be overwritten by EEPROM)
#define DEFAULT_TEMP_THRESH 30.0
#define DEFAULT_HUM_THRESH 70.0
#define DEFAULT_LDR_THRESH 800  // 0-4095
#define DEFAULT_GAS_THRESH 2000 // 0-4095

// ==========================================
// ENUMS & STRUCTURES
// ==========================================

enum SystemState {
    STATE_INIT,
    STATE_NORMAL,
    STATE_ALERT,
    STATE_MENU,
    STATE_ERROR
};

struct SensorData {
    float temperature;
    float humidity;
    int lightLevel;
    int gasLevelA;
    int gasLevelB;
    String timestamp;
};

struct ConfigData {
    float tempThreshold;
    float humThreshold;
    int ldrThreshold;
    int gasThreshold;
    unsigned long mqttInterval;
    long gmtOffset;
};

#endif
