// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// Mapeo del cableado actual: A3 -> D, A2 -> F, A0 -> J, A1 -> K.
//
// Filtro anti-vibraciones fantasma:
// el PRIMER pulso de un pad se envia al instante, y despues de eso ese pad
// se ignora por completo durante LOCKOUT_MS (1 segundo). Cualquier vibracion
// que llegue en ese tiempo se descarta, no importa cuantas sean.
// Cada pad tiene su propio bloqueo, asi que golpear otro pad sigue funcionando.
//
// Si 1 segundo es demasiado para tocar, baja LOCKOUT_MS (por ejemplo 300).

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A3, A2, A0, A1};
const int SERIAL_CHANNELS[PAD_COUNT] = {1, 2, 3, 4};
const unsigned long LOCKOUT_MS = 1000;

int idle_state[PAD_COUNT];
unsigned long locked_until[PAD_COUNT];
bool locked[PAD_COUNT];

void setup() {
	pinMode(LED_BUILTIN, OUTPUT);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		pinMode(PAD_PINS[pad], INPUT_PULLUP);
	}
	Serial.begin(9600);
	delay(100);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		idle_state[pad] = digitalRead(PAD_PINS[pad]);
		locked[pad] = false;
	}
}

void loop() {
	unsigned long now = millis();
	bool any_locked = false;
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		if (locked[pad]) {
			if ((long)(now - locked_until[pad]) >= 0) {
				locked[pad] = false;  // termino el segundo de silencio
			} else {
				any_locked = true;
				continue;  // durante el bloqueo se descarta todo
			}
		}
		if (digitalRead(PAD_PINS[pad]) != idle_state[pad]) {
			Serial.println(SERIAL_CHANNELS[pad]);
			locked[pad] = true;
			locked_until[pad] = now + LOCKOUT_MS;
			any_locked = true;
		}
	}
	digitalWrite(LED_BUILTIN, any_locked ? HIGH : LOW);
}
