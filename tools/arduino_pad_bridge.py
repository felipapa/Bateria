"""Forward four Arduino drum-pad serial events to Godot over localhost UDP."""

import socket
import sys
import time


UDP_HOST = "127.0.0.1"
DEFAULT_UDP_PORT = 4242
BAUD_RATE = 9600
HEARTBEAT_SECONDS = 1.0


def choose_port(requested_port, list_ports):
    if requested_port and requested_port.lower() != "auto":
        return requested_port
    available = sorted(port.device for port in list_ports())
    return available[0] if available else ""


def lane_from_line(line):
    token = line.strip()
    if token in ("1", "2", "3", "4"):
        return int(token) - 1
    return None


def main():
    try:
        import serial
        from serial.tools import list_ports
    except ImportError:
        print("Falta pyserial. Instala con: py -m pip install -r requirements.txt", file=sys.stderr)
        return 1

    requested_port = sys.argv[1] if len(sys.argv) > 1 else "auto"
    udp_port = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_UDP_PORT
    target = (UDP_HOST, udp_port)

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
            while True:
                port = choose_port(requested_port, list_ports.comports)
                if not port:
                    time.sleep(1.0)
                    continue

                try:
                    with serial.Serial(port, BAUD_RATE, timeout=0.05) as device:
                        print(f"Arduino {port} -> Godot UDP {UDP_HOST}:{udp_port}")
                        # Opening a serial connection can reset many Arduino boards.
                        time.sleep(1.5)
                        device.reset_input_buffer()
                        last_heartbeat = 0.0

                        while True:
                            raw_line = device.readline()
                            now = time.monotonic()
                            if raw_line:
                                lane = lane_from_line(raw_line.decode("ascii", errors="ignore"))
                                if lane is not None:
                                    udp.sendto(str(lane + 1).encode("ascii"), target)
                            if now - last_heartbeat >= HEARTBEAT_SECONDS:
                                connected_ports = {device.device for device in list_ports.comports()}
                                if port not in connected_ports:
                                    raise serial.SerialException("el puerto serial desaparecio")
                                udp.sendto(b"R", target)
                                last_heartbeat = now
                except KeyboardInterrupt:
                    return 0
                except (OSError, serial.SerialException) as error:
                    print(f"Arduino {port} desconectado; buscando de nuevo: {error}", file=sys.stderr)
                    time.sleep(1.0)
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
