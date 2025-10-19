package main

import "core:math/rand"
import rl "vendor:raylib"

generate_floor :: proc() {

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

	end_x := rand.int31() % FLOOR_SIZE
	end_y := rand.int31() % FLOOR_SIZE
	for end_x == start_x && end_y == start_y {
		end_x = rand.int31() % FLOOR_SIZE
		end_y = rand.int31() % FLOOR_SIZE
	}
	game.floor_layout[end_y][end_x].is_end = true

	current_x, current_y := start_x, start_y
	for current_x != end_x || current_y != end_y {

		if current_x < end_x {
			next_x, next_y := current_x + 1, current_y
			game.floor_layout[current_y][current_x].connections[.EAST] = true
			game.floor_layout[next_y][next_x].connections[.WEST] = true
			current_x = next_x
		} else if current_x > end_x {
			next_x, next_y := current_x - 1, current_y
			game.floor_layout[current_y][current_x].connections[.WEST] = true
			game.floor_layout[next_y][next_x].connections[.EAST] = true
			current_x = next_x
		} else if current_y < end_y {
			next_x, next_y := current_x, current_y + 1
			game.floor_layout[current_y][current_x].connections[.SOUTH] = true
			game.floor_layout[next_y][next_x].connections[.NORTH] = true
			current_y = next_y
		} else if current_y > end_y {
			next_x, next_y := current_x, current_y - 1
			game.floor_layout[current_y][current_x].connections[.NORTH] = true
			game.floor_layout[next_y][next_x].connections[.SOUTH] = true
			current_y = next_y
		}
	}

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if !game.floor_layout[y][x].is_start && !game.floor_layout[y][x].is_end {
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
			if (y == 0 && !room.connections[.NORTH]) ||
			   (y == TILES_SIZE - 1 && !room.connections[.SOUTH]) ||
			   (x == 0 && !room.connections[.WEST]) ||
			   (x == TILES_SIZE - 1 && !room.connections[.EAST]) {
				game.world[y][x] = .STONE
			}
		}
	}

	if room.is_end {
		game.world[CENTRE][CENTRE] = .EXIT
	} else {
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
			start_battle_transition(enemy.x, enemy.y)
			return true
		}
	}
	return false
}