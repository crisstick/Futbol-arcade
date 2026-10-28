class_name HumanController
extends Controller
## Lee el teclado / mando de un jugador local (prefijo de acciones p1_, p2_...).

var prefix: String


func _init(player_index: int) -> void:
	prefix = "p%d_" % player_index


func is_human() -> bool:
	return true


func read_input(_player: FootballPlayer, _game: MatchState) -> PlayerInput:
	var input := PlayerInput.new()
	input.move = Input.get_vector(prefix + "left", prefix + "right", prefix + "up", prefix + "down")
	input.shoot = Input.is_action_just_pressed(prefix + "shoot")
	input.pass_ball = Input.is_action_just_pressed(prefix + "pass")
	input.switch_player = Input.is_action_just_pressed(prefix + "switch")
	return input
