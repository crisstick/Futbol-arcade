class_name MatchState
extends Node2D
## Partido de prueba 11 vs 11: monta el campo, los equipos y el balón, y avanza
## la simulación a paso fijo (60 Hz). La lógica trabaja en coordenadas del
## mundo; solo `_sync_view` las pasa a pantalla. Mantenerlo así, en orden y sin
## depender del framerate, es lo que luego permite correrla en un servidor.

const MATCH_SECONDS := 300.0
const SHOT_SPEED := 480.0
const SHOT_LIFT := 80.0
const KICK_COOLDOWN := 0.3
const STEAL_CHANCE := 0.35      # probabilidad de quitar el balón al contacto
const MISSED_STEAL_COOLDOWN := 0.5
const GOAL_PAUSE := 2.5
const CAMERA_FOLLOW := 5.0

## 4-4-2 en fracciones del campo para el equipo que ataca hacia la derecha.
## El primero es el portero.
const FORMATION := [
	Vector2(0.03, 0.5),
	Vector2(0.17, 0.15), Vector2(0.15, 0.38), Vector2(0.15, 0.62), Vector2(0.17, 0.85),
	Vector2(0.31, 0.15), Vector2(0.29, 0.38), Vector2(0.29, 0.62), Vector2(0.31, 0.85),
	Vector2(0.41, 0.42), Vector2(0.41, 0.58),
]
const TEAM_COLORS := [Color("d63c3c"), Color("3c6ad6")]

var ball: Ball
var players: Array[FootballPlayer] = []
var score := [0, 0]
var time_left := MATCH_SECONDS
## Si es true, el jugador seleccionado también lo maneja la IA (pruebas, demo).
var autoplay := false
## A quién va dirigido el último pase mientras el balón está suelto.
var pass_target: FootballPlayer = null

var _field: Node2D
var _entities: Node2D
var _camera: Camera2D
var _cam := Pitch.CENTER
var _hud: CanvasLayer
var _human := HumanController.new(1)
var _ai := AIController.new()
var _selected: FootballPlayer
var _pause := 0.0
## Azar con semilla fija: el mismo partido se repite igual (útil para pruebas
## y para que el servidor online y los clientes coincidan).
var _rng := RandomNumberGenerator.new()
var _kickoff_team := 0


func _ready() -> void:
	_field = Node2D.new()
	_field.set_script(preload("res://scripts/match/field.gd"))
	add_child(_field)

	_entities = Node2D.new()
	_entities.y_sort_enabled = true
	add_child(_entities)

	ball = Ball.new()
	_entities.add_child(ball)

	for team in [0, 1]:
		for i in FORMATION.size():
			var p := FootballPlayer.new()
			p.team = team
			p.number = i + 1
			p.is_keeper = i == 0
			p.color = TEAM_COLORS[team]
			p.home = _formation_point(team, i)
			_entities.add_child(p)
			players.append(p)

	_camera = Camera2D.new()
	add_child(_camera)

	_hud = CanvasLayer.new()
	_hud.set_script(preload("res://scripts/match/hud.gd"))
	add_child(_hud)

	if OS.has_feature("web") and str(JavaScriptBridge.eval("location.search")).contains("demo"):
		autoplay = true   # ?demo en la URL: IA contra IA
	_rng.seed = 2026
	_kickoff(0)
	_hud.set_score(0, 0)
	_sync_view(1.0)


func _formation_point(team: int, i: int) -> Vector2:
	var f: Vector2 = FORMATION[i]
	var x := f.x * Pitch.LENGTH
	if team == 1:
		x = Pitch.LENGTH - x
	return Vector2(x, f.y * Pitch.WIDTH)


## Dónde debe estar un jugador sin balón: su puesto, desplazado con el juego.
func formation_spot(p: FootballPlayer) -> Vector2:
	if p.is_keeper:
		return p.home
	var spot := p.home + Vector2((ball.pos.x - Pitch.CENTER.x) * 0.45, (ball.pos.y - Pitch.CENTER.y) * 0.25)
	if ball.holder != null and ball.holder.team == p.team:
		spot.x += 150.0 if p.team == 0 else -150.0   # con el balón, el equipo sube
	return spot.clamp(Vector2(10, 10), Vector2(Pitch.LENGTH - 10, Pitch.WIDTH - 10))


