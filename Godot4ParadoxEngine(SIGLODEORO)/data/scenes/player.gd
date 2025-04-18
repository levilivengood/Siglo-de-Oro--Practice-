extends Node2D

var speed = 16
@onready var camera = $Camera2D
var zoom_max = Vector2(0.25, 0.25)
var zoom_min = Vector2(6, 6)

signal seekingMapColor(position:Vector2)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_up"): 
		position += Vector2(0,-1) * speed / camera.zoom.x
	if Input.is_action_pressed("ui_down"): 
		position += Vector2(0, 1) * speed / camera.zoom.x
	if Input.is_action_pressed("ui_left"): 
		position += Vector2(-1, 0) * speed / camera.zoom.x
	if Input.is_action_pressed("ui_right"): 
		position += Vector2(1, 0) * speed / camera.zoom.x

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			seekingMapColor.emit(get_global_mouse_position())
			#print("PLAYER: mouse clicked at ", get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(Vector2(0.5, 0.5))
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(Vector2(-0.5, -0.5))

func _zoom_camera(amount:Vector2) -> void:
#	print("CAMERA: zoom before:", camera.zoom)
	var new_zoom = clamp(camera.zoom + amount, zoom_max, zoom_min)
	camera.zoom = new_zoom
#	print("CAMERA: zoom after:", camera.zoom)
