# Futbol Arcade

Juego de fútbol arcade en pixel art (inspirado en Pixel Cup Soccer y Super Shot Soccer), hecho con **Godot 4.7**. Se juega en el navegador y en Android TV (Tanix).

**Jugar en el navegador:** https://crisstick.github.io/Futbol-arcade/ (se actualiza solo con cada cambio en `main`).

## Controles

| Acción  | Teclado              | Mando / control remoto |
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
scripts/core/               Medidas del campo y configuración de controles
scripts/controllers/        Quién maneja a cada jugador: humano, IA y (pronto) jugador online
scripts/match/              Partido, balón, futbolistas, campo y marcador
tests/smoke_test.gd         Prueba automática: 90 s de IA contra IA
.github/workflows/web.yml   Compila la versión web y la publica en GitHub Pages
```

Cada futbolista recibe sus órdenes de un `Controller`. Hoy existen `HumanController` y `AIController`; para el online se añadirá un controlador remoto, sin tocar la lógica del partido.

## Prueba automática

```
godot --headless --path . --fixed-fps 60 -s tests/smoke_test.gd
```

## Plan

12 semanas hasta la versión 1.0: juego offline con poderes (semanas 0 a 6), multijugador local y online con un humano por jugador (7 a 10), editor de equipos y lanzamiento (11 y 12).
