package main

import "core:math/rand"

FLOOR_SIZE :: 5 // equalateral length of a floor
ROOM_COUNT :: FLOOR_SIZE * FLOOR_SIZE // max rooms in a floor
ROOM_SIZE :: 16 // equalateral length of a room in tiles
ROOM_CENTRE :: ROOM_SIZE / 2 // the centerpoint of a room
TILE_COUNT :: ROOM_SIZE * ROOM_SIZE // number of tiles in a room

generate_floor :: proc() {
	visited := [FLOOR_SIZE][FLOOR_SIZE]bool{}
	stack := [dynamic][2]i32{}
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

	start_x := rand.int31() % FLOOR_SIZE
	start_y := rand.int31() % FLOOR_SIZE
	game.floor_layout[start_y][start_x].is_start = true

	current_x, current_y := start_x, start_y
	visited[current_y][current_x] = true
	append(&stack, [2]i32{current_x, current_y})

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

		if len(neighbors) > 0 {
			chosen := neighbors[rand.int31() % i32(len(neighbors))]
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
			append(&stack, [2]i32{next_x, next_y})
			current_x, current_y = next_x, next_y
		} else {
			if len(stack) > 1 {
				ordered_remove(&stack, len(stack) - 1)
				current_x, current_y = stack[len(stack) - 1].x, stack[len(stack) - 1].y
			} else {
				break
			}
		}
	}

	end_x := rand.int31() % FLOOR_SIZE
	end_y := rand.int31() % FLOOR_SIZE
	for (end_x == start_x && end_y == start_y) || !visited[end_y][end_x] {
		end_x = rand.int31() % FLOOR_SIZE
		end_y = rand.int31() % FLOOR_SIZE
	}
	game.floor_layout[end_y][end_x].is_end = true

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if visited[y][x] &&
			   !game.floor_layout[y][x].is_start &&
			   !game.floor_layout[y][x].is_end {
				game.floor_layout[y][x].has_enemies = rand.int31() % 3 == 0
			}
		}
	}

	place_strategic_doors_and_keys()

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[y][x]
			if room.id != 0 {
				generate_room_tiles(room)
			}
		}
	}

	place_secret_walls()

	game.room_coords = {start_x, start_y}
}

place_strategic_doors_and_keys :: proc() {
	find_reachable_rooms :: proc() -> map[[2]i32]bool {
		reachable := make(map[[2]i32]bool)
		start_coords := [2]i32{-1, -1}

		for y in 0 ..< FLOOR_SIZE {
			for x in 0 ..< FLOOR_SIZE {
				if game.floor_layout[y][x].is_start {
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

	reachable := find_reachable_rooms()
	defer delete(reachable)

	keys_to_place := 2
	keys_placed := 0

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			coord := [2]i32{i32(x), i32(y)}
			room := &game.floor_layout[y][x]
			if reachable[coord] && !room.is_start && !room.is_end && keys_placed < keys_to_place {
				room.has_key = true
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
				neighbor := &game.floor_layout[y][x + 1]
				if !room.is_start && !neighbor.is_start {
					append(&all_connections, [4]i32{i32(x), i32(y), i32(x + 1), i32(y)})
				}
			}
			if room.connections[.SOUTH] && y < FLOOR_SIZE - 1 {
				neighbor := &game.floor_layout[y + 1][x]
				if !room.is_start && !neighbor.is_start {
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

generate_room_tiles :: proc(room: ^Room) {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			room.tiles[y][x] = .GRASS
		}
	}

	for x in 0 ..< ROOM_SIZE {
		room.tiles[0][x] = .STONE
	}
	for x in 0 ..< ROOM_SIZE {
		room.tiles[ROOM_SIZE - 1][x] = .STONE
	}
	for y in 0 ..< ROOM_SIZE {
		room.tiles[y][0] = .STONE
	}
	for y in 0 ..< ROOM_SIZE {
		room.tiles[y][ROOM_SIZE - 1] = .STONE
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

	if room.is_end {
		room.tiles[ROOM_CENTRE][ROOM_CENTRE] = .EXIT
	} else if !room.is_start {
		water_count := 2 + (room.id % 3)
		for _ in 0 ..< water_count {
			water_x := 1 + rand.int31() % (ROOM_SIZE - 2)
			water_y := 1 + rand.int31() % (ROOM_SIZE - 2)
			if room.tiles[water_y][water_x] == .GRASS {
				room.tiles[water_y][water_x] = .WATER
			}
		}
	}

	if room.has_key {
		key_x := ROOM_CENTRE - 2 + (room.id % 3)
		key_y := ROOM_CENTRE - 1 + (room.id % 2)
		room.tiles[key_y][key_x] = .KEY
	}
}

place_secret_walls :: proc() {
	for room_y in 0 ..< FLOOR_SIZE {
		for room_x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[room_y][room_x]
			if room.id == 0 do continue

			if rand.int31() % 8 == 0 {
				if !room.connections[.NORTH] &&
				   room_y > 0 &&
				   game.floor_layout[room_y - 1][room_x].id != 0 {
					wall_x := 1 + rand.int31() % (ROOM_SIZE - 2)
					if room.tiles[0][wall_x] == .STONE {
						room.tiles[0][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.SOUTH] &&
				   room_y < FLOOR_SIZE - 1 &&
				   game.floor_layout[room_y + 1][room_x].id != 0 {
					wall_x := 1 + rand.int31() % (ROOM_SIZE - 2)
					if room.tiles[ROOM_SIZE - 1][wall_x] == .STONE {
						room.tiles[ROOM_SIZE - 1][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.WEST] &&
				   room_x > 0 &&
				   game.floor_layout[room_y][room_x - 1].id != 0 {
					wall_y := 1 + rand.int31() % (ROOM_SIZE - 2)
					if room.tiles[wall_y][0] == .STONE {
						room.tiles[wall_y][0] = .SECRET_WALL
					}
				}
				if !room.connections[.EAST] &&
				   room_x < FLOOR_SIZE - 1 &&
				   game.floor_layout[room_y][room_x + 1].id != 0 {
					wall_y := 1 + rand.int31() % (ROOM_SIZE - 2)
					if room.tiles[wall_y][ROOM_SIZE - 1] == .STONE {
						room.tiles[wall_y][ROOM_SIZE - 1] = .SECRET_WALL
					}
				}
			}
		}
	}
}
