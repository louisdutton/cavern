package main

import "core:math/rand"

FLOOR_SIZE :: 5 // equalateral length of a floor
ROOM_COUNT :: FLOOR_SIZE * FLOOR_SIZE // max rooms in a floor
ROOM_SIZE :: 16 // equalateral length of a room in tiles
ROOM_CENTRE :: ROOM_SIZE / 2 // the centerpoint of a room
TILE_COUNT :: ROOM_SIZE * ROOM_SIZE // number of tiles in a room

Vec2 :: [2]i32

generate_floor :: proc() {
	visited := [FLOOR_SIZE][FLOOR_SIZE]bool{}
	stack := [dynamic]Vec2{}
	defer delete(stack)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			game.floor_layout[y][x] = Room {
				id = i32(y * FLOOR_SIZE + x),
				x  = i32(x),
				y  = i32(y),
			}
		}
	}

	start_x, start_y: i32
	end_x, end_y: i32

	if game.floor_number == 1 {
		title_x: i32 = 1
		title_y: i32 = 1
		options_x: i32 = 2
		options_y: i32 = 1
		start_x = title_x
		start_y = title_y + 1

		game.floor_layout[title_y][title_x].connections[.SOUTH] = true
		game.floor_layout[title_y][title_x].connections[.EAST] = true
		game.floor_layout[options_y][options_x].connections[.WEST] = true
		game.floor_layout[start_y][start_x].connections[.NORTH] = true
	} else {
		start_x = rand.int31() % FLOOR_SIZE
		start_y = rand.int31() % FLOOR_SIZE
	}

	current_x, current_y := start_x, start_y
	visited[current_y][current_x] = true
	if game.floor_number == 1 {
		visited[1][1] = true
		visited[1][2] = true
	}
	append(&stack, Vec2{current_x, current_y})

	for len(stack) > 0 {
		neighbors := [dynamic][3]i32{}
		defer delete(neighbors)

		if current_x > 0 && !visited[current_y][current_x - 1] {
			append(&neighbors, [3]i32{current_x - 1, current_y, i32(Direction.WEST)})
		}
		if current_x < FLOOR_SIZE - 1 && !visited[current_y][current_x + 1] {
			append(&neighbors, [3]i32{current_x + 1, current_y, i32(Direction.EAST)})
		}
		if current_y > 0 && !visited[current_y - 1][current_x] {
			append(&neighbors, [3]i32{current_x, current_y - 1, i32(Direction.NORTH)})
		}
		if current_y < FLOOR_SIZE - 1 && !visited[current_y + 1][current_x] {
			append(&neighbors, [3]i32{current_x, current_y + 1, i32(Direction.SOUTH)})
		}

		if len(neighbors) == 0 {
			if len(stack) > 1 {
				ordered_remove(&stack, len(stack) - 1)
				current_x, current_y = stack[len(stack) - 1].x, stack[len(stack) - 1].y
			} else {
				break
			}

			continue
		}

		chosen := rand.choice(neighbors[:])
		next_x, next_y, direction := chosen.x, chosen.y, Direction(chosen.z)

		opposite_direction: Direction
		switch direction {
		case .NORTH: opposite_direction = .SOUTH
		case .SOUTH: opposite_direction = .NORTH
		case .EAST: opposite_direction = .WEST
		case .WEST: opposite_direction = .EAST
		}

		game.floor_layout[current_y][current_x].connections[direction] = true
		game.floor_layout[next_y][next_x].connections[opposite_direction] = true

		visited[next_y][next_x] = true
		append(&stack, Vec2{next_x, next_y})
		current_x, current_y = next_x, next_y
	}

	if game.floor_number > 1 {
		end_x = rand.int31() % FLOOR_SIZE
		end_y = rand.int31() % FLOOR_SIZE
		for (end_x == start_x && end_y == start_y) || !visited[end_y][end_x] {
			end_x = rand.int31() % FLOOR_SIZE
			end_y = rand.int31() % FLOOR_SIZE
		}
	}


	place_strategic_doors_and_keys(start_x, start_y, end_x, end_y)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if visited[y][x] {
				room := &game.floor_layout[y][x]
				generate_room_tiles(room, i32(x), i32(y), start_x, start_y, end_x, end_y)
				generate_room_enemies(room, i32(x), i32(y), start_x, start_y, end_x, end_y, visited[:])
				place_room_locked_doors(room, i32(x), i32(y))
			}
		}
	}

	place_secret_walls()

	if game.floor_number == 1 {
		game.room_coords = {1, 1}
	} else {
		game.room_coords = {start_x, start_y}
	}
}


