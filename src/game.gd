extends Node2D
class_name Game

## The gameplay scene

## The node that contains all of the objects
var objects_node: Node2D

## Whether or not the simulation is paused
var is_paused: bool

## Whether or not the level has started
var level_started: bool = false

func _ready() -> void:
	objects_node = get_tree().get_first_node_in_group("Objects")
	PhysicsServer2D.set_active(false)
	is_paused = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_play"):
		PhysicsServer2D.set_active(is_paused)
		is_paused = not is_paused
		
		if not level_started:
			level_started = true
			for object in objects_node.get_children():
				object.level_start.emit()
