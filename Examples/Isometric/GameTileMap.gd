extends AStarEnabledTileMap

func _ready() -> void:
	$YSort/Start.global_position = convert_map_to_world(Vector2(0,0))
	$YSort/End.global_position = convert_map_to_world(Vector2(5,-5))
	_draw_path()
	

func _unhandled_input(event):
	if event.is_action_pressed("left_click"):
		$YSort/Start.global_position = center_pos_on_neareast_cell(get_global_mouse_position())
		_draw_path()
	if event.is_action_pressed('right_click'):
		$YSort/End.global_position = center_pos_on_neareast_cell(get_global_mouse_position())
		_draw_path()
	if event.is_action_pressed("ui_select"):
		$Line2D.points = get_connected_cells(world_to_map($YSort/Start.global_position))


func _draw_path() -> void:
	var path = get_astar_path(world_to_map($YSort/Start.global_position), world_to_map($YSort/End.global_position))
	$Line2D.points = path


func toggle_eight_way_movement(button_pressed):
	enable_eight_way_movement = button_pressed
	initialise_astar()
	_draw_path()
