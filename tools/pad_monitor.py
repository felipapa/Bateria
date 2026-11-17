"""Muestra lo que manda el Arduino, sin el juego. Sirve para diagnosticar el pad.

Uso:   python3 tools/pad_monitor.py            (Linux)
       py -3 tools/pad_monitor.py              (Windows)
       python3 tools/pad_monitor.py /dev/ttyACM0

Cierra el juego antes: solo un programa puede usar el puerto a la vez.
Golpea los pads; cada linea muestra el canal (1=D 2=F 3=J 4=K), el tiempo desde el
golpe anterior de ese mismo pad y cuantos van. Ctrl+C para terminar.
"""

import sys
import time

sys.path.insert(0, __file__.rsplit("tools", 1)[0] + "tools")
import arduino_pad_bridge as bridge

NAMES = {"1": "D", "2": "F", "3": "J", "4": "K"}


def main():
    try:
        import serial
        from serial.tools import list_ports
    except ImportError:
        print("Falta pyserial (Linux: sudo apt install python3-serial)")
        return 1
    ports = list(list_ports.comports())
    print("Puertos vistos:")
    for port in ports:
        print("  %-16s vid=%s  %s  (puntaje %d)" % (port.device, port.vid, port.description, bridge.port_score(port)))
    requested = sys.argv[1] if len(sys.argv) > 1 else "auto"
    port = bridge.choose_port(requested, list_ports.comports)
    if not port:
        print("No hay puerto. En Linux: revisa el cable y el grupo dialout.")
        return 1
    print("Usando %s a %d baudios. Golpea los pads (Ctrl+C para salir)." % (port, bridge.BAUD_RATE))
    try:
        device = serial.Serial(port, bridge.BAUD_RATE, timeout=0.2)
    except (OSError, serial.SerialException) as error:
        print("No pude abrir el puerto: %s" % error)
        print("Cierra el juego/Monitor Serie. En Linux: sudo usermod -aG dialout $USER y reinicia sesion.")
        return 1
    time.sleep(1.5)
    device.reset_input_buffer()
    last = {}
    counts = {}
    start = time.monotonic()
    try:
        while True:
            raw = device.readline()
            if not raw:
                continue
            text = raw.decode("ascii", errors="replace").strip()
            now = time.monotonic()
            if text in NAMES:
                gap = (now - last[text]) if text in last else None
                last[text] = now
                counts[text] = counts.get(text, 0) + 1
                gap_text = "%.3f s desde el anterior" % gap if gap is not None else "primero"
                print("%6.2fs  pad %s (canal %s)  #%d  %s" % (now - start, NAMES[text], text, counts[text], gap_text))
            else:
                print("%6.2fs  linea rara: %r  (el programa de la placa no es el de Pulsora?)" % (now - start, text))
    except KeyboardInterrupt:
        print("\nTotales:", {NAMES[k]: v for k, v in sorted(counts.items())})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
