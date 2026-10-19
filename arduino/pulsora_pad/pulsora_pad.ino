// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// Mapeo del cableado actual: A3 -> D, A2 -> F, A0 -> J, A1 -> K.

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A3, A2, A0, A1};
const int SERIAL_CHANNELS[PAD_COUNT] = {1, 2, 3, 4};
int idle_state[PAD_COUNT];
int last_state[PAD_COUNT];

void setup() {
	pinMode(LED_BUILTIN, OUTPUT);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		pinMode(PAD_PINS[pad], INPUT_PULLUP);
	}
	Serial.begin(9600);
	delay(100);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		idle_state[pad] = digitalRead(PAD_PINS[pad]);
		last_state[pad] = idle_state[pad];
	}
}

void loop() {
	bool any_hit = false;
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		int state = digitalRead(PAD_PINS[pad]);
		if (state != last_state[pad]) {
			last_state[pad] = state;
			if (state != idle_state[pad]) {
				Serial.println(SERIAL_CHANNELS[pad]);
				any_hit = true;
			}
		}
	}
	digitalWrite(LED_BUILTIN, any_hit ? HIGH : LOW);
}
