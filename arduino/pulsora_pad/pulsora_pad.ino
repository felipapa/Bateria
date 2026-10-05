// Pulsora - pad fisico para el juego de bateria
// Sensor tap / vibracion (KY-031 o SW-420) en el pin 2
// Envia el canal del pad por serial a 9600 baudios.
// Canal 1 = tecla D, canal 2 = F, canal 3 = J, canal 4 = K

const int SENSOR_PIN = 2;
const int ACTIVE_STATE = HIGH; // si tu modulo dispara en bajo, cambia a LOW
const unsigned long COOLDOWN_MS = 150;

void setup() {
  pinMode(SENSOR_PIN, INPUT);
  Serial.begin(9600);
}

void loop() {
  static unsigned long last_tap = 0;
  int state = digitalRead(SENSOR_PIN);
  if (state == ACTIVE_STATE && millis() - last_tap > COOLDOWN_MS) {
    last_tap = millis();
    Serial.println('1');
  }
}