func _kickoff(team: int) -> void:
	_kickoff_team = team
	for p in players:
		p.pos = p.home
		p.velocity = Vector2.ZERO
		p.facing = Vector2.RIGHT if p.team == 0 else Vector2.LEFT
		p.cooldown = 0.0
	ball.place(Pitch.CENTER)
	pass_target = null
	var taker := _team_players(team)[9]
	taker.pos = Pitch.CENTER + (Vector2.LEFT if team == 0 else Vector2.RIGHT) * 8.0
	_select(_team_players(0)[9])
	_cam = Pitch.CENTER


func _team_players(team: int) -> Array[FootballPlayer]:
	var out: Array[FootballPlayer] = []
	for p in players:
		if p.team == team:
			out.append(p)
	return out


## El jugador de campo (sin contar al portero) más cercano al balón.
func closest_to_ball(team: int) -> FootballPlayer:
	var best: FootballPlayer = null
	var best_d := INF
	for p in _team_players(team):
		if p.is_keeper:
			continue
		var d := p.pos.distance_squared_to(ball.pos)
		if d < best_d:
			best_d = d
			best = p
	return best


func keeper_of(team: int) -> FootballPlayer:
	return _team_players(team)[0]


func nearest_opponent(player: FootballPlayer) -> FootballPlayer:
	var best: FootballPlayer = null
	var best_d := INF
	for p in _team_players(1 - player.team):
		var d := p.pos.distance_squared_to(player.pos)
		if d < best_d:
			best_d = d
			best = p
	return best


## El segundo jugador de campo más cercano al balón (el que cubre).
func second_closest_to_ball(team: int) -> FootballPlayer:
	var first := closest_to_ball(team)
	var best: FootballPlayer = null
	var best_d := INF
	for p in _team_players(team):
		if p.is_keeper or p == first:
			continue
		var d := p.pos.distance_squared_to(ball.pos)
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
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0:
			if time_left <= 0.0:
				score = [0, 0]
				time_left = MATCH_SECONDS
				_hud.set_score(0, 0)
			_kickoff(_kickoff_team)
		_sync_view(delta)
		return

	time_left = maxf(0.0, time_left - delta)
	_hud.set_clock(time_left)
	if time_left <= 0.0:
		_hud.show_banner("FIN DEL PARTIDO", 4.0)
		_pause = 4.0
		_kickoff_team = 0
		return

	# Primero todos deciden mirando el mismo instante y luego todos se mueven.
	# Si no, el equipo que se procesa segundo reacciona con ventaja.
	var inputs: Array[PlayerInput] = []
	for p in players:
		var controller: Controller = _human if p == _selected and not autoplay else _ai
		var input := controller.read_input(p, self)
		if controller.is_human() and input.switch_player and ball.holder != p:
			_select(closest_to_ball(p.team))
		inputs.append(input)

	for i in players.size():
		var p := players[i]
		var input := inputs[i]
		if ball.holder == p:
			if input.shoot:
				_shoot(p, input.move)
			elif input.pass_ball:
				_pass(p, input.move)
		p.step(input, ball.holder == p, delta)

	_update_possession()
	var prev_x := ball.pos.x
	ball.step(delta)
	_check_goal(prev_x)
	_sync_view(delta)


func _sync_view(delta: float) -> void:
	_cam = _cam.lerp(ball.pos, 1.0 - exp(-CAMERA_FOLLOW * delta))
	var half := get_viewport_rect().size / 2.0
	_cam.x = clampf(_cam.x, half.x - Pitch.BORDER, Pitch.LENGTH + Pitch.BORDER - half.x)
	var screen_y := clampf(_cam.y * View.KY, half.y - Pitch.BORDER * 2.0, Pitch.WIDTH * View.KY + Pitch.BORDER - half.y)
	View.cam_x = _cam.x
	_camera.position = Vector2(_cam.x, screen_y)
	_field.queue_redraw()
	ball.sync_view()
	for p in players:
		p.sync_view()