place_strategic_doors_and_keys :: proc(start_x, start_y, end_x, end_y: i32) {
	find_reachable_rooms :: proc(start_x, start_y: i32) -> map[[2]i32]bool {
		reachable := make(map[[2]i32]bool)
		start_coords := [2]i32{-1, -1}

		for y in 0 ..< FLOOR_SIZE {
			for x in 0 ..< FLOOR_SIZE {
				if i32(x) == start_x && i32(y) == start_y {
					start_coords = {i32(x), i32(y)}
					break
				}
			}
		}

		if start_coords.x == -1 do return reachable

		queue := [dynamic][2]i32{}
		defer delete(queue)

		append(&queue, start_coords)
		reachable[start_coords] = true

		for len(queue) > 0 {
			current := queue[0]
			ordered_remove(&queue, 0)

			room := &game.floor_layout[current.y][current.x]

			directions := [4]Direction{.NORTH, .SOUTH, .EAST, .WEST}
			deltas := [4][2]i32{{0, -1}, {0, 1}, {1, 0}, {-1, 0}}

			for i in 0 ..< 4 {
				if !room.connections[directions[i]] do continue
				if room.locked_exits[directions[i]] do continue

				next_coord := current + deltas[i]
				if next_coord.x < 0 || next_coord.x >= FLOOR_SIZE || next_coord.y < 0 || next_coord.y >= FLOOR_SIZE do continue

				if !reachable[next_coord] {
					reachable[next_coord] = true
					append(&queue, next_coord)
				}
			}
		}
		return reachable
	}

	reachable := find_reachable_rooms(start_x, start_y)
	defer delete(reachable)

	keys_to_place := 2
	keys_placed := 0

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			coord := [2]i32{i32(x), i32(y)}
			room := &game.floor_layout[y][x]
			is_start := i32(x) == start_x && i32(y) == start_y
			is_end := game.floor_number > 1 && i32(x) == end_x && i32(y) == end_y
			if reachable[coord] && !is_start && !is_end && keys_placed < keys_to_place {
				key_x := ROOM_CENTRE - 2 + (room.id % 3)
				key_y := ROOM_CENTRE - 1 + (room.id % 2)
				room.tiles[key_y][key_x] = .KEY
				keys_placed += 1
			}
		}
	}

	if keys_placed == 0 do return

	all_connections := [dynamic][4]i32{}
	defer delete(all_connections)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[y][x]
			if room.connections[.EAST] && x < FLOOR_SIZE - 1 {
				room_is_start := i32(x) == start_x && i32(y) == start_y
				neighbor_is_start := i32(x + 1) == start_x && i32(y) == start_y
				if !room_is_start && !neighbor_is_start {
					append(&all_connections, [4]i32{i32(x), i32(y), i32(x + 1), i32(y)})
				}
			}
			if room.connections[.SOUTH] && y < FLOOR_SIZE - 1 {
				room_is_start := i32(x) == start_x && i32(y) == start_y
				neighbor_is_start := i32(x) == start_x && i32(y + 1) == start_y
				if !room_is_start && !neighbor_is_start {
					append(&all_connections, [4]i32{i32(x), i32(y), i32(x), i32(y + 1)})
				}
			}
		}
	}

	max_doors := min(keys_placed, len(all_connections))
	doors_placed := 0

	for doors_placed < max_doors && len(all_connections) > 0 {
		connection_idx := rand.int31() % i32(len(all_connections))
		connection := all_connections[connection_idx]
		ordered_remove(&all_connections, int(connection_idx))

		room1 := &game.floor_layout[connection[1]][connection[0]]
		room2 := &game.floor_layout[connection[3]][connection[2]]

		if connection[0] == connection[2] {
			room1.locked_exits[.SOUTH] = true
			room2.locked_exits[.NORTH] = true
		} else {
			room1.locked_exits[.EAST] = true
			room2.locked_exits[.WEST] = true
		}

		doors_placed += 1
	}
}

