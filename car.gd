extends RigidBody2D

const ACCEL := 2600.0
const MAX_V := 850.0
const MAX_BOOST_V := 1350.0

var team := 0
var is_bot := false
var ball: RigidBody2D
var col := Color("2f7bff")
var spawn := Vector2.ZERO
var face := 1.0
var boost := 100.0
var boosting := false
var grounded := false
var normal := Vector2.UP
var jumps := 0
var air_time := 0.0
var flip_t := 0.0
var jump_was := false
var trail: Line2D

func _ready() -> void:
	mass = 1.0
	linear_damp = 0.1
	angular_damp = 2.0
	can_sleep = false
	collision_layer = 1
	collision_mask = 3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var m := PhysicsMaterial.new()
	m.friction = 0.0
	m.bounce = 0.1
	physics_material_override = m
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(120, 44)
	s.shape = r
	add_child(s)
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 16.0
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, 0.8))
	trail.gradient = g
	add_child(trail)

func reset_pos() -> void:
	freeze = true
	global_position = spawn
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	boost = 100.0
	jumps = 0
	flip_t = 0.0
	face = 1.0 if team == 0 else -1.0
	trail.clear_points()

func get_input() -> Dictionary:
	if is_bot:
		return bot_input()
	return {
		"dir": Input.get_axis("left", "right"),
		"jump": Input.is_action_pressed("jump"),
		"boost": Input.is_action_pressed("boost"),
	}

func bot_input() -> Dictionary:
	var atk := 1.0 if team == 0 else -1.0
	var rel := (ball.global_position.x - global_position.x) * atk
	var dist := ball.global_position.distance_to(global_position)
	var d := -atk
	var jump := false
	var bst := false
	if rel > 40.0:
		d = atk
		bst = dist > 500.0 and boost > 30.0
		if dist < 200.0 and randf() < 0.2:
			jump = ball.global_position.y < global_position.y - 30.0 or jumps == 1
	else:
		bst = boost > 60.0 and rel < -250.0
	return {"dir": d, "jump": jump, "boost": bst}

func _physics_process(delta: float) -> void:
	if freeze:
		return
	var inp := get_input()
	var dir: float = inp.dir
	var down := Vector2.DOWN.rotated(rotation)
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + down * 46.0, 2, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	grounded = not hit.is_empty() and linear_velocity.dot(hit.normal) < 200.0
	flip_t = maxf(0.0, flip_t - delta)

	if grounded:
		normal = hit.normal
		jumps = 0
		air_time = 0.0
		if dir != 0.0:
			face = signf(dir)
		var tangent := Vector2(-normal.y, normal.x)
		var vt := linear_velocity.dot(tangent)
		apply_central_force(-normal * 2500.0)
		var cap := MAX_BOOST_V if (inp.boost and boost > 1.0) else MAX_V
		if dir != 0.0 and vt * dir < cap:
			apply_central_force(tangent * dir * ACCEL)
		apply_central_force(-tangent * vt * (0.6 if dir != 0.0 else 4.0))
		angular_velocity = angle_difference(rotation, normal.angle() + PI / 2.0) * 12.0
	else:
		air_time += delta
		if jumps == 0 and air_time > 0.12:
			jumps = 1
		if flip_t <= 0.0:
			if dir != 0.0:
				apply_torque(dir * 90000.0)
			angular_velocity = clampf(angular_velocity, -8.0, 8.0)

	var jp: bool = inp.jump
	if jp and not jump_was:
		if grounded:
			apply_central_impulse(normal * 800.0)
			jumps = 1
		elif jumps == 1:
			jumps = 2
			flip_t = 0.35
			if dir != 0.0:
				apply_central_impulse(Vector2(dir, 0.0) * 550.0)
				angular_velocity = dir * 14.0
			else:
				apply_central_impulse(Vector2.UP * 450.0)
	jump_was = jp

	boosting = inp.boost and boost > 1.0
	if boosting:
		boost -= 33.0 * delta
		apply_central_force(Vector2(face, 0.0).rotated(rotation) * 4200.0)
		trail.add_point(global_position - Vector2(face * 55.0, 0.0).rotated(rotation))
	else:
		boost = minf(100.0, boost + 14.0 * delta)
		if trail.get_point_count() > 0:
			trail.remove_point(0)
	while trail.get_point_count() > 24:
		trail.remove_point(0)
	if linear_velocity.length() > MAX_BOOST_V:
		linear_velocity = linear_velocity.limit_length(MAX_BOOST_V)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
	var body := PackedVector2Array([
		Vector2(-60, 8), Vector2(-60, -8), Vector2(-34, -12), Vector2(-14, -26),
		Vector2(26, -26), Vector2(44, -10), Vector2(60, -6), Vector2(60, 8), Vector2(-60, 8)])
	if boosting:
		var l := randf_range(50.0, 95.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-60, -4), Vector2(-60 - l, 2), Vector2(-60, 8)]), Color("ff9a2e"))
		draw_colored_polygon(PackedVector2Array([Vector2(-60, -1), Vector2(-60 - l * 0.55, 2), Vector2(-60, 5)]), Color("fff2a0"))
	draw_polyline(body, Color(col, 0.3), 10.0)
	draw_colored_polygon(body, col)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -22), Vector2(22, -22), Vector2(38, -10), Vector2(-14, -10)]), Color(0.08, 0.12, 0.25, 0.92))
	draw_polyline(body, Color.WHITE, 2.0)
	for x in [-38.0, 38.0]:
		draw_circle(Vector2(x, 9), 13.0, Color("14141e"))
		draw_circle(Vector2(x, 9), 6.0, Color("9aa3c7"))
