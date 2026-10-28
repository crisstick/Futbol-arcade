class_name MatchState
extends Node2D
## Partido de prueba: monta el campo, los equipos y el balón, y avanza la
## simulación a paso fijo (60 Hz). Mantener toda la lógica aquí, en orden y sin
## depender del framerate, es lo que luego permite correrla en un servidor.

const TEAM_SIZE := 3
const MATCH_SECONDS := 180.0
const SHOT_SPEED := 300.0
const SHOT_LIFT := 70.0
const KICK_COOLDOWN := 0.3
const GOAL_PAUSE := 2.5

## Formación inicial en fracciones del campo propio (x: 0 = portería propia).
const FORMATION := [Vector2(0.22, 0.5), Vector2(0.5, 0.25), Vector2(0.5, 0.75)]
const TEAM_COLORS := [Color("d63c3c"), Color("3c6ad6")]

var ball: Ball
var players: Array[FootballPlayer] = []
var score := [0, 0]
var time_left := MATCH_SECONDS
## Si es true, el jugador seleccionado también lo maneja la IA (pruebas, demo).
var autoplay := false

var _entities: Node2D
var _camera: Camera2D
var _hud: CanvasLayer
var _human := HumanController.new(1)
var _ai := AIController.new()
var _selected: FootballPlayer
var _pause := 0.0
var _kickoff_team := 0


func _ready() -> void:
	var field := Node2D.new()
	field.set_script(preload("res://scripts/match/field.gd"))
	add_child(field)

	_entities = Node2D.new()
	_entities.y_sort_enabled = true
	add_child(_entities)

	ball = Ball.new()
	_entities.add_child(ball)

	for team in [0, 1]:
		for i in TEAM_SIZE:
			var p := FootballPlayer.new()
			p.team = team
			p.number = i + 1
			p.color = TEAM_COLORS[team]
			p.home = _formation_point(team, i)
			_entities.add_child(p)
			players.append(p)

	_camera = Camera2D.new()
	_camera.limit_left = int(-Pitch.BORDER)
	_camera.limit_top = int(-Pitch.BORDER)
	_camera.limit_right = int(Pitch.LENGTH + Pitch.BORDER)
	_camera.limit_bottom = int(Pitch.WIDTH + Pitch.BORDER)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	add_child(_camera)

	_hud = CanvasLayer.new()
	_hud.set_script(preload("res://scripts/match/hud.gd"))
	add_child(_hud)

	_kickoff(0)
	_hud.set_score(0, 0)


func _formation_point(team: int, i: int) -> Vector2:
	var f: Vector2 = FORMATION[i % FORMATION.size()]
	var x := f.x * Pitch.LENGTH * 0.5
	if team == 1:
		x = Pitch.LENGTH - x
	return Vector2(x, f.y * Pitch.WIDTH)


func _kickoff(team: int) -> void:
	_kickoff_team = team
	for p in players:
		p.position = p.home
		p.velocity = Vector2.ZERO
		p.facing = Vector2.RIGHT if p.team == 0 else Vector2.LEFT
		p.cooldown = 0.0
	ball.place(Pitch.CENTER)
	var taker := _team_players(team)[1]
	taker.position = Pitch.CENTER + (Vector2.LEFT if team == 0 else Vector2.RIGHT) * 8.0
	_select(_team_players(0)[1])
	_camera.position = Pitch.CENTER
	_camera.reset_smoothing()


func _team_players(team: int) -> Array[FootballPlayer]:
	var out: Array[FootballPlayer] = []
	for p in players:
		if p.team == team:
			out.append(p)
	return out


