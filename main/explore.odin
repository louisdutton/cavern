package main

import "audio"
import "core:math/rand"
import rl "vendor:raylib"

is_in_bounds :: proc(pos: Vec2, max: int = ROOM_SIZE) -> bool {
	return pos.x < max && pos.y < max && pos.x >= 0 && pos.y >= 0
}

is_tile_walkable :: proc(pos: Vec2) -> bool {
	assert(is_in_bounds(pos))
	return(
		game.world[pos.y][pos.x] != .STONE &&
		game.world[pos.y][pos.x] != .LOCKED_DOOR &&
		game.world[pos.y][pos.x] != .BOULDER \
	)
}

can_unlock_door :: proc(pos: Vec2) -> bool {
	return game.world[pos.y][pos.x] == .LOCKED_DOOR && len(game.inventory) > 0
}

can_push_boulder :: proc(boulder, dir: Vec2) -> bool {
	if game.world[boulder.y][boulder.x] != .BOULDER do return false
	target := boulder + dir
	return is_in_bounds(target) && game.world[target.y][target.x] == .GRASS
}

push_boulder :: proc(boulder, push_dir: Vec2) {
	if !can_push_boulder(boulder, push_dir) do return

	new_boulder := boulder + push_dir

	game.world[boulder.y][boulder.x] = .GRASS
	game.world[new_boulder.y][new_boulder.x] = .BOULDER
}

get_door_direction :: proc(x, y: int) -> int {
	if y == 0 && (x == ROOM_CENTRE - 1 || x == ROOM_CENTRE) do return int(Direction.NORTH)
	if y == ROOM_SIZE - 1 && (x == ROOM_CENTRE - 1 || x == ROOM_CENTRE) do return int(Direction.SOUTH)
	if x == 0 && (y == ROOM_CENTRE - 1 || y == ROOM_CENTRE) do return int(Direction.WEST)
	if x == ROOM_SIZE - 1 && (y == ROOM_CENTRE - 1 || y == ROOM_CENTRE) do return int(Direction.EAST)
	return -1
}

