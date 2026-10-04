extends RigidBody2D

const R := 46.0
const MAX_V := 2200.0

func _ready() -> void:
	mass = 0.6
	gravity_scale = 0.75
	linear_damp = 0.08
	angular_damp = 0.4
	can_sleep = false
	collision_layer = 1
	collision_mask = 3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var m := PhysicsMaterial.new()
	m.bounce = 0.65
	m.friction = 0.3
	physics_material_override = m
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = R
	s.shape = c
	add_child(s)

func _physics_process(_d: float) -> void:
	if linear_velocity.length() > MAX_V:
		linear_velocity = linear_velocity.normalized() * MAX_V

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var v := minf(linear_velocity.length() / 1500.0, 1.0)
	draw_circle(Vector2.ZERO, R + 12.0, Color(0.5, 0.7, 1.0, 0.10 + 0.2 * v))
	draw_circle(Vector2.ZERO, R, Color("f4f6ff"))
	draw_arc(Vector2.ZERO, R - 8.0, 0.0, TAU, 32, Color("6f86ff"), 3.0)
	for i in 5:
		draw_line(Vector2.ZERO, Vector2.from_angle(i * TAU / 5.0) * (R - 8.0), Color("6f86ff"), 3.0)
