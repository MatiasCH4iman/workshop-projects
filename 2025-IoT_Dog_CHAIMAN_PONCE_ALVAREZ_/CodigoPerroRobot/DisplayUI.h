/*
IoT Dog
Nombres: Lucas Alejandro Ponce Medina, Zafiro Álvarez Consuegra y Matías David Chaiman Hans
Curso: 5LB
Grupo: 9
*/
#ifndef DISPLAYUI_H
#define DISPLAYUI_H

#include "Config.h"
#include <LiquidCrystal_I2C.h>
#include <Wire.h>

class DisplayManager {
public:
    void begin();
    void update(SystemState state, SensorData data, ConfigData config);
    void handleMenuInput(int buttonPressed, ConfigData &config); // Returns true if config changed

private:
    void drawStatusScreen(SensorData data);
    void drawAlertScreen(SensorData data);
    void drawMenuScreen(ConfigData config);
    
    int menuIndex = 0;
    bool inSubMenu = false;
};

#endif
