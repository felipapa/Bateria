#!/usr/bin/env bash
# Lanza Pulsora en Linux y revisa que todo este listo para el pad Arduino.
cd "$(dirname "$0")" || exit 1

if [ "$(id -u)" -eq 0 ]; then
	echo "No ejecutes el juego con sudo."
	exit 1
fi

GODOT="${GODOT:-}"
if [ -z "$GODOT" ]; then
	for candidate in godot4 godot Godot_v4*; do
		if command -v "$candidate" >/dev/null 2>&1; then
			GODOT="$candidate"
			break
		fi
	done
fi
if [ -z "$GODOT" ]; then
	echo "No encuentro Godot. Instala Godot 4.x o ejecuta: GODOT=/ruta/a/godot ./run_linux.sh"
	exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "Falta python3 (sudo apt install python3 python3-serial). El juego va con teclado igual."
elif ! python3 -c "import serial" >/dev/null 2>&1; then
	echo "Falta pyserial para el pad: sudo apt install python3-serial. El juego va con teclado igual."
fi

if ls /dev/ttyACM* /dev/ttyUSB* >/dev/null 2>&1; then
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx dialout; then
		echo "Aviso: tu usuario no esta en el grupo dialout. Ejecuta una vez:"
		echo "  sudo usermod -aG dialout \"$USER\"   (y reinicia la sesion)"
	fi
else
	echo "No veo el Arduino en /dev/ttyACM* ni /dev/ttyUSB*; se jugara con teclado (D F J K)."
fi

exec "$GODOT" --path . "$@"
