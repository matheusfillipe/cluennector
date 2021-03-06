extends Node2D

export var hover_border_color = Color(0.95, 0.1, 0, 1)
export var pressed_border_color = Color(0, 0.1, 0.95, 1)
export var pin_out = Vector2(-1, -5)
export var pin_in = Vector2(-2, -4)


var hover_scale = 1.3
var modulate_scale = Color(1.3, 1.3, 1.3, 1)
var border_width = 2.5
var transition_time = 0.5

var viewing = false
var is_hovered: bool = false
var mouse_pressed_inside = false
var has_mouse: bool = false
var has_drag_stared: bool = false

var description: String = ""
var title: String = ""
var size = Vector2.ONE * 5
var texture: Texture
var resource
var valid_next_list = []
var next = []
var pinned = false


var initial_scale = Vector2.ONE
onready var initial_modulate = modulate
onready var initial_rotation = rotation
onready var initial_position = global_position

onready var collision = $Area2D/CollisionShape2D
onready var mouse_area = $Area2D
onready var sprite = $Sprite
onready var timer = $Timer
onready var hover_tween = $HoverTween
onready var tween = $Tween
onready var pin = $Pin
onready var pintween = $pintween

signal hovered
signal mouse_entered
signal unhovered
signal drag_started
signal drag_stopped
signal clicked
signal right_clicked

func _ready():
	texture = resource.texture
	position = resource.pos
	description = resource.description
	if not description:
		description = "No description."
	title = resource.title
	valid_next_list = resource.next
	collision.shape.extents = size
	sprite.texture = texture
	sprite.scale = size / texture.get_size() * 2
	sprite.material.set_shader_param("color", hover_border_color)

## stores world scale, position and rotation
func init():
	initial_scale = scale
	initial_position = global_position
	initial_rotation = rotation
	initial_modulate = modulate

func add_pin():
	pin.visible = true
	pinned = true
	pintween.stop_all()
	pintween.interpolate_property(pin, "position",
			pin_out, pin_in, 0.1,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	pintween.start()

func remove_pin():
	pin.visible = true
	pinned = false
	pintween.stop_all()
	pintween.interpolate_property(pin, "position",
			pin_in, pin_out, 0.1,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	pintween.connect("tween_all_completed", self, "hide_pin")
	pintween.start()

func hide_pin():
	if pintween.is_connected("tween_all_completed", self, "hide_pin"):
		pintween.disconnect("tween_all_completed", self, "hide_pin")
	pin.visible = false


func diagonal_size():
	return (get_parent().get_parent().scale * size).length()

func get_title():
	return title if title else description

func stop_drag():
	has_drag_stared = false
	emit_signal("drag_stopped", self)
	sprite.material.set_shader_param("color", hover_border_color)
	is_hovered = has_mouse
	hover_animation()

func _input(event):
	if event is InputEventMouseMotion and mouse_pressed_inside:
		if has_drag_stared:
			return
		has_drag_stared = true
		emit_signal("drag_started", self)

func _process(_delta):
	if viewing:
		if has_drag_stared:
			stop_drag()
		has_drag_stared = false
	elif Input.is_action_just_pressed("mouse_left_click") and has_mouse:
		sprite.material.set_shader_param("color", pressed_border_color)
		mouse_pressed_inside = true
	elif Input.is_action_just_released("mouse_left_click") and has_mouse and not has_drag_stared and mouse_pressed_inside:
		sprite.material.set_shader_param("color", hover_border_color)
		if has_drag_stared:
			stop_drag()
		emit_signal("clicked", self)
	elif Input.is_action_just_released("mouse_left_click"):
		if has_drag_stared:
			stop_drag()
		mouse_pressed_inside = false
	elif Input.is_action_just_released("mouse_right_click") and has_mouse:
		emit_signal("right_clicked", self)

func click_animation(to_position: Vector2, to_scale: Vector2, to_rotation: float):
	viewing = true
	pin.visible = false
	is_hovered = false
	z_index = 1000
	if has_drag_stared:
		emit_signal("drag_stopped", self)

	hover_tween.stop_all()
	tween.stop_all()
	modulate = initial_modulate
	sprite.material.set_shader_param("border_width", 0.0)
	tween.interpolate_property(self, "scale",
			scale, to_scale, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(self, "global_position",
			global_position, to_position, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(self, "rotation",
			rotation, to_rotation, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(sprite.get_material(), "shader_param/border_width",
			sprite.material.get_shader_param("border_width"), 0.0, 0.15,
			hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)

	if tween.is_connected("tween_all_completed", self, "_on_Tween_tween_all_completed"):
		tween.disconnect("tween_all_completed", self, "_on_Tween_tween_all_completed")
	tween.connect("tween_all_completed", self, "_on_Tween_tween_all_completed", [true])
	tween.start()

func return_animation():
	tween.stop_all()
	tween.interpolate_property(self, "scale",
			scale, initial_scale, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(self, "global_position",
			global_position, initial_position, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(self, "rotation",
			rotation, initial_rotation, transition_time,
			tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	if tween.is_connected("tween_all_completed", self, "_on_Tween_tween_all_completed"):
		tween.disconnect("tween_all_completed", self, "_on_Tween_tween_all_completed")
	tween.connect("tween_all_completed", self, "_on_Tween_tween_all_completed", [false])
	tween.start()

func hover_animation():
	if viewing:
		return
	hover_tween.stop_all()
	if is_hovered:
		z_index = 10
		hover_tween.interpolate_property(self, "scale",
				scale, initial_scale * hover_scale, 0.1,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
		hover_tween.interpolate_property(self, "modulate",
				modulate, initial_modulate * modulate_scale, 0.1,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
		hover_tween.interpolate_property(sprite.get_material(), "shader_param/border_width",
				sprite.material.get_shader_param("border_width"), border_width, 0.1,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
	else:
		z_index = 0
		hover_tween.interpolate_property(self, "scale",
				scale, initial_scale, 0.5,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
		hover_tween.interpolate_property(self, "modulate",
				modulate, initial_modulate, 0.2,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
		hover_tween.interpolate_property(sprite.get_material(), "shader_param/border_width",
				sprite.material.get_shader_param("border_width"), 0.0, 0.15,
				hover_tween.TRANS_LINEAR, hover_tween.EASE_IN_OUT)
	hover_tween.start()

func _on_Area2D_mouse_entered():
	emit_signal("mouse_entered", self)
	has_mouse = true
	if is_hovered or viewing:
		return
	is_hovered = true
	timer.start()
	hover_animation()

func _on_Area2D_mouse_exited():
	has_mouse = false
	mouse_pressed_inside = false
	if not is_hovered or viewing or has_drag_stared:
		return
	is_hovered = false
	emit_signal("unhovered", self)
	sprite.material.set_shader_param("color", hover_border_color)
	hover_animation()

func _on_Timer_timeout():
	if is_hovered:
		hover_tween.stop_all()
		emit_signal("hovered", self)
		# Ensure because this scale hover_tween is not perfect
		scale = initial_scale * hover_scale
		modulate =  initial_modulate * modulate_scale
		sprite.material.set_shader_param("border_width", border_width)


func _on_Tween_tween_all_completed(is_showing=false):
	if tween.is_connected("tween_all_completed", self, "_on_Tween_tween_all_completed"):
		tween.disconnect("tween_all_completed", self, "_on_Tween_tween_all_completed")
	if is_showing:
		modulate = initial_modulate
		sprite.material.set_shader_param("border_width", 0.0)
	else:
		viewing = false
		is_hovered = false
		z_index = 0
		if pinned:
			pin.visible=true
