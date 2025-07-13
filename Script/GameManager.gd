extends Node

enum GameState { EXPLORATION, BATTLE, GAME_OVER }
enum TurnState { PLAYER_TURN, ENEMY_TURN }

@export var grid_size: int = 10
@export var cell_size: int = 64

var current_state: GameState = GameState.EXPLORATION
var turn_state: TurnState = TurnState.PLAYER_TURN
var grid_positions: Array = []
var occupied_positions: Dictionary = {}

@onready var player = $"../Player"
@onready var enemies_node = $"../Enemies"
@onready var ui = $"../UI/GameUI"
@onready var battle_ui = $"../UI/GameUI/BattleUI"
@onready var battle_log = $"../UI/GameUI/BattleUI/BattleLog"

var current_enemy: CharacterBody2D = null

func _ready():
	initialize_grid()
	setup_initial_positions()
	update_ui()
	battle_ui.visible = false
	
	# 신호 연결
	player.battle_triggered.connect(_on_battle_triggered)
	player.moved.connect(_on_player_moved)

func initialize_grid():
	# 그리드 좌표 초기화 (0,0 ~ 3,3)
	for x in range(grid_size):
		for y in range(grid_size):
			grid_positions.append(Vector2(x, y))

func setup_initial_positions():
	# 플레이어 시작 위치 (0,0)
	player.grid_pos = Vector2(0, 0)
	player.position = grid_to_world(Vector2(0, 0))
	occupied_positions[Vector2(0, 0)] = player
	
	# 적 배치
	var enemies = enemies_node.get_children()
	if enemies.size() > 0:
		enemies[0].grid_pos = Vector2(2, 1)
		enemies[0].position = grid_to_world(Vector2(2, 1))
		occupied_positions[Vector2(2, 1)] = enemies[0]
	
	if enemies.size() > 1:
		enemies[1].grid_pos = Vector2(3, 3)
		enemies[1].position = grid_to_world(Vector2(3, 3))
		occupied_positions[Vector2(3, 3)] = enemies[1]

func grid_to_world(grid_pos: Vector2) -> Vector2:
	return Vector2(grid_pos.x * cell_size + cell_size/2, grid_pos.y * cell_size + cell_size/2)

func world_to_grid(world_pos: Vector2) -> Vector2:
	return Vector2(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

func is_valid_position(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size and grid_pos.y >= 0 and grid_pos.y < grid_size

func is_position_occupied(grid_pos: Vector2) -> bool:
	return occupied_positions.has(grid_pos)

func get_occupant(grid_pos: Vector2):
	return occupied_positions.get(grid_pos, null)

func move_character(character, old_pos: Vector2, new_pos: Vector2):
	occupied_positions.erase(old_pos)
	occupied_positions[new_pos] = character

func _on_battle_triggered(enemy):
	current_state = GameState.BATTLE
	
	current_enemy = enemy
	battle_ui.visible = true
	
	add_battle_log("전투 시작! " + enemy.name + "과 마주쳤다!")
	update_ui()

func _on_player_moved():
	if current_state == GameState.EXPLORATION:
		# 적 턴 진행
		process_enemy_turns()
	update_ui()

func process_enemy_turns():
	for enemy in enemies_node.get_children():
		if enemy.is_alive():
			enemy.take_turn()

func add_battle_log(text: String):
	if battle_log:
		battle_log.append_text(text + "\n")

func update_ui():
	var hp_label = $"../UI/GameUI/PlayerStats/HPLabel"
	var turn_label = $"../UI/GameUI/PlayerStats/TurnLabel"
	
	if hp_label:
		hp_label.text = "HP: " + str(player.health) + "/" + str(player.max_health)
	
	if turn_label:
		var state_text = "탐험" if current_state == GameState.EXPLORATION else "전투"
		turn_label.text = "상태: " + state_text

func _on_attack_button_pressed():
	if current_state == GameState.BATTLE and current_enemy:
		print("on battel - attack")
		player_attack()

func _on_defend_button_pressed():
	if current_state == GameState.BATTLE:
		print("on battle - defend")
		player_defend()

func player_attack():
	var damage = player.attack_damage + randi() % 5
	current_enemy.take_damage(damage)
	add_battle_log("플레이어가 " + str(damage) + " 데미지를 입혔다!")
	
	if not current_enemy.is_alive():
		add_battle_log(current_enemy.name + "을 처치했다!")
		end_battle()
	else:
		enemy_attack()

func player_defend():
	add_battle_log("플레이어가 방어 자세를 취했다!")
	# 방어 효과 적용 (다음 공격 데미지 감소)
	player.is_defending = true
	enemy_attack()

func enemy_attack():
	if current_enemy and current_enemy.is_alive():
		var damage = current_enemy.attack_damage + randi() % 3
		if player.is_defending:
			damage = damage / 2
			player.is_defending = false
			add_battle_log("방어로 데미지를 절반으로 줄였다!")
		
		player.take_damage(damage)
		add_battle_log(current_enemy.name + "이 " + str(damage) + " 데미지를 입혔다!")
		
		if not player.is_alive():
			add_battle_log("플레이어가 쓰러졌다!")
			current_state = GameState.GAME_OVER

func end_battle():
	current_state = GameState.EXPLORATION
	battle_ui.visible = false
	current_enemy = null
	update_ui()
