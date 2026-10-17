// Temporary end-to-end test for the Pulsora serial bridge.
// No sensors are needed. Sends lanes 1-4 repeatedly at 9600 baud.

const int LED_PIN = LED_BUILTIN;
const unsigned long TEST_INTERVAL_MS = 900;

unsigned long last_test = 0;
int lane = 1;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
  delay(1000);
}

void loop() {
  unsigned long now = millis();
  if (now - last_test >= TEST_INTERVAL_MS) {
    last_test = now;
    Serial.println(lane);
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    lane = lane % 4 + 1;
  }
}
