extends Node
# Autoload "Save" : XP, niveau de compte, voiture choisie

const PATH := "user://save.cfg"
const XP_PER_LEVEL := 200
# [nom, couleur, niveau requis]
const CARS := [
	["Bleu", Color("2f7bff"), 1],
	["Rouge", Color("ff3b3b"), 2],
	["Vert", Color("2fe08a"), 4],
	["Violet", Color("a64dff"), 6],
	["Or", Color("ffc933"), 9],
	["Rose", Color("ff5fb4"), 12],
]

var xp := 0
var level := 1
var car := 0

func _ready() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) == OK:
		xp = c.get_value("p", "xp", 0)
		car = c.get_value("p", "car", 0)
	level = 1 + xp / XP_PER_LEVEL

func add_xp(n: int) -> void:
	xp += n
	level = 1 + xp / XP_PER_LEVEL
	save()

func unlocked(i: int) -> bool:
	return level >= CARS[i][2]

func next_car() -> void:
	for i in CARS.size():
		var j := (car + 1 + i) % CARS.size()
		if unlocked(j):
			car = j
			break
	save()

func save() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "xp", xp)
	c.set_value("p", "car", car)
	c.save(PATH)
