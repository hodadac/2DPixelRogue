extends CharacterBody2D

@export var max_health: int = 50
@export var attack_damage: int = 15
@export var enemy_name: String = "피존투"

var health: int
var grid_pos: Vector2

@onready var game_manager = get_node("../../GameManager")

func _ready():
	health = max_health
	name = enemy_name

func is_enemy() -> bool:
	return true

func take_turn():
	# 간단한 AI: 플레이어 쪽으로 한 칸 이동 시도
	var player_pos = game_manager.player.grid_pos
	var direction = Vector2.ZERO
	
	if abs(player_pos.x - grid_pos.x) > abs(player_pos.y - grid_pos.y):
		direction.x = sign(player_pos.x - grid_pos.x)
	else:
		direction.y = sign(player_pos.y - grid_pos.y)
	
	var new_pos = grid_pos + direction
	
	if game_manager.is_valid_position(new_pos) and not game_manager.is_position_occupied(new_pos):
		move_to_position(new_pos)

func move_to_position(new_pos: Vector2):
	var old_pos = grid_pos
	grid_pos = new_pos
	game_manager.move_character(self, old_pos, new_pos)
	
	# 부드러운 이동
	var target_world_pos = game_manager.grid_to_world(new_pos)
	var tween = create_tween()
	tween.tween_property(self, "position", target_world_pos, 0.5)

func take_damage(amount: int):
	health -= amount
	health = max(0, health)
	
	if not is_alive():
		die()

func is_alive() -> bool:
	return health > 0

func die():
	game_manager.occupied_positions.erase(grid_pos)
	queue_free()
