package main

import "audio"
import "core:math/rand"
import rl "vendor:raylib"

is_in_bounds :: proc(pos: Vec2, max: int = ROOM_SIZE) -> bool {
	return pos.x < max && pos.y < max && pos.x >= 0 && pos.y >= 0
}

is_tile_walkable :: proc(pos: Vec2) -> bool {
	if !is_in_bounds(pos) do return false
	tile := world_get(pos)

	#partial switch world_get(pos) {
	case .STONE, .LOCKED_DOOR, .BOULDER: return false
	case: return true
	}
}

can_push_boulder :: proc(boulder, dir: Vec2) -> bool {
	return is_tile_walkable(boulder + dir)
}

push_boulder :: proc(boulder, push_dir: Vec2) {
	if !can_push_boulder(boulder, push_dir) do return

	world_set(boulder, .GRASS)
	world_set(boulder + push_dir, .BOULDER)
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
		world_set({0, ROOM_CENTRE - 1}, .GRASS)
		world_set({0, ROOM_CENTRE}, .GRASS)

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
		world_set({ROOM_SIZE - 1, ROOM_CENTRE - 1}, .GRASS)
		world_set({ROOM_SIZE - 1, ROOM_CENTRE}, .GRASS)

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
		world_set({ROOM_CENTRE - 1, 0}, .GRASS)
		world_set({ROOM_CENTRE, 0}, .GRASS)

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
		world_set({ROOM_CENTRE - 1, ROOM_SIZE}, .GRASS)
		world_set({ROOM_CENTRE, ROOM_SIZE}, .GRASS)

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
	if world_get(game.player.position) == .ENEMY {
		combat_init(game.player.x, game.player.y)
		return true
	}
	return false
}
