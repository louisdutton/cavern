package main

import "core:math/rand"
import rl "vendor:raylib"

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
			if visited[y][x] && !game.floor_layout[y][x].is_start && !game.floor_layout[y][x].is_end {
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


is_tile_walkable :: proc(x, y: i32) -> bool {
	return game.world[y][x] != .STONE && game.world[y][x] != .LOCKED_DOOR
}

can_unlock_door :: proc(x, y: i32) -> bool {
	return game.world[y][x] == .LOCKED_DOOR && len(game.following_items) > 0
}

get_door_direction :: proc(x, y: i32) -> i32 {
	if y == 0 && (x == CENTRE - 1 || x == CENTRE) do return i32(Direction.NORTH)
	if y == TILES_SIZE - 1 && (x == CENTRE - 1 || x == CENTRE) do return i32(Direction.SOUTH)
	if x == 0 && (y == CENTRE - 1 || y == CENTRE) do return i32(Direction.WEST)
	if x == TILES_SIZE - 1 && (y == CENTRE - 1 || y == CENTRE) do return i32(Direction.EAST)
	return -1
}

unlock_door_connection :: proc(direction: Direction) {
	current_door_key := [3]i32{game.room_coords.x, game.room_coords.y, i32(direction)}
	game.unlocked_doors[current_door_key] = true

	switch direction {
	case .NORTH:
		game.world[0][CENTRE - 1] = .GRASS
		game.world[0][CENTRE] = .GRASS
		if game.room_coords.y > 0 {
			neighbor_door_key := [3]i32{game.room_coords.x, game.room_coords.y - 1, i32(Direction.SOUTH)}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .SOUTH:
		game.world[TILES_SIZE - 1][CENTRE - 1] = .GRASS
		game.world[TILES_SIZE - 1][CENTRE] = .GRASS
		if game.room_coords.y < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]i32{game.room_coords.x, game.room_coords.y + 1, i32(Direction.NORTH)}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .WEST:
		game.world[CENTRE - 1][0] = .GRASS
		game.world[CENTRE][0] = .GRASS
		if game.room_coords.x > 0 {
			neighbor_door_key := [3]i32{game.room_coords.x - 1, game.room_coords.y, i32(Direction.EAST)}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .EAST:
		game.world[CENTRE - 1][TILES_SIZE - 1] = .GRASS
		game.world[CENTRE][TILES_SIZE - 1] = .GRASS
		if game.room_coords.x < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]i32{game.room_coords.x + 1, game.room_coords.y, i32(Direction.WEST)}
			game.unlocked_doors[neighbor_door_key] = true
		}
	}
}

