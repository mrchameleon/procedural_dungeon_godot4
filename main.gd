extends Node2D
#https://www.youtube.com/watch?v=-g1eTeq4JYI

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i(0, 1),
	Vector2i.LEFT,
	Vector2i(0, -1)
]

enum Doors
{
	RIGHT = 1,
	UP = 2,
	LEFT = 4,
	DOWN = 8
}

enum Contents
{
	EMPTY = 0,
	ENTRANCE = 16,
	STAIRS = 32,
	ENEMY = 64,
	TREASURE = 128,
	MERCHANT = 256,
	CAMP = 512,
	BOSS = 1024,
	RANDOM = 2048
}

const BOTTOM_LEFT_CORNER: Vector2 = Vector2(320, 896)
const ROOM_SIZE: Vector2 = Vector2(160, 160)

@export var _dimensions: Vector2i = Vector2i(7, 5)
@export var _start: Vector2i = Vector2i(-1, 0)
@export var _critical_path_length: int = 13
@export var _branches: Array[Contents] = []
@export var _branch_length : Vector2i = Vector2i(1, 4)
@export var _room_scene : PackedScene
@export var _room_icons : Array[Texture2D]
var _branch_candidates : Array[Vector2i]
var dungeon : Array

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		_clear_dungeon()
		_generate_dungeon()

func _clear_dungeon() -> void:
	dungeon.clear()
	_branch_candidates.clear()
	for child in get_children():
		child.queue_free()

func _generate_dungeon() -> void:
	_initialize_dungeon()
	_place_entrance()
	_generate_path(_start, _critical_path_length, [Contents.CAMP, Contents.BOSS, Contents.STAIRS])
	_generate_branches()
	_print_dungeon()
	_draw_dungeon()

func _initialize_dungeon() -> void:
	if _start.x < 0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x - 1)
	if _start.y < 0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y - 1)
	for x in _dimensions.x:
		dungeon.append([])
		for y in _dimensions.y:
			dungeon[x].append(Contents.EMPTY)

func _place_entrance() -> void:
	dungeon[_start.x][_start.y] |= Contents.ENTRANCE

func _generate_path(from: Vector2i, length: int, end_of_path: Array[int]) -> bool:
	if length == 0:
		return true
	var current: Vector2i = from
	var random: int = randi_range(0, 3)
	var direction: Vector2i = DIRECTIONS[random]
	for i in 4:
		if (current.x + direction.x >= 0 and current.x + direction.x < _dimensions.x and
			current.y + direction.y >= 0 and current.y + direction.y < _dimensions.y and
			not dungeon[current.x + direction.x][current.y + direction.y]):
			dungeon[current.x][current.y] |= Doors.values()[random]
			current += direction
			dungeon[current.x][current.y] |= Doors.values()[(random + 2) % 4]
			if length <= end_of_path.size():
				dungeon[current.x][current.y] |= end_of_path[end_of_path.size() - length]
			else:
				_branch_candidates.append(current)
				match randi_range(0, 2):
					1:
						dungeon[current.x][current.y] |= Contents.ENEMY
					2:
						dungeon[current.x][current.y] |= Contents.RANDOM
			if _generate_path(current, length - 1, end_of_path):
				return true
			else:
				_branch_candidates.erase(current)
				dungeon[current.x][current.y] = Contents.EMPTY
				current -= direction
				dungeon[current.x][current.y] &= ~Doors.values()[random]
		random += 1
		random %= 4
		direction = DIRECTIONS[random]
	return false

func _generate_branches() -> void:
	var branches_created : int = 0
	var candidate : Vector2i
	while branches_created < _branches.size() and _branch_candidates.size():
		candidate = _branch_candidates[randi_range(0, _branch_candidates.size() - 1)]
		if _generate_path(candidate, randi_range(_branch_length.x, _branch_length.y), [_branches[branches_created]]):
			branches_created += 1
		else:
			_branch_candidates.erase(candidate)

func _print_dungeon() -> void:
	var dungeon_as_string : String = ""
	for y in range(_dimensions.y - 1, -1, -1):
		for x in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += '\n'
	#print(dungeon_as_string)


func _draw_dungeon() -> void:
	var room : Node2D
	for y in range(_dimensions.y - 1, -1, -1):
		for x in _dimensions.x:
			if dungeon[x][y]:
				room = _room_scene.instantiate()
				add_child(room)
				room.position = BOTTOM_LEFT_CORNER + Vector2(x, -y) * ROOM_SIZE
				for i in Doors.size():
					if dungeon[x][y] & Doors.values()[i]:
						room.add_door(i)
				for i in _room_icons.size():
					if dungeon[x][y] & Contents.values()[i]:
						var colors: Array = [
							Color(1.0, 0.0, 0.0),    # Red / ENTRANCE
							Color(0.0, 0.6, 1.0),    # Blue / STAIRS
							Color(0.0, 0.8, 0.2),    # Green / ENEMY
							Color(1.0, 0.5, 0.0),    # Orange / TREASURE
							Color(0.6, 0.0, 1.0),    # Purple / MERCHANT
							Color(1.0, 1.0, 0.0),    # Yellow / CAMP
							Color(0.0, 0.9, 0.8),    # Cyan / BOSS
							Color(1.0, 0.0, 1.0)     # Magenta / RANDOM
						]
						var color = colors[i-1]
						room.set_icon(_room_icons[i], color)
						break