generate_room_tiles :: proc(room: ^Room, room_x, room_y, start_x, start_y, end_x, end_y: i32) {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			room.tiles[y][x] = .GRASS
		}
	}

	// place walls
	for i in 0 ..< ROOM_SIZE {
		room.tiles[0][i] = .STONE
		room.tiles[ROOM_SIZE - 1][i] = .STONE
		room.tiles[i][0] = .STONE
		room.tiles[i][ROOM_SIZE - 1] = .STONE
	}

	if room.connections[.NORTH] {
		room.tiles[0][ROOM_CENTRE - 1] = .GRASS
		room.tiles[0][ROOM_CENTRE] = .GRASS
	}
	if room.connections[.SOUTH] {
		room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
		room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
	}
	if room.connections[.WEST] {
		room.tiles[ROOM_CENTRE - 1][0] = .GRASS
		room.tiles[ROOM_CENTRE][0] = .GRASS
	}
	if room.connections[.EAST] {
		room.tiles[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
		room.tiles[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
	}

	is_title := game.floor_number == 1 && room_x == 1 && room_y == 1
	is_options := game.floor_number == 1 && room_x == 2 && room_y == 1
	is_start := room_x == start_x && room_y == start_y
	is_end := game.floor_number > 1 && room_x == end_x && room_y == end_y

	if is_end {
		room.tiles[ROOM_CENTRE][ROOM_CENTRE] = .EXIT
	} else if is_start && game.floor_number == 1 {
		room.tiles[ROOM_CENTRE][ROOM_CENTRE] = .EXIT
	} else if !is_start && !is_title && !is_options {
		boulder_count := 2 + (room.id % 3)
		for _ in 0 ..< boulder_count {
			boulder_x := 1 + rand.int31() % (ROOM_SIZE - 2)
			boulder_y := 1 + rand.int31() % (ROOM_SIZE - 2)
			if room.tiles[boulder_y][boulder_x] == .GRASS {
				room.tiles[boulder_y][boulder_x] = .BOULDER
			}
		}
	}

}

generate_room_enemies :: proc(room: ^Room, room_x, room_y, start_x, start_y, end_x, end_y: i32, visited: [][FLOOR_SIZE]bool) {
	is_title := game.floor_number == 1 && room_x == 1 && room_y == 1
	is_options := game.floor_number == 1 && room_x == 2 && room_y == 1
	is_start := room_x == start_x && room_y == start_y
	is_end := game.floor_number > 1 && room_x == end_x && room_y == end_y

	if !is_start && !is_end && !is_title && !is_options && rand.int31() % 3 == 0 {
		enemy_count := 2 + (room.id % 3)
		for _ in 0 ..< enemy_count {
			enemy_x := 1 + rand.int31() % (ROOM_SIZE - 2)
			enemy_y := 1 + rand.int31() % (ROOM_SIZE - 2)
			if room.tiles[enemy_y][enemy_x] == .GRASS {
				room.tiles[enemy_y][enemy_x] = .ENEMY
			}
		}
	}
}

place_room_locked_doors :: proc(room: ^Room, room_x, room_y: i32) {
	door_key := [3]i32{room_x, room_y, 0}

	if room.locked_exits[.NORTH] {
		door_key.z = i32(Direction.NORTH)
		if !game.unlocked_doors[door_key] {
			room.tiles[0][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[0][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.SOUTH] {
		door_key.z = i32(Direction.SOUTH)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.WEST] {
		door_key.z = i32(Direction.WEST)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_CENTRE - 1][0] = .LOCKED_DOOR
			room.tiles[ROOM_CENTRE][0] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.EAST] {
		door_key.z = i32(Direction.EAST)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .LOCKED_DOOR
			room.tiles[ROOM_CENTRE][ROOM_SIZE - 1] = .LOCKED_DOOR
		}
	}
}

place_secret_walls :: proc() {
	ROOM_END :: ROOM_SIZE - 1
	FLOOR_END :: FLOOR_SIZE - 1
	TILE_END :: ROOM_SIZE - 2
	SECRET_WALL_SPAWN_CHANCE :: 0.1

	for ry in 0 ..< FLOOR_SIZE {
		for rx in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[ry][rx]

			if rand.float32() <= SECRET_WALL_SPAWN_CHANCE {
				if !room.connections[.NORTH] && ry > 0 {
					tx := 1 + rand.int31() % TILE_END
					room.tiles[0][tx] = .SECRET_WALL
				}
				if !room.connections[.SOUTH] && ry < FLOOR_END {
					tx := 1 + rand.int31() % TILE_END
					room.tiles[ROOM_END][tx] = .SECRET_WALL
				}
				if !room.connections[.WEST] && rx > 0 {
					ty := 1 + rand.int31() % TILE_END
					room.tiles[ty][0] = .SECRET_WALL
				}
				if !room.connections[.EAST] && rx < FLOOR_END {
					ty := 1 + rand.int31() % TILE_END
					room.tiles[ty][ROOM_END] = .SECRET_WALL
				}
			}
		}
	}
}
