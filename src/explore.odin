package main

is_in_bounds :: proc(pos: Vec2, max: int = ROOM_SIZE) -> bool {
	return pos.x < max && pos.y < max && pos.x >= 0 && pos.y >= 0
}

get_door_direction :: proc(pos: Vec2) -> Maybe(Direction) {
	if pos.y == 0 && (pos.x == ROOM_CENTRE - 1 || pos.x == ROOM_CENTRE) do return .UP
	if pos.y == ROOM_SIZE - 1 && (pos.x == ROOM_CENTRE - 1 || pos.x == ROOM_CENTRE) do return .DOWN
	if pos.x == 0 && (pos.y == ROOM_CENTRE - 1 || pos.y == ROOM_CENTRE) do return .LEFT
	if pos.x == ROOM_SIZE - 1 && (pos.y == ROOM_CENTRE - 1 || pos.y == ROOM_CENTRE) do return .RIGHT
	return nil
}

unlock_door_connection :: proc(direction: Direction) {
	current_door_key := [3]int{game.room_coords.x, game.room_coords.y, int(direction)}
	game.unlocked_doors[current_door_key] = true

	switch direction {
	case .UP:
		world_set({ROOM_CENTRE - 1, 0}, .GRASS)
		world_set({ROOM_CENTRE, 0}, .GRASS)

		if game.room_coords.y > 0 {
			neighbor_door_key := [3]int {
				game.room_coords.x,
				game.room_coords.y - 1,
				int(Direction.DOWN),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y - 1][game.room_coords.x]
			neighbor_room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
			neighbor_room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
		}
	case .DOWN:
		world_set({ROOM_CENTRE - 1, ROOM_SIZE - 1}, .GRASS)
		world_set({ROOM_CENTRE, ROOM_SIZE - 1}, .GRASS)

		if game.room_coords.y < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]int {
				game.room_coords.x,
				game.room_coords.y + 1,
				int(Direction.UP),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y + 1][game.room_coords.x]
			neighbor_room.tiles[0][ROOM_CENTRE - 1] = .GRASS
			neighbor_room.tiles[0][ROOM_CENTRE] = .GRASS
		}
	case .LEFT:
		world_set({0, ROOM_CENTRE - 1}, .GRASS)
		world_set({0, ROOM_CENTRE}, .GRASS)

		if game.room_coords.x > 0 {
			neighbor_door_key := [3]int {
				game.room_coords.x - 1,
				game.room_coords.y,
				int(Direction.RIGHT),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y][game.room_coords.x - 1]
			neighbor_room.tiles[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
			neighbor_room.tiles[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
		}
	case .RIGHT:
		world_set({ROOM_SIZE - 1, ROOM_CENTRE - 1}, .GRASS)
		world_set({ROOM_SIZE - 1, ROOM_CENTRE}, .GRASS)

		if game.room_coords.x < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]int {
				game.room_coords.x + 1,
				game.room_coords.y,
				int(Direction.LEFT),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y][game.room_coords.x + 1]
			neighbor_room.tiles[ROOM_CENTRE - 1][0] = .GRASS
			neighbor_room.tiles[ROOM_CENTRE][0] = .GRASS
		}
	}
}
