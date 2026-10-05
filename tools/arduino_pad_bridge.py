import glob
import os
import select
import socket
import sys
import termios
import time


def find_port():
    for pattern in ("/dev/ttyACM*", "/dev/ttyUSB*"):
        ports = sorted(glob.glob(pattern))
        if ports:
            return ports[0]
    return ""


def configure_serial(fd, baud):
    settings = termios.tcgetattr(fd)
    settings[0] = 0
    settings[1] = 0
    settings[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
    settings[3] = 0
    settings[4] = baud
    settings[5] = baud
    settings[6][termios.VMIN] = 0
    settings[6][termios.VTIME] = 1
    termios.tcsetattr(fd, termios.TCSANOW, settings)


def main():
    port = sys.argv[1] if len(sys.argv) > 1 else "auto"
    if port == "auto":
        port = find_port()
    if not port:
        return 1

    fd = os.open(port, os.O_RDONLY | os.O_NOCTTY | os.O_NONBLOCK)
    configure_serial(fd, termios.B9600)
    udp_port = int(sys.argv[2]) if len(sys.argv) > 2 else 4242
    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    target = ("127.0.0.1", udp_port)
    udp.sendto(b"R", target)
    time.sleep(1.5)

    buffer = bytearray()
    armed = True
    last_tap = 0.0
    last_heartbeat = time.monotonic()

    try:
        while True:
            readable, _, _ = select.select([fd], [], [], 0.05)
            if readable:
                try:
                    data = os.read(fd, 256)
                except BlockingIOError:
                    data = b""
                for byte in data:
                    if byte in (10, 13):
                        if buffer:
                            token = buffer.decode("ascii", "ignore").strip()
                            buffer.clear()
                            now = time.monotonic()
                            if token in ("1", "2", "3", "4"):
                                if now - last_tap >= 0.12:
                                    udp.sendto(token.encode("ascii"), target)
                                    last_tap = now
                                armed = True
                                continue
                            try:
                                value = float(token)
                            except ValueError:
                                continue
                            threshold = 0.25 if abs(value) <= 5.0 else 50.0
                            if value > threshold:
                                if armed and now - last_tap >= 0.12:
                                    udp.sendto(b"1", target)
                                    last_tap = now
                                armed = False
                            else:
                                armed = True
                    elif len(buffer) < 32:
                        buffer.append(byte)

            now = time.monotonic()
            if now - last_heartbeat >= 1.0:
                udp.sendto(b"R", target)
                last_heartbeat = now
    finally:
        os.close(fd)
        udp.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, termios.error):
        raise SystemExit(1)
