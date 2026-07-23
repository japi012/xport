extends AnimatableBody2D
class_name Spring

## Spring object

## The amount of time it takes to coil
var coil_duration: float = 1000

## The initial height of the spring
var initial_height = 1

## The height when it's fully coiled
var coil_height = 0.5

func _ready():
	get_parent().level_start.connect(_on_level_start)
	initial_height = scale.y

func _on_level_start():
	var tween = create_tween()
	tween.tween_method(tween_spring, 0.0, 1.0, coil_duration / 1000)
	
	var unspring = create_tween()
	unspring.tween_callback(tween_unspring).set_delay(coil_duration / 1000)

func tween_spring(value: float):
	#scale.y = (1 - value) * (initial_height / coil_height) * coil_height
	pass

func tween_unspring():
	#scale.y = initial_height
	pass
