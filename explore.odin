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

	game.room_coords = {start_x, start_y}
}

load_current_room :: proc() {
	clear(&game.enemies)

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			game.world[y][x] = .GRASS
		}
	}

	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			is_wall := false

			if y == 0 && !room.connections[.NORTH] {
				is_wall = true
			} else if y == TILES_SIZE - 1 && !room.connections[.SOUTH] {
				is_wall = true
			} else if x == 0 && !room.connections[.WEST] {
				is_wall = true
			} else if x == TILES_SIZE - 1 && !room.connections[.EAST] {
				is_wall = true
			}

			if y == 0 && room.connections[.NORTH] && (x < CENTRE - 1 || x > CENTRE) {
				is_wall = true
			} else if y == TILES_SIZE - 1 && room.connections[.SOUTH] && (x < CENTRE - 1 || x > CENTRE) {
				is_wall = true
			} else if x == 0 && room.connections[.WEST] && (y < CENTRE - 1 || y > CENTRE) {
				is_wall = true
			} else if x == TILES_SIZE - 1 && room.connections[.EAST] && (y < CENTRE - 1 || y > CENTRE) {
				is_wall = true
			}

			if is_wall {
				game.world[y][x] = .STONE
			}
		}
	}

	if room.is_end {
		game.world[CENTRE][CENTRE] = .EXIT
	} else if !room.is_start {
		water_count := 2 + (room.id % 3)
		for i in 0 ..< water_count {
			wx := 3 + (i * 4) % 10
			wy := 3 + (i * 3) % 10
			for dy in 0 ..< 2 {
				for dx in 0 ..< 2 {
					if i32(wx) + i32(dx) < TILES_SIZE - 1 && i32(wy) + i32(dy) < TILES_SIZE - 1 {
						game.world[i32(wy) + i32(dy)][i32(wx) + i32(dx)] = .WATER
					}
				}
			}
		}
	}

	if room.has_enemies {
		enemy_count := 1 + (room.id % 3)
		for i in 0 ..< enemy_count {
			ex := 2 + (i * 5) % 12
			ey := 2 + (i * 7) % 12
			axis := u8(i % 2)
			append(
				&game.enemies,
				Enemy{x = ex, y = ey, direction = 1, min_pos = 2, max_pos = 13, axis = axis},
			)
		}
	}

	if !room.is_start && !room.is_end && room.id % 4 == 1 {
		key_x := 3 + (room.id * 2) % 10
		key_y := 3 + (room.id * 3) % 10
		game.world[key_y][key_x] = .KEY
	}
}

is_tile_walkable :: proc(x, y: i32) -> bool {
	return game.world[y][x] != .STONE
}

update_player :: proc(dt: f32) {
	game.move_timer -= dt

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
		game.player.x = 1
	} else if new_x < 0 && room.connections[.WEST]  {
		game.room_coords.x -= 1
		game.player.x = TILES_SIZE - 2
	} else if new_y < 0 && room.connections[.NORTH]  {
		game.room_coords.y -= 1
		game.player.y = TILES_SIZE - 2
	} else if new_y >= TILES_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 1
	} else {
		if is_tile_walkable(new_x, new_y) {
			spawn_dust(game.player.x, game.player.y)

			if game.world[new_y][new_x] == .KEY {
				game.world[new_y][new_x] = .GRASS
				append(&game.following_items, FollowingItem{x = new_x, y = new_y, target_x = game.player.x, target_y = game.player.y})
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

update_enemies :: proc(dt: f32) {
	game.enemy_timer -= dt
	if game.enemy_timer > 0 do return

	for &enemy in game.enemies {
		spawn_dust(enemy.x, enemy.y)

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

update_following_items :: proc(player_x, player_y: i32) {
	if len(game.following_items) == 0 do return

	for i in 0 ..< len(game.following_items) {
		item := &game.following_items[i]

		if i == 0 {
			item.target_x = player_x
			item.target_y = player_y
		} else {
			prev_item := &game.following_items[i - 1]
			item.target_x = prev_item.x
			item.target_y = prev_item.y
		}

		if item.x != item.target_x || item.y != item.target_y {
			item.x = item.target_x
			item.y = item.target_y
		}
	}
}