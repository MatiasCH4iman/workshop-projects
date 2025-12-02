class MPU6050Sensor{
    public:
        int numeroSensor;
        float accX, accY, accZ;
        float gyroX,gyroY, gyroZ;
    MPU6050Sensor(float ax, float ay, float az, float gx, float gy, float gz) {
        accX = ax;
        accY = ay;
        accZ = az;
        gyroX = gx;
        gyroY = gy;
        gyroZ = gz;
    }
}

const int cantidadSensores = 5;
// Definición de pines transistor
const int pinesTransistores[cantidadSensores] = {A0,A1,A2,A3,A4};
// Definición de lista de objetos
    MPU6050Sensor = listaSensores [cantidadSensores];
// Definición estado default transistor
#define LEER HIGH
#define NOLEER LOW
void semaforoSensores();
void setup(){
    for(int i = 0; i < cantidadSensores; i++){
        pinMode(pinesTransistores[i], OUTPUT);
    }
}
void loop(){
    semaforoSensores();
    delay(500);
}
void semaforoSensores(){
    for(int i = 0; i < cantidadSensores; i++){
        digitalWrite(pinTransistores[i], LEER);
        digitalWrite(pinTransistores[i], NOLEER);
        //Lee los valores de los sensores
        float ax = mpu.getAccelerationX();
        float ay = mpu.getAccelerationY();
        float az = mpu.getAccelerationZ();
        float gx = mpu.getRotationX();
        float gy = mpu.getRotationY();
        float gz = mpu.getRotationZ();
        //Guarda los datos en el objeto
        listaSensores[i] = (MPU6050Sensor(ax,ay,az,gx,gy,g));
        digitalWrite(pinesTransistores[i], NOLEER); // Apaga transistor
    }
}