func _shoot(p: FootballPlayer, aim: Vector2) -> void:
	var dir := aim.normalized() if aim.length() > 0.1 else p.facing
	var goal := Pitch.target_goal(p.team)
	if dir.dot((goal - p.pos).normalized()) > 0.3 and absf(dir.x) > 0.05:
		# Ayuda de puntería: si el tiro va hacia el arco pero se abre, lo
		# corrige hasta el palo más cercano.
		var t := (goal.x - p.pos.x) / dir.x
		var y := clampf(p.pos.y + dir.y * t, Pitch.goal_top() + 6.0, Pitch.goal_bottom() - 6.0)
		dir = (Vector2(goal.x, y) - p.pos).normalized()
	ball.kick(dir, SHOT_SPEED, SHOT_LIFT)
	p.cooldown = KICK_COOLDOWN


func _pass(p: FootballPlayer, aim: Vector2) -> void:
	var dir := aim.normalized() if aim.length() > 0.1 else p.facing
	var target: FootballPlayer = null
	var best := -INF
	for mate in _team_players(p.team):
		if mate == p or mate.is_keeper:
			continue
		var to_mate := mate.pos - p.pos
		var forward := to_mate.x * (1.0 if p.team == 0 else -1.0)
		var value := dir.dot(to_mate.normalized()) * 2.0 - to_mate.length() / 300.0 + forward / 250.0
		if to_mate.length() > 350.0:
			value -= 3.0
		if p.is_keeper:
			value = dir.dot(to_mate.normalized()) + to_mate.length() / 400.0
		if value > best:
			best = value
			target = mate
	if target == null:
		return
	var to_target := target.pos + target.velocity * 0.4 - p.pos
	# El balón rodando recorre aprox. v0 / 0.7 píxeles antes de pararse.
	var speed := clampf(to_target.length() * 0.7 + 90.0, 180.0, 450.0)
	# El portero saca por arriba para superar a los delanteros rivales.
	ball.kick(to_target, speed, 150.0 if p.is_keeper else 0.0)
	pass_target = target
	p.cooldown = KICK_COOLDOWN
	if p == _selected:
		_select(target)


func _update_possession() -> void:
	for p in players:
		if p == ball.holder or p.cooldown > 0.0:
			continue
		var keeper_catch := p.is_keeper and Pitch.in_own_box(p.team, ball.pos)
		var reach := FootballPlayer.KEEPER_REACH if keeper_catch else FootballPlayer.CONTROL_RADIUS
		var max_z := Pitch.CROSSBAR_HEIGHT + 6.0 if keeper_catch else 8.0
		if ball.z > max_z or p.pos.distance_to(ball.pos) > reach:
			continue
		var previous := ball.holder
		if previous != null:
			if previous.team == p.team or previous.protection > 0.0:
				continue
			# Al portero con el balón en las manos no se le puede quitar.
			if previous.is_keeper and Pitch.in_own_box(previous.team, previous.pos):
				continue
			# Solo se roba de frente. Desde el costado o desde atrás hará falta
			# la barrida (semana 2).
			if (p.pos - previous.pos).normalized().dot(previous.facing) < 0.4:
				continue
			if _rng.randf() > STEAL_CHANCE:
				p.cooldown = MISSED_STEAL_COOLDOWN
				continue
			previous.cooldown = FootballPlayer.LOSE_BALL_COOLDOWN
			previous.stun = FootballPlayer.STUN
			p.protection = FootballPlayer.STEAL_PROTECTION
		ball.holder = p
		pass_target = null
		if p.team == 0 and p != _selected and not p.is_keeper:
			_select(p)
		return


func _check_goal(prev_x: float) -> void:
	var in_mouth := ball.pos.y > Pitch.goal_top() and ball.pos.y < Pitch.goal_bottom()
	var scorer := -1
	if prev_x >= 0.0 and ball.pos.x < 0.0:
		scorer = 1
	elif prev_x <= Pitch.LENGTH and ball.pos.x > Pitch.LENGTH:
		scorer = 0
	if scorer == -1 or not in_mouth:
		return
	if ball.z >= Pitch.CROSSBAR_HEIGHT:
		ball.pos.x = clampf(ball.pos.x, 0.0, Pitch.LENGTH)
		ball.velocity.x = -ball.velocity.x * Ball.WALL_BOUNCE
		return
	score[scorer] += 1
	_hud.set_score(score[0], score[1])
	_hud.show_banner("¡GOL!", GOAL_PAUSE)
	_pause = GOAL_PAUSE
	_kickoff_team = 1 - scorer
