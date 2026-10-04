extends Control

var game
var held := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	queue_redraw()

func _rects() -> Dictionary:
	var s := size
	return {
		"left": Rect2(30, s.y - 180, 140, 140),
		"right": Rect2(190, s.y - 180, 140, 140),
		"boost": Rect2(s.x - 330, s.y - 170, 130, 130),
		"jump": Rect2(s.x - 180, s.y - 190, 150, 150),
	}

func _hit(p: Vector2) -> String:
	var r := _rects()
	for k in r:
		if r[k].grow(20).has_point(p):
			return k
	return ""

func _release(i: int) -> void:
	if held.has(i):
		Input.action_release(held[i])
		held.erase(i)

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		_release(e.index)
		if e.pressed:
			var a := _hit(e.position)
			if a != "":
				held[e.index] = a
				Input.action_press(a)
	elif e is InputEventScreenDrag:
		var b := _hit(e.position)
		if held.get(e.index, "") != b:
			_release(e.index)
			if b != "":
				held[e.index] = b
				Input.action_press(b)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_click(e.position)

func _click(p: Vector2) -> void:
	var c := size / 2.0
	if game.state == game.MENU:
		if Rect2(c.x - 300, c.y - 40, 280, 90).has_point(p):
			game.start_match(1)
		elif Rect2(c.x + 20, c.y - 40, 280, 90).has_point(p):
			game.start_match(2)
		elif Rect2(c.x - 140, c.y + 80, 280, 80).has_point(p):
			Save.next_car()
	elif game.state == game.OVER:
		game.to_menu()

func _text(t: String, pos: Vector2, sz: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - 400.0, pos.y), t, HORIZONTAL_ALIGNMENT_CENTER, 800.0, sz, col)

func _btn(rc: Rect2, t: String, col: Color) -> void:
	draw_rect(rc, Color(col, 0.35))
	draw_rect(rc, col, false, 4.0)
	_text(t, Vector2(rc.get_center().x, rc.get_center().y + 12.0), 36, Color.WHITE)

func _tri(rc: Rect2, d: float) -> void:
	var m := rc.get_center()
	draw_colored_polygon(PackedVector2Array([
		m + Vector2(-30.0 * d, 0), m + Vector2(25.0 * d, -40), m + Vector2(25.0 * d, 40)]), Color(1, 1, 1, 0.8))

func _draw() -> void:
	var c := size / 2.0
	var st: int = game.state
	if st == game.MENU:
		_text("SIDESWIPE CLONE", Vector2(c.x, c.y - 140), 64, Color.WHITE)
		_btn(Rect2(c.x - 300, c.y - 40, 280, 90), "1 v 1", Color("2f7bff"))
		_btn(Rect2(c.x + 20, c.y - 40, 280, 90), "2 v 2", Color("ff8a2b"))
		var car: Array = Save.CARS[Save.car]
		_btn(Rect2(c.x - 140, c.y + 80, 280, 80), "Voiture : " + car[0], car[1])
		_text("Niveau %d  -  %d/%d XP" % [Save.level, Save.xp % Save.XP_PER_LEVEL, Save.XP_PER_LEVEL], Vector2(c.x, c.y + 210), 28, Color("c8d0ff"))
		return

	var tt := "PROLONGATION" if game.overtime else "%d:%02d" % [int(game.time_left) / 60, int(game.time_left) % 60]
	_text(str(game.score[0]), Vector2(c.x - 180, 70), 64, Color("2f7bff"))
	_text(str(game.score[1]), Vector2(c.x + 180, 70), 64, Color("ff8a2b"))
	_text(tt, Vector2(c.x, 55), 36, Color.WHITE)

	if st != game.OVER:
		var r := _rects()
		for k in r:
			var on := Input.is_action_pressed(k)
			draw_rect(r[k], Color(1, 1, 1, 0.28 if on else 0.12))
			draw_rect(r[k], Color(1, 1, 1, 0.5), false, 3.0)
		_tri(r["left"], -1.0)
		_tri(r["right"], 1.0)
		_text("SAUT", Vector2(r["jump"].get_center().x, r["jump"].get_center().y + 10), 34, Color.WHITE)
		_text("BOOST", Vector2(r["boost"].get_center().x, r["boost"].get_center().y + 10), 28, Color("ffb347"))
		if game.player:
			var rb: Rect2 = r["boost"]
			draw_rect(Rect2(rb.position.x, rb.position.y - 18, rb.size.x, 10), Color(1, 1, 1, 0.15))
			draw_rect(Rect2(rb.position.x, rb.position.y - 18, rb.size.x * game.player.boost / 100.0, 10), Color("ffb347"))

	if st == game.COUNT:
		_text(str(ceili(game.count)), Vector2(c.x, c.y + 40), 140, Color.WHITE)
	elif st == game.GOAL:
		_text("BUT !", Vector2(c.x, c.y), 120, Color("2f7bff") if game.last_scorer == 0 else Color("ff8a2b"))
	elif st == game.OVER:
		var a: int = game.score[0]
		var b: int = game.score[1]
		_text("VICTOIRE !" if a > b else ("DÉFAITE" if a < b else "ÉGALITÉ"), Vector2(c.x, c.y - 40), 110, Color.WHITE)
		_text("+%d XP   (niveau %d)" % [game.xp_gain, Save.level], Vector2(c.x, c.y + 40), 40, Color("ffd34d"))
		_text("Touche l'écran pour continuer", Vector2(c.x, c.y + 110), 30, Color("c8d0ff"))
