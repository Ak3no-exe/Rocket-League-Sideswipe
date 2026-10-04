extends Node2D

const MENU := 0
const COUNT := 1
const PLAY := 2
const GOAL := 3
const OVER := 4
const HW := 1200.0
const FY := 450.0
const GOAL_TOP := 190.0
const CarScript = preload("res://scripts/car.gd")
const BallScript = preload("res://scripts/ball.gd")
const HudScript = preload("res://scripts/hud.gd")

var state := MENU
var score := [0, 0]
var time_left := 120.0
var count := 3.0
var msg_t := 0.0
var overtime := false
var xp_gain := 0
var last_scorer := 0
var cars: Array = []
var player
var ball: RigidBody2D
var cam: Camera2D
var hud

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0b1030"))
	_setup_input()
	_build_arena()
	ball = BallScript.new()
	add_child(ball)
	cam = Camera2D.new()
	add_child(cam)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HudScript.new()
	hud.game = self
	layer.add_child(hud)
	to_menu()

func _setup_input() -> void:
	var map := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP], "boost": [KEY_SHIFT, KEY_S, KEY_DOWN]}
	for a in map:
		InputMap.add_action(a)
		for k in map[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)

func _build_arena() -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 2
	sb.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 0.3
	pm.bounce = 0.4
	sb.physics_material_override = pm
	add_child(sb)
	var segs := [
		[Vector2(-1360, FY), Vector2(-1360, GOAL_TOP)],
		[Vector2(-1360, GOAL_TOP), Vector2(-HW, GOAL_TOP)],
		[Vector2(-HW, GOAL_TOP), Vector2(-HW, -250)],
		[Vector2(-HW, -250), Vector2(-1000, -450)],
	]
	var all := [[Vector2(-1360, FY), Vector2(1360, FY)], [Vector2(-1000, -450), Vector2(1000, -450)]]
	for s in segs:
		all.append(s)
		all.append([Vector2(-s[0].x, s[0].y), Vector2(-s[1].x, s[1].y)])
	for s in all:
		var cs := CollisionShape2D.new()
		var sh := SegmentShape2D.new()
		sh.a = s[0]
		sh.b = s[1]
		cs.shape = sh
		sb.add_child(cs)

func _draw() -> void:
	var o := PackedVector2Array([
		Vector2(-HW, FY), Vector2(-HW, -250), Vector2(-1000, -450),
		Vector2(1000, -450), Vector2(HW, -250), Vector2(HW, FY)])
	draw_colored_polygon(o, Color("121a4d"))
	draw_line(Vector2(0, -450), Vector2(0, FY), Color(1, 1, 1, 0.12), 3.0)
	draw_arc(Vector2(0, 150), 220.0, PI, TAU, 48, Color(1, 1, 1, 0.12), 3.0)
	draw_rect(Rect2(-1360, GOAL_TOP, 160, 260), Color("2f7bff", 0.35))
	draw_rect(Rect2(HW, GOAL_TOP, 160, 260), Color("ff8a2b", 0.35))
	draw_polyline(o, Color(0.35, 0.82, 1.0, 0.25), 14.0)
	draw_polyline(o, Color("5ad2ff"), 5.0)
	draw_line(Vector2(-1360, FY), Vector2(1360, FY), Color("5ad2ff"), 5.0)
	draw_polyline(PackedVector2Array([Vector2(-HW, GOAL_TOP), Vector2(-1360, GOAL_TOP), Vector2(-1360, FY)]), Color("2f7bff"), 6.0)
	draw_polyline(PackedVector2Array([Vector2(HW, GOAL_TOP), Vector2(1360, GOAL_TOP), Vector2(1360, FY)]), Color("ff8a2b"), 6.0)

func start_match(m: int) -> void:
	for c in cars:
		c.queue_free()
	cars.clear()
	score = [0, 0]
	time_left = 120.0
	overtime = false
	for t in 2:
		for i in m:
			var c = CarScript.new()
			c.team = t
			c.ball = ball
			c.is_bot = not (t == 0 and i == 0)
			if c.is_bot:
				c.col = Color("2f7bff") if t == 0 else Color("ff8a2b")
			else:
				c.col = Save.CARS[Save.car][1]
			c.spawn = Vector2((-1.0 if t == 0 else 1.0) * (550.0 + i * 260.0), 424.0)
			add_child(c)
			cars.append(c)
			if not c.is_bot:
				player = c
	reset_kickoff()
	state = COUNT
	count = 3.0

func reset_kickoff() -> void:
	ball.freeze = true
	ball.global_position = Vector2(0, -150)
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	for c in cars:
		c.reset_pos()

func to_menu() -> void:
	for c in cars:
		c.queue_free()
	cars.clear()
	player = null
	state = MENU
	Engine.time_scale = 1.0
	ball.freeze = true
	ball.global_position = Vector2(0, -150)

func goal(team: int) -> void:
	score[team] += 1
	last_scorer = team
	state = GOAL
	msg_t = 1.0
	Engine.time_scale = 0.4

func end_match() -> void:
	state = OVER
	Engine.time_scale = 1.0
	xp_gain = 50 + 25 * score[0] + (100 if score[0] > score[1] else 0)
	Save.add_xp(xp_gain)
	ball.freeze = true
	for c in cars:
		c.freeze = true

func _physics_process(delta: float) -> void:
	match state:
		COUNT:
			count -= delta
			if count <= 0.0:
				state = PLAY
				ball.freeze = false
				for c in cars:
					c.freeze = false
		PLAY:
			if not overtime:
				time_left -= delta
				if time_left <= 0.0:
					if score[0] == score[1]:
						overtime = true
					else:
						end_match()
						return
			var p := ball.global_position
			if p.y > GOAL_TOP:
				if p.x < -HW - 10.0:
					goal(1)
				elif p.x > HW + 10.0:
					goal(0)
		GOAL:
			msg_t -= delta
			if msg_t <= 0.0:
				Engine.time_scale = 1.0
				if overtime:
					end_match()
				else:
					reset_kickoff()
					state = COUNT
					count = 3.0

func _process(delta: float) -> void:
	if player and state != MENU:
		var pp: Vector2 = player.global_position
		var d := absf(pp.x - ball.global_position.x)
		var z := clampf(1600.0 / (d + 1000.0), 0.45, 0.75)
		var k := 1.0 - exp(-6.0 * delta)
		cam.global_position = cam.global_position.lerp((pp + ball.global_position) * 0.5, k)
		cam.zoom = cam.zoom.lerp(Vector2(z, z), k)
	else:
		cam.global_position = Vector2.ZERO
		cam.zoom = Vector2(0.5, 0.5)
