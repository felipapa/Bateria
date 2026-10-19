# Pulsora

Juego de ritmo de cuatro botones hecho en Godot 4, con una
autopista larga y de perspectiva suave inspirada en Guitar Hero. La identidad
visual usa piedra, vitral roto, cadenas, runas doradas y fuego tenue. El nivel
se genera desde `scripts/rhythm_game.gd`.

## Probar el juego

1. Abrir esta carpeta con Godot 4.x.
2. Ejecutar el proyecto (`F6` o el boton Play).
3. En el menu, elegir una cancion con `Arriba/Abajo` y presionar `Enter`.
4. Escribir tu nombre y presionar `Enter`.
5. Tocar las notas cuando lleguen a la linea inferior.

Controles:

- Carril 1: `D` o flecha izquierda
- Carril 2: `F` o flecha abajo
- Carril 3: `J` o flecha arriba
- Carril 4: `K` o flecha derecha
- `Espacio`: pausa
- `R`: reiniciar el nivel
- `Esc`: volver al menu

La barra de vida baja lentamente durante la cancion. Los aciertos recuperan
vida segun su precision y los `BAD`, `MISS` y notas perdidas quitan vida. Si
llega a cero, la partida termina.

Al terminar o perder se guarda automaticamente la mejor puntuacion de ese
jugador para esa cancion. Desde el menu, `T` abre la tabla; si el mismo nombre
juega de nuevo, solo se reemplaza su registro cuando consigue un score mayor.

## Editor de niveles

Desde el menu presiona `E` para abrir el editor de la cancion seleccionada.

- `Espacio`: reproducir o pausar la cancion.
- Click izquierdo en un carril: colocar o quitar una nota.
- Click derecho: borrar la nota cercana.
- Click central: mover el cursor sin colocar una nota.
- `1`: ajustar a negras.
- `2`: ajustar a corcheas.
- `3`: ajustar a semicorcheas.
- `S`: guardar en `levels/` con el chart de la cancion seleccionada.
- `L`: cargar el chart guardado.
- `Enter`: probar el chart actual.
- `Esc`: volver al menu.

Desde el menu tambien se puede administrar el contenido:

- `X`: eliminar una cancion personalizada y su chart, con confirmacion.
- `C`: eliminar todas las notas del chart seleccionado, con confirmacion.
- Las canciones incluidas originalmente no se pueden eliminar.

## Agregar una cancion

Copia un `.mp3` en la carpeta principal del proyecto y vuelve a ejecutar el
juego. En el menu presiona `N`, selecciona la cancion, escribe su BPM, offset y
dificultad con `TAB`, y presiona `Enter`. Se abrira el editor con el chart
completamente vacio para que coloques las notas manualmente. Guarda con `S`; el
nivel quedara registrado en `levels/custom_levels.json` y su chart se guardara
en `levels/`.

El nivel de prueba usa la cancion `This Love` de Maroon 5 a 95.10 BPM, con un
offset inicial de 0.505 segundos detectado desde el audio. Las
ventanas actuales son `Perfect` +/-60 ms, `Great` +/-110 ms y `Good` +/-180 ms.
Los aciertos muestran una explosion en el receptor, hacen crecer el juicio en
pantalla, reproducen un golpe de bateria y generan una vibracion breve con
destellos laterales. Los fallos producen un golpe grave de error.

## Pad fisico con Arduino

El sketch `arduino/pulsora_pad/pulsora_pad.ino` admite cuatro modulos digitales
SW-420 en un Arduino Uno. Con el USB desconectado, conecta sus salidas `DO` a
`A0`, `A1`, `A2` y `A3`, y comparte `5V` y `GND` entre todos. No uses los pines
seriales `0/RX` ni `1/TX` para los sensores.

Sube el sketch a la placa y cierra el Monitor Serie. El puente del juego usa
`pyserial` para detectar el puerto automaticamente en Windows, macOS o Linux y
reintenta si la placa se desconecta.

En Windows instala la dependencia con:

```text
py -m pip install -r requirements.txt
```

En Ubuntu o Linux Mint, instala Python y pyserial con
`sudo apt install python3 python3-serial`; para permisos del puerto USB mira
`LINUX_SETUP.md`.

El Arduino envia los canales `1` a `4` a 9600 baudios y Python los reenvia a
Godot por UDP local. El mapeo actual es `A3 -> D`, `A2 -> F`, `A1 -> J` y
`A0 -> K`. El firmware espera 80 ms de reposo estable entre vibraciones
para filtrar rebotes, pero no impone un intervalo fijo entre golpes. Si
hay varios puertos seriales conectados, ajusta `TAP_SERIAL_PORT` en
`scripts/rhythm_game.gd` (por ejemplo, `COM3` en Windows). Cierra tambien
cualquier Monitor Serie antes de abrir el juego, porque solo un programa puede
usar el puerto a la vez.

Estos modulos digitales detectan golpes, pero no miden bien la fuerza. Para
velocidad/intensidad variable conviene usar piezos con un circuito de proteccion
y una lectura analogica calibrada. Mientras tanto, el juego sigue funcionando
con teclado aunque no haya Arduino conectado.

Para probar la conexion sin sensores, carga temporalmente
`arduino/serial_test/serial_test.ino`. La placa enviara los carriles 1-4 en
secuencia. Cierra el Monitor Serie y ejecuta el juego; al conectar el puente,
los receptores parpadearan siguiendo esos eventos. Luego vuelve a cargar el
sketch `arduino/pulsora_pad/pulsora_pad.ino` cuando tengas los sensores.

## Cancion actual

El proyecto incluye tres canciones en `.mp3`: `This Love` de Maroon 5
(Normal), `You're Gonna Go Far, Kid` de The Offspring (Hard) y `Hero` de
Skillet (Expert). Cada una tiene BPM, offset y densidad de notas propios. El
pack de samples de bateria se usa en los cuatro carriles, con volumen bajo para
no tapar la cancion. Si el pack no carga, queda un sonido sintetico de respaldo.

El nivel `PAD TEST` es una prueba corta de los cuatro sensores. Recorre
`D/F/J/K` y no drena vida ni guarda puntuaciones. Por el cableado actual,
`A3` activa `D`, `A2` activa `F`, `A1` activa `J` y `A0` activa `K`.
