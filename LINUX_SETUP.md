# Pulsora en Linux

Guia para continuar el proyecto en una PC con Linux y conectar el Arduino Uno.
Esta version usa el puente Python multiplataforma, reintenta cuando el USB se
desconecta y conserva el juego con teclado si no hay placa.

## 1. Actualizar el proyecto

En la carpeta del repositorio:

```bash
git pull origin main
```

Instala Godot 4.7 o una version 4.x compatible, Python 3 y pyserial. En Ubuntu
o Linux Mint:

```bash
sudo apt update
sudo apt install python3 python3-serial
```

No ejecutes Godot con `sudo`.

Para volver a cargar el firmware, instala Arduino IDE 2 desde el gestor de
software de tu distribucion o desde Arduino. El sketch ya cargado permanece en
la placa aunque la desconectes o cambies de PC.

## 2. Permiso para el puerto USB

Conecta el Arduino y mira el nombre del puerto:

```bash
python3 -m serial.tools.list_ports -v
```

Normalmente aparece como `/dev/ttyACM0` o `/dev/ttyUSB0`. Si el usuario no tiene
permiso, agregalo al grupo serial y luego cierra y vuelve a abrir la sesion:

```bash
sudo usermod -aG dialout "$USER"
```

No mantengas abierto el Monitor Serie del IDE mientras corre el juego: el
puerto solo puede estar abierto por un programa a la vez.

## 3. Cargar el sketch del pad

Abre `arduino/pulsora_pad/pulsora_pad.ino` en Arduino IDE, selecciona `Arduino
Uno`, el puerto `/dev/ttyACM0` (o el que aparezca en tu PC) y pulsa Subir.

El firmware lee cuatro modulos digitales SW-420 por `A0-A3`, envia los canales
por serial a 9600 baudios y espera 35 ms de reposo estable para filtrar el
rebote de una misma vibracion. No impone un cooldown fijo por golpe. Por el
cableado actual, `A0` envia el carril `F` y `A1` envia `D`; `A2` y `A3` envian
`J` y `K`.

## 4. Ejecutar y probar

Abre el proyecto en Godot y pulsa Play. Al iniciar, Godot lanza el puente
`tools/arduino_pad_bridge.py`, que detecta automaticamente el puerto, envia
golpes por UDP local y vuelve a buscar el Arduino si se desconecta. El menu
muestra `PAD ARDUINO` en verde cuando recibe el heartbeat.

Para probar los dos pads conectados, elige `PAD TEST` al final de la lista. Es
una pista corta con notas alternadas en `D` y `F`, sin drenaje de vida ni
registro de puntuacion. Golpea el primer pad en las notas `F` y el segundo en
las notas `D`.

Si no aparece `PAD ARDUINO`, comprueba el permiso del puerto, que el Monitor
Serie este cerrado y que `python3 -m serial.tools.list_ports -v` liste el Uno.
El juego tambien funciona con las teclas `D`, `F`, `J` y `K` sin Arduino.
