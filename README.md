# Futbol Arcade

Juego de fútbol arcade 11 vs 11 en pixel art, con la vista lateral de International Superstar Soccer Deluxe y supertiros al estilo Super Shot Soccer. Hecho con **Godot 4.7**. Destino: Steam (PC); también se juega en el navegador.

**Jugar en el navegador:** https://crisstick.github.io/Futbol-arcade/ (se actualiza solo con cada cambio en `main`).
Agrega `?demo` al final de la dirección para ver un partido de la computadora contra sí misma.

## Controles

| Acción  | Teclado              | Mando |
|---------|----------------------|------------------------|
| Mover   | Flechas o WASD       | Stick izquierdo / cruceta |
| Tirar   | J, Espacio o Enter   | A |
| Pase    | K                    | B |
| Cambiar de jugador | L o Shift | X |

## Abrir el proyecto

1. Instala [Godot 4.7](https://godotengine.org/download) (versión estándar, no la .NET).
2. En Godot: **Importar** → elige el archivo `project.godot` de esta carpeta.
3. Pulsa **F5** para jugar.

## Estructura

```
scenes/main.tscn            Escena principal (el partido)
scripts/core/               Medidas del campo, proyección de la vista ISSD y controles
scripts/controllers/        Quién maneja a cada jugador: humano, IA y (pronto) jugador online
scripts/match/              Partido, balón, futbolistas, campo y marcador
tests/smoke_test.gd         Prueba automática: 3 minutos de IA contra IA
.github/workflows/web.yml   Compila la versión web y la publica en GitHub Pages
```

La simulación trabaja en un campo plano de 105 × 68 m (10 px por metro) y `View` lo proyecta a la vista lateral con perspectiva. Cada futbolista recibe sus órdenes de un `Controller`. Hoy existen `HumanController` y `AIController`; para el online se añadirá un controlador remoto, sin tocar la lógica del partido.

## Prueba automática

```
godot --headless --path . --fixed-fps 60 -s tests/smoke_test.gd
```

## Plan

12 semanas hasta la versión 1.0: juego offline con poderes (semanas 0 a 6), multijugador local y online con una persona por jugador (7 a 10), editor de equipos y preparación para Steam (11 y 12).
