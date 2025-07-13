extends Node2D

@export var grid_size: int = 10
@export var cell_size: int = 64
@export var line_color: Color = Color.GRAY
@export var line_width: float = 2.0

func _ready():
	queue_redraw()

func _draw():
	# 그리드 라인 그리기
	for i in range(grid_size + 1):
		# 세로 라인
		var start_v = Vector2(i * cell_size, 0)
		var end_v = Vector2(i * cell_size, grid_size * cell_size)
		draw_line(start_v, end_v, line_color, line_width)
		
		# 가로 라인
		var start_h = Vector2(0, i * cell_size)
		var end_h = Vector2(grid_size * cell_size, i * cell_size)
		draw_line(start_h, end_h, line_color, line_width)
