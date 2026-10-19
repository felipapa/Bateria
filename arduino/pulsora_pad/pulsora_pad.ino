// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// Mapeo del cableado actual: A3 -> D, A2 -> F, A1 -> J, A0 -> K.

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A3, A2, A1, A0};
const int SERIAL_CHANNELS[PAD_COUNT] = {1, 2, 3, 4};
const unsigned long REARM_IDLE_MS = 80;
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
