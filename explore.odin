package main

import "core:math/rand"
import rl "vendor:raylib"


is_tile_walkable :: proc(x, y: i32) -> bool {
	assert(x < ROOM_SIZE && y < ROOM_SIZE)
	return game.world[y][x] != .STONE && game.world[y][x] != .LOCKED_DOOR
}

can_unlock_door :: proc(x, y: i32) -> bool {
	return game.world[y][x] == .LOCKED_DOOR && len(game.following_items) > 0
}

get_door_direction :: proc(x, y: i32) -> i32 {
	if y == 0 && (x == ROOM_CENTRE - 1 || x == ROOM_CENTRE) do return i32(Direction.NORTH)
	if y == ROOM_SIZE - 1 && (x == ROOM_CENTRE - 1 || x == ROOM_CENTRE) do return i32(Direction.SOUTH)
	if x == 0 && (y == ROOM_CENTRE - 1 || y == ROOM_CENTRE) do return i32(Direction.WEST)
	if x == ROOM_SIZE - 1 && (y == ROOM_CENTRE - 1 || y == ROOM_CENTRE) do return i32(Direction.EAST)
	return -1
}

unlock_door_connection :: proc(direction: Direction) {
	current_door_key := [3]i32{game.room_coords.x, game.room_coords.y, i32(direction)}
	game.unlocked_doors[current_door_key] = true

	switch direction {
	case .NORTH:
		game.world[0][ROOM_CENTRE - 1] = .GRASS
		game.world[0][ROOM_CENTRE] = .GRASS
		if game.room_coords.y > 0 {
			neighbor_door_key := [3]i32 {
				game.room_coords.x,
				game.room_coords.y - 1,
				i32(Direction.SOUTH),
			}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .SOUTH:
		game.world[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
		game.world[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
		if game.room_coords.y < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]i32 {
				game.room_coords.x,
				game.room_coords.y + 1,
				i32(Direction.NORTH),
			}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .WEST:
		game.world[ROOM_CENTRE - 1][0] = .GRASS
		game.world[ROOM_CENTRE][0] = .GRASS
		if game.room_coords.x > 0 {
			neighbor_door_key := [3]i32 {
				game.room_coords.x - 1,
				game.room_coords.y,
				i32(Direction.EAST),
			}
			game.unlocked_doors[neighbor_door_key] = true
		}
	case .EAST:
		game.world[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
		game.world[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
		if game.room_coords.x < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]i32 {
				game.room_coords.x + 1,
				game.room_coords.y,
				i32(Direction.WEST),
			}
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

	if new_x >= ROOM_SIZE && room.connections[.EAST] {
		game.room_coords.x += 1
		game.player.x = 0
	} else if new_x < 0 && room.connections[.WEST] {
		game.room_coords.x -= 1
		game.player.x = ROOM_SIZE - 1
	} else if new_y < 0 && room.connections[.NORTH] {
		game.room_coords.y -= 1
		game.player.y = ROOM_SIZE - 1
	} else if new_y >= ROOM_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 0
	} else {
		if is_tile_walkable(new_x, new_y) {
			if game.world[new_y][new_x] == .KEY {
				game.world[new_y][new_x] = .GRASS
				append(
					&game.following_items,
					FollowingItem {
						x = new_x,
						y = new_y,
						target_x = game.player.x,
						target_y = game.player.y,
					},
				)
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
				game.player.x = ROOM_SIZE - 1
				game.player.y = new_y
			} else if new_x == ROOM_SIZE - 1 && game.room_coords.x < FLOOR_SIZE - 1 {
				game.room_coords.x += 1
				game.player.x = 0
				game.player.y = new_y
			} else if new_y == 0 && game.room_coords.y > 0 {
				game.room_coords.y -= 1
				game.player.x = new_x
				game.player.y = ROOM_SIZE - 1
			} else if new_y == ROOM_SIZE - 1 && game.room_coords.y < FLOOR_SIZE - 1 {
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

			if new_x == 0 || new_x == ROOM_SIZE - 1 || new_y == 0 || new_y == ROOM_SIZE - 1 {
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
			game.world[0][ROOM_CENTRE - 1] = .LOCKED_DOOR
			game.world[0][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.SOUTH] {
		door_key.z = i32(Direction.SOUTH)
		if !game.unlocked_doors[door_key] {
			game.world[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .LOCKED_DOOR
			game.world[ROOM_SIZE - 1][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.WEST] {
		door_key.z = i32(Direction.WEST)
		if !game.unlocked_doors[door_key] {
			game.world[ROOM_CENTRE - 1][0] = .LOCKED_DOOR
			game.world[ROOM_CENTRE][0] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.EAST] {
		door_key.z = i32(Direction.EAST)
		if !game.unlocked_doors[door_key] {
			game.world[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .LOCKED_DOOR
			game.world[ROOM_CENTRE][ROOM_SIZE - 1] = .LOCKED_DOOR
		}
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
