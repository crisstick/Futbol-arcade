class_name AIController
extends Controller
## IA mínima: el más cercano de cada equipo va por el balón y el resto guarda
## su puesto de la formación, desplazado según dónde esté el balón. Con balón,
## avanza hacia el arco y tira al llegar cerca. El portero cubre su arco.

const SHOOT_RANGE := 230.0
const KEEPER_LINE := 14.0       # distancia a la que se para el portero
const KEEPER_RUSH := 110.0      # sale por el balón si está así de cerca
const KEEPER_HOLD := 0.8        # segundos con el balón antes de sacar


func read_input(player: FootballPlayer, game: MatchState) -> PlayerInput:
	if player.is_keeper:
		return _keeper(player, game)

	var input := PlayerInput.new()
	var ball := game.ball
	var goal := Pitch.target_goal(player.team)

	if ball.holder == player:
		var to_goal := goal - player.pos
		var dir := to_goal.normalized()
		input.move = dir
		if to_goal.length() < SHOOT_RANGE:
			# Apunta al palo más lejos del portero rival.
			var keeper := game.keeper_of(1 - player.team)
			var corner := Pitch.goal_top() + 8.0
			if keeper.pos.y < Pitch.CENTER.y:
				corner = Pitch.goal_bottom() - 8.0
			input.move = (Vector2(goal.x, corner) - player.pos).normalized()
			input.shoot = true
			return input
		var rival := game.nearest_opponent(player)
		if rival != null:
			var to_rival := rival.pos - player.pos
			if to_rival.length() < 70.0 and to_rival.normalized().dot(dir) > 0.5:
				# Esquiva al rival que tiene delante y, si está encima, pasa.
				var side := dir.orthogonal()
				if side.dot(to_rival) > 0.0:
					side = -side
				# Cerca de la banda, esquiva hacia el centro.
				if absf(player.pos.y - Pitch.CENTER.y) > Pitch.WIDTH / 2.0 - 70.0:
					side = Vector2(0, signf(Pitch.CENTER.y - player.pos.y))
				input.move = (dir + side * 1.3).normalized()
				if to_rival.length() < 35.0 and player.hold_time > 0.15:
					# Pasa hacia el lado libre, no a través del rival.
					input.move = (dir + side * 2.0).normalized()
					input.pass_ball = true
		return input

	if ball.holder == null and game.pass_target == player:
		input.move = _chase(player.pos, ball.pos + ball.velocity * 0.3)
		return input

	var defending := ball.holder != null and ball.holder.team != player.team
	if game.closest_to_ball(player.team) == player:
		var target := ball.pos
		if defending:
			# Entra por delante del rival, entre el balón y su propio arco.
			target += (Pitch.own_goal(player.team) - ball.pos).normalized() * 10.0
		input.move = _chase(player.pos, target)
		return input

	var own_half := (ball.pos.x < Pitch.CENTER.x) == (player.team == 0)
	if defending and own_half and game.second_closest_to_ball(player.team) == player:
		# Cubre: se pone entre el balón y su arco.
		var own := Pitch.own_goal(player.team)
		input.move = _chase(player.pos, ball.pos.lerp(own, 0.25))
		return input

	input.move = _seek(player.pos, game.formation_spot(player))
	return input


func _keeper(player: FootballPlayer, game: MatchState) -> PlayerInput:
	var input := PlayerInput.new()
	var ball := game.ball
	var goal := Pitch.own_goal(player.team)
	var out := 1.0 if player.team == 0 else -1.0

	if ball.holder == player:
		input.move = Vector2(out, 0)
		input.pass_ball = player.hold_time > KEEPER_HOLD
		return input

	var near := ball.pos.distance_to(goal) < KEEPER_RUSH and Pitch.in_own_box(player.team, ball.pos)
	if near and (ball.holder == null or ball.holder.team != player.team):
		input.move = _chase(player.pos, ball.pos)
		return input

	# Si viene un tiro, va al punto por donde el balón cruzará la línea.
	var toward_goal := ball.velocity.x * -out
	if ball.holder == null and toward_goal > 200.0:
		var t := (player.pos.x - ball.pos.x) / ball.velocity.x
		if t > 0.0:
			var y_cross := ball.pos.y + ball.velocity.y * t
			if absf(y_cross - Pitch.CENTER.y) < Pitch.GOAL_MOUTH:
				input.move = _chase(player.pos, Vector2(player.pos.x, y_cross))
				return input

	# Se coloca sobre la línea entre el balón y el centro del arco.
	var to_ball := (ball.pos - goal).normalized()
	var spot := goal + to_ball * KEEPER_LINE / maxf(absf(to_ball.x), 0.3)
	spot.y = clampf(spot.y, Pitch.goal_top(), Pitch.goal_bottom())
	input.move = _chase(player.pos, spot) if player.pos.distance_to(spot) > 3.0 else Vector2.ZERO
	return input


## Corre a toda velocidad (para ir por el balón).
func _chase(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	return d.normalized() if d.length() > 1.0 else Vector2.ZERO


## Llega frenando (para ir a un puesto).
func _seek(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	if d.length() < 4.0:
		return Vector2.ZERO
	return d.normalized() if d.length() > 20.0 else d / 20.0
