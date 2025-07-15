extends CharacterBody2D

@export var max_health: int = 50
@export var attack_damage: int = 15
@export var enemy_name: String = "피존투"
@export var detection_range: int = 4  # 3 spaces detection range
@export var move_speed: float = 0.5

var health: int
var grid_pos: Vector2
var is_moving: bool = false

@onready var game_manager = get_node("../../GameManager")

func _ready():
	health = max_health
	name = enemy_name

func is_enemy() -> bool:
	return true

func take_turn():
	if is_moving:
		return
	
	# Check if player is within 3 spaces
	if not game_manager.is_player_in_range(grid_pos, detection_range):
		return  # Player is too far away, don't move
	
	# Get path to player (up to 3 steps)
	var path_to_player = game_manager.get_path_to_player(grid_pos)
	
	if path_to_player.size() > 0:
		var target_pos = path_to_player[0]  # Move one step toward player
		move_to_position(target_pos)
	else:
		# Try alternative movement if direct path is blocked
		try_alternative_movement()

func try_alternative_movement():
	"""Try to move in alternative directions if direct path is blocked"""
	var player_pos = game_manager.player.grid_pos
	var possible_moves = []
	
	# Check all 4 directions
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var new_pos = grid_pos + direction
		
		if game_manager.is_valid_position(new_pos) and not game_manager.is_position_occupied(new_pos):
			# Calculate distance to player from this position
			var distance_to_player = abs(new_pos.x - player_pos.x) + abs(new_pos.y - player_pos.y)
			possible_moves.append({
				"position": new_pos,
				"distance": distance_to_player
			})
	
	if possible_moves.size() > 0:
		# Sort by distance to player (closest first)
		possible_moves.sort_custom(func(a, b): return a.distance < b.distance)
		
		# Move to the closest position to player
		move_to_position(possible_moves[0].position)

func move_to_position(new_pos: Vector2):
	if is_moving:
		return
		
	is_moving = true
	var old_pos = grid_pos
	grid_pos = new_pos
	game_manager.move_character(self, old_pos, new_pos)
	
	# 부드러운 이동 애니메이션
	var target_world_pos = game_manager.grid_to_world(new_pos)
	var tween = create_tween()
	tween.tween_property(self, "position", target_world_pos, move_speed)
	await tween.finished
	
	is_moving = false
	
	# Check if we can attack player after moving
	check_for_player_attack()

func check_for_player_attack():
	"""Check if player is adjacent after moving and attack if possible"""
	var player_pos = game_manager.player.grid_pos
	var distance_to_player = abs(grid_pos.x - player_pos.x) + abs(grid_pos.y - player_pos.y)
	
	# If player is adjacent (distance 1), we could implement ranged attack
	if distance_to_player == 1:
		# For now, just print debug message
		print(name + " is adjacent to player!")
		# You could implement a ranged attack system here if needed

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

# Debug function to visualize detection range
func _draw():
	if Engine.is_editor_hint():
		var detection_color = Color.YELLOW
		detection_color.a = 0.3
		
		# Draw detection range squares
		for x in range(-detection_range, detection_range + 1):
			for y in range(-detection_range, detection_range + 1):
				if abs(x) + abs(y) <= detection_range:  # Manhattan distance
					var offset = Vector2(x * game_manager.cell_size, y * game_manager.cell_size)
					draw_rect(Rect2(offset - Vector2(game_manager.cell_size/2, game_manager.cell_size/2), 
									Vector2(game_manager.cell_size, game_manager.cell_size)), detection_color)

# Utility functions
func get_distance_to_player() -> int:
	"""Get Manhattan distance to player"""
	return int(game_manager.get_distance_to_player(grid_pos))

func is_player_in_detection_range() -> bool:
	"""Check if player is within detection range"""
	return game_manager.is_player_in_range(grid_pos, detection_range)

func can_see_player() -> bool:
	"""Check if enemy can see player (within detection range)"""
	return is_player_in_detection_range()

func get_direction_to_player() -> Vector2:
	"""Get direction vector to player"""
	var player_pos = game_manager.player.grid_pos
	var direction = Vector2.ZERO
	
	if abs(player_pos.x - grid_pos.x) > abs(player_pos.y - grid_pos.y):
		direction.x = sign(player_pos.x - grid_pos.x)
	else:
		direction.y = sign(player_pos.y - grid_pos.y)
	
	return direction
