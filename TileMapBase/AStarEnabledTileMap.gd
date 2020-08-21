extends TileMap
class_name AStarEnabledTileMap
const CLASS_NAME = 'AStarEnabledTileMap'

export(bool) var initialise_astar_on_ready = true

#Control the agent's movement options
#If false agents can move only up, down, left and right
#If true agents can move into any tile bordering the current tile
export(bool) var enable_eight_way_movement = false

#Control walkable tiles
export(Array) var walkable_tile_ids = []

#Control impassable tiles
export(Array) var impassable_tile_ids = []

#AStar2D node
var astar:AStar2D

#Dictionary of all point ids in astar by coordinate
#Key: Vector2 - coordinate on the tilemap
#Value: int - point id reference for astar
var astar_cells:Dictionary = {}

const SURROUNDING_CELLS:Array = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]

func _ready() -> void:
	if initialise_astar_on_ready: initialise_astar()


#Resets astar and astar_cells and recalculates the graph
func initialise_astar() -> void:
	astar_cells.clear()
	if !astar:
		astar = AStar2D.new()
	else:
		astar.clear()
	
	_load_and_connect_cells()


func get_astar_path(start:Vector2, end:Vector2, in_world_coordinates:bool = true) -> PoolVector2Array:
	if !astar_cells.has(start):
		print(CLASS_NAME + ": " + String(start) + " not found")
		return PoolVector2Array()
	if !astar_cells.has(end):
		print(CLASS_NAME + ": " + String(end) + " not found")
		return PoolVector2Array()
	
	var path:PoolVector2Array = astar.get_point_path(astar_cells[start], astar_cells[end])
	
	if in_world_coordinates:
		var world_coordinates_path:PoolVector2Array = PoolVector2Array()
		for cell in path:
			world_coordinates_path.append(convert_map_to_world(cell))
		return world_coordinates_path
	else: return path


#Takes all used cells and loads them into astar and connects them
func _load_and_connect_cells() -> void:
	for cell in get_used_cells():
		var cell_id:int = astar.get_available_point_id()
		astar.add_point(cell_id, cell)
		astar_cells[cell] = cell_id
	
	for cell in astar_cells:
		if enable_eight_way_movement:
			_connect_cell_eight_way(cell)
		else:
			_connect_cell_four_way(cell)

#Connects each cell to each other cell in each cardinal direction it that has a walkable tile id
func _connect_cell_four_way(cell:Vector2) -> void:
	if impassable_tile_ids.has(get_cellv(cell)): return
	for offset in SURROUNDING_CELLS:
		var possible_cell:Vector2 = cell + offset
		if astar_cells.has(possible_cell) and walkable_tile_ids.has(get_cellv(possible_cell)):
			astar.connect_points(astar_cells[cell], astar_cells[possible_cell])

#Connects each cell to each other cell surrounding it that has a walkable tile id
func _connect_cell_eight_way(cell:Vector2) -> void:
	if impassable_tile_ids.has(get_cellv(cell)): return
	for x in range(cell.x - 1, cell.x + 2):
		for y in range(cell.y - 1, cell.y +2):
			if Vector2(x,y) == cell: continue
			else:
				var possible_cell:Vector2 = Vector2(x,y)
				if astar_cells.has(possible_cell) and walkable_tile_ids.has(get_cellv(possible_cell)):
					astar.connect_points(astar_cells[cell], astar_cells[possible_cell])

#Converts a cell position into a global position adjusted for different cell modes
func convert_map_to_world(cell:Vector2) -> Vector2:
	match mode:
		MODE_SQUARE: 
			return map_to_world(cell) + cell_size/2
		MODE_ISOMETRIC: 
			return map_to_world(cell) + Vector2(0, cell_size.y/2)
		MODE_CUSTOM: 
			return map_to_world(cell)
		_:
			return map_to_world(cell)

#Gets the global position of the center of the cell at any given global position
func center_pos_on_neareast_cell(pos:Vector2) -> Vector2:
	return convert_map_to_world(world_to_map(pos))

#Gets the coordinates (map or global) for all cells accessible from any given cell
func get_connected_cells(cell:Vector2, in_world_coordinates:bool = true) -> PoolVector2Array:
	if !astar_cells.has(cell):
		print(CLASS_NAME + ": " + String(cell) + " not found")
		return PoolVector2Array()
	var connected_cells:PoolVector2Array = PoolVector2Array()
	var connected_points:PoolIntArray = astar.get_point_connections(astar_cells[cell])
	
	if in_world_coordinates:
		for point in connected_points:
			connected_cells.append(convert_map_to_world(astar.get_point_position(point)))
	else:
		for point in connected_points:
			connected_cells.append(astar.get_point_position(point))
	
	return connected_cells
