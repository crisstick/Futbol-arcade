class_name Controller
extends RefCounted
## Base de quien maneja a un jugador: IA, humano local o (más adelante)
## humano remoto. El partido no sabe ni le importa cuál es.


func is_human() -> bool:
	return false


func read_input(_player: FootballPlayer, _game: MatchState) -> PlayerInput:
	return PlayerInput.new()