update_player :: proc() {
	game.move_timer -= 1

	if game.move_timer > 0 do return

	new_x := game.player.x
	new_y := game.player.y
	moved := false

	if rl.IsKeyDown(.W) {
		new_y -= 1
		moved = true
	} else if rl.IsKeyDown(.S) {
		new_y += 1
		moved = true
	} else if rl.IsKeyDown(.A) {
		new_x -= 1
		moved = true
	} else if rl.IsKeyDown(.D) {
		new_x += 1
		moved = true
	}

	if !moved do return

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	if new_x >= TILES_SIZE && room.connections[.EAST] {
		game.room_coords.x += 1
		game.player.x = 0
	} else if new_x < 0 && room.connections[.WEST]  {
		game.room_coords.x -= 1
		game.player.x = TILES_SIZE - 1
	} else if new_y < 0 && room.connections[.NORTH]  {
		game.room_coords.y -= 1
		game.player.y = TILES_SIZE - 1
	} else if new_y >= TILES_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 0
	} else {
		if is_tile_walkable(new_x, new_y) {
			if game.world[new_y][new_x] == .KEY {
				game.world[new_y][new_x] = .GRASS
				append(&game.following_items, FollowingItem{x = new_x, y = new_y, target_x = game.player.x, target_y = game.player.y})
				current_room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
				current_room.has_key = false
			}

			update_following_items(game.player.x, game.player.y)

			game.player.x = new_x
			game.player.y = new_y
			game.move_timer = MOVE_DELAY

			pitch := 0.8 + f32((game.player.x + game.player.y) % 5) * 0.1
			rl.SetSoundPitch(game.click_sound, pitch)
			rl.PlaySound(game.click_sound)

		} else if game.world[new_y][new_x] == .SECRET_WALL {
			game.world[new_y][new_x] = .GRASS
			add_screen_shake(20)

			if new_x == 0 && game.room_coords.x > 0 {
				game.room_coords.x -= 1
				game.player.x = TILES_SIZE - 1
				game.player.y = new_y
			} else if new_x == TILES_SIZE - 1 && game.room_coords.x < FLOOR_SIZE - 1 {
				game.room_coords.x += 1
				game.player.x = 0
				game.player.y = new_y
			} else if new_y == 0 && game.room_coords.y > 0 {
				game.room_coords.y -= 1
				game.player.x = new_x
				game.player.y = TILES_SIZE - 1
			} else if new_y == TILES_SIZE - 1 && game.room_coords.y < FLOOR_SIZE - 1 {
				game.room_coords.y += 1
				game.player.x = new_x
				game.player.y = 0
			} else {
				game.player.x = new_x
				game.player.y = new_y
			}
			game.move_timer = MOVE_DELAY

			pitch := 1.0 + f32(rand.int31() % 3) * 0.2
			rl.SetSoundPitch(game.click_sound, pitch)
			rl.PlaySound(game.click_sound)

			if new_x == 0 || new_x == TILES_SIZE - 1 || new_y == 0 || new_y == TILES_SIZE - 1 {
				load_current_room()
			}

		} else if can_unlock_door(new_x, new_y) {
			ordered_remove(&game.following_items, len(game.following_items) - 1)

			door_direction := get_door_direction(new_x, new_y)
			if door_direction != -1 {
				unlock_door_connection(Direction(door_direction))
				add_screen_shake(15)
			}

			update_following_items(game.player.x, game.player.y)

			game.player.x = new_x
			game.player.y = new_y
			game.move_timer = MOVE_DELAY

			pitch := 0.8 + f32((game.player.x + game.player.y) % 5) * 0.1
			rl.SetSoundPitch(game.click_sound, pitch)
			rl.PlaySound(game.click_sound)

		}
		return
	}

	game.move_timer = MOVE_DELAY
	update_following_items(game.player.x, game.player.y)
	load_current_room()
}

update_enemies :: proc() {
	game.enemy_timer -= 1
	if game.enemy_timer > 0 do return

	for &enemy in game.enemies {

		if enemy.axis == 0 {
			enemy.x += enemy.direction
			if enemy.x <= enemy.min_pos || enemy.x >= enemy.max_pos {
				enemy.direction *= -1
			}
		} else {
			enemy.y += enemy.direction
			if enemy.y <= enemy.min_pos || enemy.y >= enemy.max_pos {
				enemy.direction *= -1
			}
		}
	}

	game.enemy_timer = ENEMY_DELAY
}

check_player_enemy_collision :: proc() -> bool {
	for enemy in game.enemies {
		if game.player.x == enemy.x && game.player.y == enemy.y {
			init_battle(enemy.x, enemy.y)
			return true
		}
	}
	return false
}


place_locked_doors_at_exits :: proc(room: ^Room) {
	door_key := [3]i32{game.room_coords.x, game.room_coords.y, 0}

	if room.locked_exits[.NORTH] {
		door_key.z = i32(Direction.NORTH)
		if !game.unlocked_doors[door_key] {
			game.world[0][CENTRE - 1] = .LOCKED_DOOR
			game.world[0][CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.SOUTH] {
		door_key.z = i32(Direction.SOUTH)
		if !game.unlocked_doors[door_key] {
			game.world[TILES_SIZE - 1][CENTRE - 1] = .LOCKED_DOOR
			game.world[TILES_SIZE - 1][CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.WEST] {
		door_key.z = i32(Direction.WEST)
		if !game.unlocked_doors[door_key] {
			game.world[CENTRE - 1][0] = .LOCKED_DOOR
			game.world[CENTRE][0] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.EAST] {
		door_key.z = i32(Direction.EAST)
		if !game.unlocked_doors[door_key] {
			game.world[CENTRE - 1][TILES_SIZE - 1] = .LOCKED_DOOR
			game.world[CENTRE][TILES_SIZE - 1] = .LOCKED_DOOR
		}
	}
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

update_following_items :: proc(player_x, player_y: i32) {
	if len(game.following_items) == 0 do return

	prev_x := player_x
	prev_y := player_y

	for i in 0 ..< len(game.following_items) {
		item := &game.following_items[i]

		old_x := item.x
		old_y := item.y

		item.x = prev_x
		item.y = prev_y

		prev_x = old_x
		prev_y = old_y
	}
}