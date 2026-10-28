class_name AIController
extends Controller
## IA mínima de prueba: el más cercano va por el balón, los demás guardan su
## posición desplazada según dónde esté el balón. Con balón, avanza y tira.

const SHOOT_RANGE := 170.0


func read_input(player: FootballPlayer, game: MatchState) -> PlayerInput:
	var input := PlayerInput.new()
	var ball := game.ball
	var goal := Pitch.target_goal(player.team)

	if ball.holder == player:
		var to_goal := goal - player.position
		input.move = to_goal.normalized()
		if to_goal.length() < SHOOT_RANGE:
			input.shoot = true
		return input

	if game.closest_to_ball(player.team) == player:
		input.move = _seek(player.position, ball.position)
		return input

	var shift := (ball.position.x - Pitch.CENTER.x) * 0.5
	var target := player.home + Vector2(shift, (ball.position.y - Pitch.CENTER.y) * 0.25)
	input.move = _seek(player.position, target)
	return input


func _seek(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	if d.length() < 4.0:
		return Vector2.ZERO
	return d.normalized()
