// Pulsora - pad fisico para el juego de bateria
// Sensor tap / vibracion (KY-031 o SW-420)
// Cableado: S del sensor -> A0, del medio -> 5V, - -> GND
// Envia el canal del pad por serial a 9600 baudios.
// Canal 1 = tecla D, canal 2 = F, canal 3 = J, canal 4 = K
// Al detectar un golpe parpadea el LED L de la placa.

const int SENSOR_PIN = A0;
const unsigned long COOLDOWN_MS = 150;
int idle_state = LOW;

void setup() {
  pinMode(SENSOR_PIN, INPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
  delay(100);
  idle_state = digitalRead(SENSOR_PIN);
}

void loop() {
  static unsigned long last_tap = 0;
  int state = digitalRead(SENSOR_PIN);
  if (state != idle_state && millis() - last_tap > COOLDOWN_MS) {
    last_tap = millis();
    Serial.println('1');
    digitalWrite(LED_BUILTIN, HIGH);
    delay(60);
    digitalWrite(LED_BUILTIN, LOW);
  }
}
