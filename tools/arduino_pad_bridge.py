"""Forward four Arduino drum-pad serial events to Godot over localhost UDP."""

import os
import socket
import sys
import time


UDP_HOST = "127.0.0.1"
DEFAULT_UDP_PORT = 4242
BAUD_RATE = 9600
HEARTBEAT_SECONDS = 1.0


ARDUINO_VIDS = {0x2341, 0x2A03, 0x1A86, 0x0403, 0x10C4}  # Arduino, clones CH340, FTDI, CP210x


def port_score(port):
    """Higher is better. Negative means: never pick automatically."""
    device = port.device or ""
    name = device.lower()
    if "/ttys" in name or name.startswith("/dev/ttys") or "bluetooth" in name or "bth" in name:
        return -1
    score = 0
    if port.vid in ARDUINO_VIDS:
        score += 10
    text = ((port.description or "") + " " + (port.manufacturer or "")).lower()
    if "arduino" in text or "ch340" in text:
        score += 5
    if "usb" in text:
        score += 4
    if "ttyacm" in name or "ttyusb" in name or "usbmodem" in name or "usbserial" in name:
        score += 3
    if name.startswith("com"):
        score += 1
    return score


def choose_port(requested_port, list_ports):
    if requested_port and requested_port.lower() != "auto":
        return requested_port
    candidates = [(port_score(port), port.device) for port in list_ports()]
    candidates = [item for item in candidates if item[0] >= 0]
    if not candidates:
        return ""
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return candidates[0][1]


def parent_alive(parent_pid):
    """False once the Godot process that launched us is gone."""
    if parent_pid <= 0:
        return True
    if os.name == "nt":
        import ctypes
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.OpenProcess(0x00100000, False, parent_pid)  # SYNCHRONIZE
        if not handle:
            return False
        try:
            return kernel32.WaitForSingleObject(handle, 0) == 0x102  # WAIT_TIMEOUT
        finally:
            kernel32.CloseHandle(handle)
    try:
        os.kill(parent_pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


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
        print("Falta pyserial. Instala con: py -m pip install -r requirements.txt (Windows) o sudo apt install python3-serial (Linux)", file=sys.stderr)
        return 1

    requested_port = sys.argv[1] if len(sys.argv) > 1 else "auto"
    udp_port = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_UDP_PORT
    parent_pid = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    target = (UDP_HOST, udp_port)

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
            while parent_alive(parent_pid):
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
                            if not parent_alive(parent_pid):
                                return 0
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
