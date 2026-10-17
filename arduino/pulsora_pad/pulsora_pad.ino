// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// A0 y A1 salen intercambiados para corregir el cableado actual: A0 -> F, A1 -> D.

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A0, A1, A2, A3};
const int SERIAL_CHANNELS[PAD_COUNT] = {2, 1, 3, 4};
const unsigned long REARM_IDLE_MS = 35;
int idle_state[PAD_COUNT];
bool armed[PAD_COUNT] = {true, true, true, true};
unsigned long last_active[PAD_COUNT] = {0, 0, 0, 0};

void setup() {
	pinMode(LED_BUILTIN, OUTPUT);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		pinMode(PAD_PINS[pad], INPUT_PULLUP);
	}
	Serial.begin(9600);
	delay(100);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		idle_state[pad] = digitalRead(PAD_PINS[pad]);
	}
}

void loop() {
	unsigned long now = millis();
	bool any_hit = false;
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		int state = digitalRead(PAD_PINS[pad]);
		if (state != idle_state[pad]) {
			last_active[pad] = now;
			if (armed[pad]) {
				armed[pad] = false;
				Serial.println(SERIAL_CHANNELS[pad]);
				any_hit = true;
			}
		} else if (now - last_active[pad] >= REARM_IDLE_MS) {
			armed[pad] = true;
		}
	}
	digitalWrite(LED_BUILTIN, any_hit ? HIGH : LOW);
}
