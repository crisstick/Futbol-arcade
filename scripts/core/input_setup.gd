extends Node
## Crea las acciones de entrada por código para no depender de editar el
## Input Map a mano. Cada jugador humano local tiene su prefijo (p1_, p2_...).
## El jugador 1 usa teclado y el primer mando; el control remoto del Tanix
## envía flechas y Enter, así que también funciona.

const ACTIONS := ["left", "right", "up", "down", "shoot", "pass", "switch"]


func _ready() -> void:
	_add_player(1, {
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP],
		"down": [KEY_S, KEY_DOWN],
		"shoot": [KEY_J, KEY_SPACE, KEY_ENTER],
		"pass": [KEY_K],
		"switch": [KEY_L, KEY_SHIFT],
	}, 0)


func _add_player(index: int, keys: Dictionary, joypad: int) -> void:
	var prefix := "p%d_" % index
	for action in ACTIONS:
		var name: String = prefix + action
		if not InputMap.has_action(name):
			InputMap.add_action(name, 0.2)
		for key in keys.get(action, []):
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(name, ev)

	_add_axis(prefix + "left", joypad, JOY_AXIS_LEFT_X, -1.0)
	_add_axis(prefix + "right", joypad, JOY_AXIS_LEFT_X, 1.0)
	_add_axis(prefix + "up", joypad, JOY_AXIS_LEFT_Y, -1.0)
	_add_axis(prefix + "down", joypad, JOY_AXIS_LEFT_Y, 1.0)
	_add_button(prefix + "left", joypad, JOY_BUTTON_DPAD_LEFT)
	_add_button(prefix + "right", joypad, JOY_BUTTON_DPAD_RIGHT)
	_add_button(prefix + "up", joypad, JOY_BUTTON_DPAD_UP)
	_add_button(prefix + "down", joypad, JOY_BUTTON_DPAD_DOWN)
	_add_button(prefix + "shoot", joypad, JOY_BUTTON_A)
	_add_button(prefix + "pass", joypad, JOY_BUTTON_B)
	_add_button(prefix + "switch", joypad, JOY_BUTTON_X)


func _add_axis(action: String, device: int, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = device
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


func _add_button(action: String, device: int, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = button
	InputMap.action_add_event(action, ev)