unlock_door_connection :: proc(direction: Direction) {
	current_door_key := [3]int{game.room_coords.x, game.room_coords.y, int(direction)}
	game.unlocked_doors[current_door_key] = true

	switch direction {
	case .NORTH:
		game.world[0][ROOM_CENTRE - 1] = .GRASS
		game.world[0][ROOM_CENTRE] = .GRASS
		if game.room_coords.y > 0 {
			neighbor_door_key := [3]int {
				game.room_coords.x,
				game.room_coords.y - 1,
				int(Direction.SOUTH),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y - 1][game.room_coords.x]
			neighbor_room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
			neighbor_room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
		}
	case .SOUTH:
		game.world[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
		game.world[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
		if game.room_coords.y < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]int {
				game.room_coords.x,
				game.room_coords.y + 1,
				int(Direction.NORTH),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y + 1][game.room_coords.x]
			neighbor_room.tiles[0][ROOM_CENTRE - 1] = .GRASS
			neighbor_room.tiles[0][ROOM_CENTRE] = .GRASS
		}
	case .WEST:
		game.world[ROOM_CENTRE - 1][0] = .GRASS
		game.world[ROOM_CENTRE][0] = .GRASS
		if game.room_coords.x > 0 {
			neighbor_door_key := [3]int {
				game.room_coords.x - 1,
				game.room_coords.y,
				int(Direction.EAST),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y][game.room_coords.x - 1]
			neighbor_room.tiles[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
			neighbor_room.tiles[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
		}
	case .EAST:
		game.world[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
		game.world[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
		if game.room_coords.x < FLOOR_SIZE - 1 {
			neighbor_door_key := [3]int {
				game.room_coords.x + 1,
				game.room_coords.y,
				int(Direction.WEST),
			}
			game.unlocked_doors[neighbor_door_key] = true
			neighbor_room := &game.floor_layout[game.room_coords.y][game.room_coords.x + 1]
			neighbor_room.tiles[ROOM_CENTRE - 1][0] = .GRASS
			neighbor_room.tiles[ROOM_CENTRE][0] = .GRASS
		}
	}
}

update_player :: proc() {
	game.move_timer -= 1
	if game.move_timer > 0 do return

	dir := input_get_direction()
	if is_zero_vec2(dir) do return
	new := dir + {game.player.x, game.player.y}

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	if new.x >= ROOM_SIZE && room.connections[.EAST] {
		game.room_coords.x += 1
		game.player.x = 0
	} else if new.x < 0 && room.connections[.WEST] {
		game.room_coords.x -= 1
		game.player.x = ROOM_SIZE - 1
	} else if new.y < 0 && room.connections[.NORTH] {
		game.room_coords.y -= 1
		game.player.y = ROOM_SIZE - 1
	} else if new.y >= ROOM_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 0
	} else {
		if is_tile_walkable(new) {
			if game.world[new.y][new.x] == .KEY ||
			   game.world[new.y][new.x] == .SWORD ||
			   game.world[new.y][new.x] == .SHIELD {
				kind := game.world[new.y][new.x]
				game.world[new.y][new.x] = .GRASS
				append(
					&game.inventory,
					Item {
						x = new.x,
						y = new.y,
						target_x = game.player.x,
						target_y = game.player.y,
						kind = kind,
					},
				)
			}

			inventory_update(game.player.position)

			game.player.x = new.x
			game.player.y = new.y
			game.move_timer = MOVE_DELAY

			audio.play_sound(.CLICK)

		} else if game.world[new.y][new.x] == .SECRET_WALL {
			game.world[new.y][new.x] = .GRASS
			add_screen_shake(20)

			if new.x == 0 && game.room_coords.x > 0 {
				game.room_coords.x -= 1
				game.player.x = ROOM_SIZE - 1
				game.player.y = new.y
			} else if new.x == ROOM_SIZE - 1 && game.room_coords.x < FLOOR_SIZE - 1 {
				game.room_coords.x += 1
				game.player.x = 0
				game.player.y = new.y
			} else if new.y == 0 && game.room_coords.y > 0 {
				game.room_coords.y -= 1
				game.player.x = new.x
				game.player.y = ROOM_SIZE - 1
			} else if new.y == ROOM_SIZE - 1 && game.room_coords.y < FLOOR_SIZE - 1 {
				game.room_coords.y += 1
				game.player.x = new.x
				game.player.y = 0
			} else {
				game.player.x = new.x
				game.player.y = new.y
			}
			game.move_timer = MOVE_DELAY

			audio.play_sound(.DESTROY)

			if new.x == 0 || new.x == ROOM_SIZE - 1 || new.y == 0 || new.y == ROOM_SIZE - 1 {
				load_current_room()
			}

		} else if can_unlock_door(new) {
			ordered_remove(&game.inventory, len(game.inventory) - 1)

			door_direction := get_door_direction(new.x, new.y)
			if door_direction != -1 {
				unlock_door_connection(Direction(door_direction))
				add_screen_shake(15)
				audio.play_sound(.UNLOCK)
				audio.play_sound(.DESTROY)
			}

			inventory_update(game.player.position)

			game.player.x = new.x
			game.player.y = new.y
			game.move_timer = MOVE_DELAY

		} else if game.world[new.y][new.x] == .BOULDER {
			push_dir := new - game.player.position

			if can_push_boulder(new, push_dir) {
				push_boulder(new, push_dir)

				inventory_update(game.player.x)

				game.player.x = new.x
				game.player.y = new.y
				game.move_timer = MOVE_DELAY

				audio.play_sound(.METAL)
			}
		}
		return
	}

	game.move_timer = MOVE_DELAY
	inventory_update(game.player.position)
	load_current_room()
}

update_enemies :: proc() {
	game.enemy_timer -= 1
	if game.enemy_timer > 0 do return

	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			if game.world[y][x] == .ENEMY {
				new_x, new_y := int(x), int(y)

				if rand.int31() % 2 == 0 {
					if rand.int31() % 2 == 0 {
						new_x += (int(rand.int31()) % 2) * 2 - 1
					} else {
						new_y += (int(rand.int31()) % 2) * 2 - 1
					}
				}

				if new_x >= 1 &&
				   new_x < ROOM_SIZE - 1 &&
				   new_y >= 1 &&
				   new_y < ROOM_SIZE - 1 &&
				   game.world[new_y][new_x] == .GRASS {
					game.world[y][x] = .GRASS
					game.world[new_y][new_x] = .ENEMY
				}
			}
		}
	}

	game.enemy_timer = ENEMY_DELAY
}

check_player_enemy_collision :: proc() -> bool {
	if game.world[game.player.y][game.player.x] == .ENEMY {
		combat_init(game.player.x, game.player.y)
		return true
	}
	return false
}