func closest_to_ball(team: int) -> FootballPlayer:
	var best: FootballPlayer = null
	var best_d := INF
	for p in _team_players(team):
		var d := p.position.distance_squared_to(ball.position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _select(p: FootballPlayer) -> void:
	if _selected != null:
		_selected.selected = false
	_selected = p
	p.selected = true


func _physics_process(delta: float) -> void:
	_camera.position = ball.position
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0:
			if time_left <= 0.0:
				score = [0, 0]
				time_left = MATCH_SECONDS
				_hud.set_score(0, 0)
			_kickoff(_kickoff_team)
		return

	time_left = maxf(0.0, time_left - delta)
	_hud.set_clock(time_left)
	if time_left <= 0.0:
		_hud.show_banner("FIN DEL PARTIDO", 4.0)
		_pause = 4.0
		_kickoff_team = 0
		return

	for p in players:
		var controller: Controller = _human if p == _selected and not autoplay else _ai
		var input := controller.read_input(p, self)
		if controller.is_human() and input.switch_player and ball.holder != p:
			_select(_closest_other(p))
		if ball.holder == p:
			if input.shoot:
				_shoot(p, input.move)
			elif input.pass_ball:
				_pass(p, input.move)
		p.step(input, ball.holder == p, delta)

	_update_possession()
	var prev_x := ball.position.x
	ball.step(delta)
	_check_goal(prev_x)


func _closest_other(current: FootballPlayer) -> FootballPlayer:
	var best := current
	var best_d := INF
	for p in _team_players(current.team):
		if p == current:
			continue
		var d := p.position.distance_squared_to(ball.position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _shoot(p: FootballPlayer, aim: Vector2) -> void:
	var dir := aim.normalized() if aim.length() > 0.1 else p.facing
	var to_goal := (Pitch.target_goal(p.team) - p.position).normalized()
	if dir.dot(to_goal) > 0.3:
		dir = dir.lerp(to_goal, 0.35).normalized()
	ball.kick(dir, SHOT_SPEED, SHOT_LIFT)
	p.cooldown = KICK_COOLDOWN


func _pass(p: FootballPlayer, aim: Vector2) -> void:
	var dir := aim.normalized() if aim.length() > 0.1 else p.facing
	var target: FootballPlayer = null
	var best := -INF
	for mate in _team_players(p.team):
		if mate == p:
			continue
		var to_mate := mate.position - p.position
		var score_dir := dir.dot(to_mate.normalized()) * 2.0 - to_mate.length() / 300.0
		if score_dir > best:
			best = score_dir
			target = mate
	if target == null:
		return
	var to_target := target.position + target.velocity * 0.4 - p.position
	# El balón rodando recorre aprox. v0 / 0.6 píxeles antes de pararse.
	var speed := clampf(to_target.length() * 0.6 + 60.0, 90.0, 320.0)
	ball.kick(to_target, speed, 0.0)
	p.cooldown = KICK_COOLDOWN
	if p == _selected:
		_select(target)


func _update_possession() -> void:
	if ball.z > 8.0:
		return
	for p in players:
		if p == ball.holder or p.cooldown > 0.0:
			continue
		if p.position.distance_to(ball.position) > FootballPlayer.CONTROL_RADIUS:
			continue
		var previous := ball.holder
		if previous != null:
			if previous.team == p.team:
				continue
			previous.cooldown = FootballPlayer.LOSE_BALL_COOLDOWN
		ball.holder = p
		if p.team == 0 and p != _selected:
			_select(p)
		return


func _check_goal(prev_x: float) -> void:
	var in_mouth := ball.position.y > Pitch.goal_top() and ball.position.y < Pitch.goal_bottom()
	var scorer := -1
	if prev_x >= 0.0 and ball.position.x < 0.0:
		scorer = 1
	elif prev_x <= Pitch.LENGTH and ball.position.x > Pitch.LENGTH:
		scorer = 0
	if scorer == -1 or not in_mouth:
		return
	if ball.z >= Pitch.CROSSBAR_HEIGHT:
		ball.position.x = clampf(ball.position.x, 0.0, Pitch.LENGTH)
		ball.velocity.x = -ball.velocity.x * Ball.WALL_BOUNCE
		return
	score[scorer] += 1
	_hud.set_score(score[0], score[1])
	_hud.show_banner("¡GOL!", GOAL_PAUSE)
	_pause = GOAL_PAUSE
	_kickoff_team = 1 - scorer
