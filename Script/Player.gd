extends CharacterBody2D

signal battle_triggered(enemy)
signal moved

@export var max_health: int = 100
@export var attack_damage: int = 20
@export var move_speed: float = 5.0

var health: int
var grid_pos: Vector2
var is_defending: bool = false
var is_moving: bool = false

@onready var game_manager = $"../GameManager"

func _ready():
	health = max_health

func _input(event):
	if not is_moving and game_manager.current_state == game_manager.GameState.EXPLORATION:
		if event.is_action_pressed("ui_up"):
			try_move(Vector2.UP)
		elif event.is_action_pressed("ui_down"):
			try_move(Vector2.DOWN)
		elif event.is_action_pressed("ui_left"):
			try_move(Vector2.LEFT)
		elif event.is_action_pressed("ui_right"):
			try_move(Vector2.RIGHT)

func try_move(direction: Vector2):
	var new_pos = grid_pos + direction
	
	if not game_manager.is_valid_position(new_pos):
		return
	
	var occupant = game_manager.get_occupant(new_pos)
	if occupant:
		if occupant.has_method("is_enemy") and occupant.is_enemy():
			# 적과 조우 - 전투 시작
			battle_triggered.emit(occupant)
		return
	
	# 이동 실행
	move_to_position(new_pos)

func move_to_position(new_pos: Vector2):
	is_moving = true
	var old_pos = grid_pos
	grid_pos = new_pos
	
	game_manager.move_character(self, old_pos, new_pos)
	
	# 부드러운 이동 애니메이션
	var target_world_pos = game_manager.grid_to_world(new_pos)
	var tween = create_tween()
	tween.tween_property(self, "position", target_world_pos, 0.3)
	await tween.finished
	
	is_moving = false
	moved.emit()

func take_damage(amount: int):
	health -= amount
	health = max(0, health)

func is_alive() -> bool:
	return health > 0
