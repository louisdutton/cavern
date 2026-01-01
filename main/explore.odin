package main

import "audio"
import "core:math/rand"
import rl "vendor:raylib"

is_tile_walkable :: proc(x, y: int) -> bool {
	assert(x < ROOM_SIZE && y < ROOM_SIZE)
	return(
		game.world[y][x] != .STONE &&
		game.world[y][x] != .LOCKED_DOOR &&
		game.world[y][x] != .BOULDER \
	)
}

can_unlock_door :: proc(x, y: int) -> bool {
	return game.world[y][x] == .LOCKED_DOOR && len(game.inventory) > 0
}

can_push_boulder :: proc(boulder_x, boulder_y, push_dir_x, push_dir_y: int) -> bool {
	if game.world[boulder_y][boulder_x] != .BOULDER do return false

	new_boulder_x := boulder_x + push_dir_x
	new_boulder_y := boulder_y + push_dir_y

	if new_boulder_x < 0 ||
	   new_boulder_x >= ROOM_SIZE ||
	   new_boulder_y < 0 ||
	   new_boulder_y >= ROOM_SIZE {
		return false
	}

	return game.world[new_boulder_y][new_boulder_x] == .GRASS
}

push_boulder :: proc(boulder_x, boulder_y, push_dir_x, push_dir_y: int) {
	if !can_push_boulder(boulder_x, boulder_y, push_dir_x, push_dir_y) do return

	new_boulder_x := boulder_x + push_dir_x
	new_boulder_y := boulder_y + push_dir_y

	game.world[boulder_y][boulder_x] = .GRASS
	game.world[new_boulder_y][new_boulder_x] = .BOULDER
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
		if is_tile_walkable(new.x, new.y) {
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

			audio.play(.CLICK)

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

			audio.play(.DESTROY)

			if new.x == 0 || new.x == ROOM_SIZE - 1 || new.y == 0 || new.y == ROOM_SIZE - 1 {
				load_current_room()
			}

		} else if can_unlock_door(new.x, new.y) {
			ordered_remove(&game.inventory, len(game.inventory) - 1)

			door_direction := get_door_direction(new.x, new.y)
			if door_direction != -1 {
				unlock_door_connection(Direction(door_direction))
				add_screen_shake(15)
				audio.play(.UNLOCK)
				audio.play(.DESTROY)
			}

			inventory_update(game.player.position)

			game.player.x = new.x
			game.player.y = new.y
			game.move_timer = MOVE_DELAY

		} else if game.world[new.y][new.x] == .BOULDER {
			push_dir_x := new.x - game.player.x
			push_dir_y := new.y - game.player.y

			if can_push_boulder(new.x, new.y, push_dir_x, push_dir_y) {
				push_boulder(new.x, new.y, push_dir_x, push_dir_y)

				inventory_update(game.player.x)

				game.player.x = new.x
				game.player.y = new.y
				game.move_timer = MOVE_DELAY

				audio.play(.METAL)
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
