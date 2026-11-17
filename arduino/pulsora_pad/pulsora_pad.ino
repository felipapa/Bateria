// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// Mapeo del cableado actual: A3 -> D, A2 -> F, A0 -> J, A1 -> K.
//
// Filtro anti-vibraciones fantasma (bloqueo adaptativo):
// el PRIMER pulso de un pad se envia al instante. Despues ese pad se ignora
// mientras siga vibrando: cada pulso que llega durante el bloqueo lo alarga.
// El pad se libera cuando:
//   - pasaron al menos MIN_LOCKOUT_MS desde el golpe, y
//   - estuvo QUIET_MS sin ningun pulso (la vibracion se apago),
// o cuando pasan MAX_LOCKOUT_MS (limite, por si el sensor se queda activo).
// Asi, la vibracion fantasma (rafagas de pulsos seguidos) se descarta, pero
// puedes volver a golpear apenas el pad se calma.
// Cada pad tiene su propio bloqueo.
//
// Ajuste: si siguen entrando fantasmas, sube QUIET_MS (por ejemplo 250) o
// MIN_LOCKOUT_MS. Si no puedes tocar rapido, baja QUIET_MS o MAX_LOCKOUT_MS.

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A3, A2, A0, A1};
const int SERIAL_CHANNELS[PAD_COUNT] = {1, 2, 3, 4};
const unsigned long MIN_LOCKOUT_MS = 120;
const unsigned long QUIET_MS = 150;
const unsigned long MAX_LOCKOUT_MS = 1000;

int idle_state[PAD_COUNT];
bool locked[PAD_COUNT];
unsigned long hit_time[PAD_COUNT];
unsigned long last_active[PAD_COUNT];

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
		bool active = digitalRead(PAD_PINS[pad]) != idle_state[pad];
		if (locked[pad]) {
			if (active) {
				last_active[pad] = now;  // sigue vibrando: alarga el bloqueo
			}
			unsigned long since_hit = now - hit_time[pad];
			unsigned long since_active = now - last_active[pad];
			bool calm = since_hit >= MIN_LOCKOUT_MS && since_active >= QUIET_MS;
			if (calm || since_hit >= MAX_LOCKOUT_MS) {
				locked[pad] = false;
			} else {
				any_locked = true;
				continue;
			}
		}
		if (active) {
			Serial.println(SERIAL_CHANNELS[pad]);
			locked[pad] = true;
			hit_time[pad] = now;
			last_active[pad] = now;
			any_locked = true;
		}
	}
	digitalWrite(LED_BUILTIN, any_locked ? HIGH : LOW);
}
