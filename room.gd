extends Node2D

@export var _door_scene: PackedScene

func add_door(direction: int) -> void:
	var door: Sprite2D = _door_scene.instantiate()
	add_child(door)
	door.position = Vector2(64, 0).rotated(-PI * direction / 2.0)
	door.rotation = -PI * direction / 2.0

func clear_doors() -> void:
	for child in get_children():
		if not child.name.begins_with("F") and not child.name.begins_with("I"):
			child.queue_free()

func set_icon(icon: Texture2D, color) -> void:
	self.texture = icon
	self.modulate = color
