/*
IoT Dog
Nombres: Lucas Alejandro Ponce Medina, Zafiro Álvarez Consuegra y Matías David Chaiman Hans
Curso: 5LB
Grupo: 9
*/
#include "DisplayUI.h"

// Initialize LCD with address 0x27, 16 columns, 2 rows
LiquidCrystal_I2C lcd(0x27, 16, 2);

void DisplayManager::begin() {
    lcd.init();
    lcd.backlight();
    lcd.setCursor(0, 0);
    lcd.print("Iniciando perro robot...");
    delay(1000);
    lcd.clear();
}

void DisplayManager::update(SystemState state, SensorData data, ConfigData config) {
    lcd.clear(); // Clear before drawing new state
    
    switch(state) {
        case STATE_NORMAL:
        case STATE_ALERT:
            drawStatusScreen(data);
            break;
        case STATE_MENU:
            drawMenuScreen(config);
            break;
        default:
            lcd.setCursor(0, 0);
            lcd.print("Error");
            break;
    }
}

void DisplayManager::drawStatusScreen(SensorData data) {
    // Row 0: T:25.5 H:60%
    lcd.setCursor(0, 0);
    lcd.print("T:"); lcd.print(data.temperature, 1);
    lcd.print(" H:"); lcd.print(data.humidity, 0); lcd.print("%");

    // Row 1: L:500 G:100
    lcd.setCursor(0, 1);
    lcd.print("L:"); lcd.print(data.lightLevel);
    lcd.print(" G:"); lcd.print(data.gasLevelA);
}

void DisplayManager::drawMenuScreen(ConfigData config) {
    lcd.setCursor(0, 0);
    
    switch(menuIndex) {
        case 0:
            lcd.print("T:"); lcd.print(config.tempThreshold, 1);
            break;
        case 1:
            lcd.print("G:"); lcd.print(config.gasThreshold); lcd.print("%");
            break;
        case 2:
            lcd.print("L:"); lcd.print(config.ldrThreshold); lcd.print("%");
            break;
        case 3:
            lcd.print("H:"); lcd.print(config.humThreshold, 0); lcd.print("%");
            break;
        case 4:
            lcd.print("GMT:"); lcd.print(config.gmtOffset / 3600); lcd.print("h");
            break;
        case 5:
            lcd.print("MQTT:"); lcd.print(config.mqttInterval / 1000); lcd.print("s");
            break;
    }
}

void DisplayManager::handleMenuInput(int buttonPressed, ConfigData &config) {
    // buttonPressed: 0=None, 1=Next, 2=Increase, 3=Decrease
    Serial.print("MenuInput: "); Serial.println(buttonPressed);
    
    switch(buttonPressed) {
        case 1: // Next
            menuIndex++;
            if (menuIndex > 5) menuIndex = 0; // Cycle 0-5
            Serial.print("Menu Index: "); Serial.println(menuIndex);
            
            // Print current value when switching to it
            switch(menuIndex) {
                case 0:
                    Serial.print("Current Temp Thresh: "); Serial.println(config.tempThreshold);
                    break;
                case 1:
                    Serial.print("Current Gas Thresh: "); Serial.println(config.gasThreshold);
                    break;
                case 2:
                    Serial.print("Current Light Thresh: "); Serial.println(config.ldrThreshold);
                    break;
                case 3:
                    Serial.print("Current Humidity Thresh: "); Serial.println(config.humThreshold);
                    break;
                case 4:
                    Serial.print("Current GMT Offset (h): "); Serial.println(config.gmtOffset / 3600);
                    break;
                case 5:
                    Serial.print("Current MQTT Interval (s): "); Serial.println(config.mqttInterval / 1000);
                    break;
            }
            break;
            
        case 2: // Increase
            switch(menuIndex) {
                case 0:
                    config.tempThreshold += 1.0;
                    Serial.print("New Temp Thresh: "); Serial.println(config.tempThreshold);
                    break;
                case 1:
                    config.gasThreshold += 5;
                    if(config.gasThreshold > 100) config.gasThreshold = 100;
                    Serial.print("New Gas Thresh: "); Serial.println(config.gasThreshold);
                    break;
                case 2:
                    config.ldrThreshold += 5;
                    if(config.ldrThreshold > 100) config.ldrThreshold = 100;
                    Serial.print("New Light Thresh: "); Serial.println(config.ldrThreshold);
                    break;
                case 3:
                    config.humThreshold += 5;
                    if(config.humThreshold > 100) config.humThreshold = 100;
                    Serial.print("New Humidity Thresh: "); Serial.println(config.humThreshold);
                    break;
                case 4:
                    config.gmtOffset += 3600;
                    if(config.gmtOffset / 3600 > 14) config.gmtOffset = -12 * 3600; // Wrap to -12
                    Serial.print("New GMT Offset (h): "); Serial.println(config.gmtOffset / 3600);
                    break;
                case 5:
                    config.mqttInterval += 5000;
                    Serial.print("New MQTT Interval (s): "); Serial.println(config.mqttInterval / 1000);
                    break;
            }
            break;
            
        case 3: // Decrease
            switch(menuIndex) {
                case 0:
                    config.tempThreshold -= 1.0;
                    Serial.print("New Temp Thresh: "); Serial.println(config.tempThreshold);
                    break;
                case 1:
                    config.gasThreshold -= 5;
                    if(config.gasThreshold < 0) config.gasThreshold = 0;
                    Serial.print("New Gas Thresh: "); Serial.println(config.gasThreshold);
                    break;
                case 2:
                    config.ldrThreshold -= 5;
                    if(config.ldrThreshold < 0) config.ldrThreshold = 0;
                    Serial.print("New Light Thresh: "); Serial.println(config.ldrThreshold);
                    break;
                case 3:
                    config.humThreshold -= 5;
                    if(config.humThreshold < 0) config.humThreshold = 0;
                    Serial.print("New Humidity Thresh: "); Serial.println(config.humThreshold);
                    break;
                case 4:
                    config.gmtOffset -= 3600;
                    if(config.gmtOffset / 3600 < -12) config.gmtOffset = 14 * 3600; // Wrap to +14
                    Serial.print("New GMT Offset (h): "); Serial.println(config.gmtOffset / 3600);
                    break;
                case 5:
                    config.mqttInterval -= 5000;
                    if(config.mqttInterval < 30000) config.mqttInterval = 30000; // Minimum 30 seconds
                    Serial.print("New MQTT Interval (s): "); Serial.println(config.mqttInterval / 1000);
                    break;
            }
            break;
    }
}
