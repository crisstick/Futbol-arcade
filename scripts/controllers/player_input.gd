class_name PlayerInput
extends RefCounted
## Órdenes de un jugador durante un tick de simulación. Es lo único que un
## controlador produce, así que en el online basta con enviar esto por la red.

var move := Vector2.ZERO
var shoot := false
var pass_ball := false
var switch_player := false
