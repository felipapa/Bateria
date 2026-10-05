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

El juego puede recibir golpes de un sensor tap/vibracion (KY-031 o SW-420)
conectado a un Arduino. El sketch esta en `arduino/pulsora_pad/`.

1. Conecta el modulo: `S` del sensor a `A0`, el pin del medio a `5V` y `-` a
   `GND`. Encaja bien el conector de 3 pines sobre el modulo.
2. Abre `arduino/pulsora_pad/pulsora_pad.ino` en el IDE de Arduino y subelo.
3. Cierra el monitor serie y conecta el Arduino por USB.
4. Ejecuta el juego: detecta el puerto `/dev/ttyACM*` o `/dev/ttyUSB*` solo.
5. Cada toque del sensor reemplaza a la tecla `D`. Si usas mas sensores,
   cambia el canal en el sketch enviando `'2'`, `'3'` o `'4'` para las teclas
   `F`, `J` y `K`.

Cuando el pad esta conectado, el menu muestra `PAD ARDUINO` en verde. Si no hay
placa conectada, el juego funciona igual con el teclado.

## Cancion actual

El proyecto incluye tres canciones en `.mp3`: `This Love` de Maroon 5
(Normal), `You're Gonna Go Far, Kid` de The Offspring (Hard) y `Hero` de
Skillet (Expert). Cada una tiene BPM, offset y densidad de notas propios. El
pack de samples de bateria se usa en los cuatro carriles, con volumen bajo para
no tapar la cancion. Si el pack no carga, queda un sonido sintetico de respaldo.
