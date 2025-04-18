extends Node2D

var input_map = Image.load_from_file("res://assets/map/province_map.png")
var control

signal sendingMapColor(color:Color)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_input_map_color(position:Vector2) -> void: # called by control after signal from player node
	sendingMapColor.emit(input_map.get_pixel(position.x, position.y))
