// Pulsora - cuatro pads digitales KY-031 / SW-420.
// Conecta cada salida S a A0-A3; comparte 5V y GND entre los sensores.
// Envia los canales 1-4 por Serial a 9600 baudios para los carriles D/F/J/K.
// Mapeo del cableado actual: A3 -> D, A2 -> F, A0 -> J, A1 -> K.
//
// Filtros contra vibracion excesiva:
//  1. Golpes debiles: un golpe solo cuenta si la senal queda activa al menos
//     MIN_ACTIVE_US microsegundos dentro de una ventana de CONFIRM_WINDOW_US.
//  2. Bloqueo por pad: despues de un golpe, ese pad se ignora PAD_LOCKOUT_MS
//     (absorbe el rebote y la vibracion residual) y debe volver a reposo
//     antes de aceptar otro golpe.
//  3. Bloqueo cruzado: los demas pads se ignoran CROSSTALK_MS para que la
//     vibracion que viaja por la estructura no dispare los vecinos. Dos
//     golpes realmente simultaneos (dos palos) se aceptan porque se miden en
//     la misma ventana.
//
// Para ajustar: pon DEBUG_WIDTHS en true, golpea suave y fuerte, y mira en el
// Monitor Serie las lineas "w<canal>=<microsegundos>". Elige MIN_ACTIVE_US
// entre lo que marcan los golpes flojos que quieres ignorar y los golpes
// normales. Vuelve a ponerlo en false y cierra el Monitor Serie antes de jugar.
// Tambien puedes bajar la sensibilidad girando el potenciometro de cada modulo.

const int PAD_COUNT = 4;
const int PAD_PINS[PAD_COUNT] = {A3, A2, A0, A1};
const int SERIAL_CHANNELS[PAD_COUNT] = {1, 2, 3, 4};

const unsigned long CONFIRM_WINDOW_US = 3000;  // tiempo que se mide cada golpe
const unsigned long MIN_ACTIVE_US = 400;       // sube para ignorar mas golpes flojos
const unsigned long PAD_LOCKOUT_MS = 90;       // pausa del pad tras un golpe
const unsigned long CROSSTALK_MS = 25;         // pausa de los otros pads
const bool DEBUG_WIDTHS = false;

int idle_state[PAD_COUNT];
bool armed[PAD_COUNT];
bool candidate[PAD_COUNT];
unsigned long locked_until[PAD_COUNT];
unsigned long active_us[PAD_COUNT];

void lock_pad(int pad, unsigned long until) {
	if ((long)(until - locked_until[pad]) > 0) {
		locked_until[pad] = until;
	}
}

void setup() {
	pinMode(LED_BUILTIN, OUTPUT);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		pinMode(PAD_PINS[pad], INPUT_PULLUP);
	}
	Serial.begin(9600);
	delay(100);
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		idle_state[pad] = digitalRead(PAD_PINS[pad]);
		armed[pad] = true;
		locked_until[pad] = 0;
	}
}

void loop() {
	unsigned long now = millis();
	bool any_candidate = false;
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		candidate[pad] = false;
		bool active = digitalRead(PAD_PINS[pad]) != idle_state[pad];
		if (!active) {
			armed[pad] = true;
		} else if (armed[pad] && (long)(now - locked_until[pad]) >= 0) {
			candidate[pad] = true;
			any_candidate = true;
		}
	}
	if (!any_candidate) {
		digitalWrite(LED_BUILTIN, LOW);
		return;
	}

	// Mide cuanto tiempo permanece activo cada pad candidato.
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		active_us[pad] = 0;
	}
	unsigned long start = micros();
	unsigned long last = start;
	while (last - start < CONFIRM_WINDOW_US) {
		unsigned long t = micros();
		unsigned long dt = t - last;
		last = t;
		for (int pad = 0; pad < PAD_COUNT; pad++) {
			if (candidate[pad] && digitalRead(PAD_PINS[pad]) != idle_state[pad]) {
				active_us[pad] += dt;
			}
		}
	}

	bool any_hit = false;
	now = millis();
	for (int pad = 0; pad < PAD_COUNT; pad++) {
		if (!candidate[pad]) {
			continue;
		}
		if (DEBUG_WIDTHS) {
			Serial.print("w");
			Serial.print(SERIAL_CHANNELS[pad]);
			Serial.print("=");
			Serial.println(active_us[pad]);
		}
		armed[pad] = false;  // debe volver a reposo antes del siguiente golpe
		if (active_us[pad] >= MIN_ACTIVE_US) {
			Serial.println(SERIAL_CHANNELS[pad]);
			lock_pad(pad, now + PAD_LOCKOUT_MS);
			any_hit = true;
		}
	}
	if (any_hit) {
		for (int pad = 0; pad < PAD_COUNT; pad++) {
			if (!candidate[pad]) {
				lock_pad(pad, now + CROSSTALK_MS);
			}
		}
	}
	digitalWrite(LED_BUILTIN, any_hit ? HIGH : LOW);
}
