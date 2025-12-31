package main

import "core:math/rand"

FLOOR_SIZE :: 5 // equalateral length of a floor
ROOM_COUNT :: FLOOR_SIZE * FLOOR_SIZE // max rooms in a floor
ROOM_SIZE :: 16 // equalateral length of a room in tiles
ROOM_CENTRE :: ROOM_SIZE / 2 // the centerpoint of a room
TILE_COUNT :: ROOM_SIZE * ROOM_SIZE // number of tiles in a room

Vec2 :: [2]i32

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

	start_x, start_y: i32
	end_x, end_y: i32

	if game.floor_number == 1 {
		start_x = 1
		start_y = 2
	} else {
		start_x = rand.int31() % FLOOR_SIZE
		start_y = rand.int31() % FLOOR_SIZE
	}

	end_x = rand.int31() % FLOOR_SIZE
	end_y = rand.int31() % FLOOR_SIZE
	min_distance := i32(3)
	if game.floor_number == 1 {
		for (end_x == start_x && end_y == start_y) ||
		    (end_x == 1 && end_y == 1) ||
		    (end_x == 2 && end_y == 1) ||
		    (abs(end_x - start_x) + abs(end_y - start_y) < min_distance) {
			end_x = rand.int31() % FLOOR_SIZE
			end_y = rand.int31() % FLOOR_SIZE
		}
	} else {
		for (end_x == start_x && end_y == start_y) ||
		    (abs(end_x - start_x) + abs(end_y - start_y) < min_distance) {
			end_x = rand.int31() % FLOOR_SIZE
			end_y = rand.int31() % FLOOR_SIZE
		}
	}

	create_path_start_to_end(start_x, start_y, end_x, end_y)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if room_exists(i32(x), i32(y)) {
				room := &game.floor_layout[y][x]
				generate_room_tiles(room, i32(x), i32(y), start_x, start_y, end_x, end_y)
				generate_room_enemies(room, i32(x), i32(y), start_x, start_y, end_x, end_y)
				place_room_locked_doors(room, i32(x), i32(y))
			}
		}
	}

	place_lock_and_key_on_path(start_x, start_y, end_x, end_y)
	place_sword_and_shield(start_x, start_y, end_x, end_y)

	if game.floor_number == 1 {
		game.room_coords = {1, 1}
	} else {
		game.room_coords = {start_x, start_y}
	}
}

room_exists :: proc(x, y: i32) -> bool {
	if x < 0 || x >= FLOOR_SIZE || y < 0 || y >= FLOOR_SIZE do return false
	room := &game.floor_layout[y][x]
	return(
		room.connections[.NORTH] ||
		room.connections[.SOUTH] ||
		room.connections[.EAST] ||
		room.connections[.WEST] \
	)
}

create_path_start_to_end :: proc(start_x, start_y, end_x, end_y: i32) {
	if game.floor_number == 1 {
		game.floor_layout[1][1].connections[.SOUTH] = true
		game.floor_layout[1][1].connections[.EAST] = true
		game.floor_layout[1][2].connections[.WEST] = true
		game.floor_layout[2][1].connections[.NORTH] = true
	}

	current_x, current_y := start_x, start_y

	for current_x != end_x {
		if current_x < end_x {
			game.floor_layout[current_y][current_x].connections[.EAST] = true
			game.floor_layout[current_y][current_x + 1].connections[.WEST] = true
			current_x += 1
		} else {
			game.floor_layout[current_y][current_x].connections[.WEST] = true
			game.floor_layout[current_y][current_x - 1].connections[.EAST] = true
			current_x -= 1
		}
	}

	for current_y != end_y {
		if current_y < end_y {
			game.floor_layout[current_y][current_x].connections[.SOUTH] = true
			game.floor_layout[current_y + 1][current_x].connections[.NORTH] = true
			current_y += 1
		} else {
			game.floor_layout[current_y][current_x].connections[.NORTH] = true
			game.floor_layout[current_y - 1][current_x].connections[.SOUTH] = true
			current_y -= 1
		}
	}
}

place_lock_and_key_on_path :: proc(start_x, start_y, end_x, end_y: i32) {
	key_x := start_x + (end_x - start_x) / 2
	key_y := start_y + (end_y - start_y) / 2

	if key_x == start_x && key_y == start_y {
		if end_x != start_x {
			key_x = start_x + 1
		} else {
			key_y = start_y + 1
		}
	}

	if key_x == end_x && key_y == end_y {
		if end_x != start_x {
			key_x = end_x - 1
		} else {
			key_y = end_y - 1
		}
	}

	if game.floor_number == 1 && (key_x == 1 && key_y == 1) do return
	if game.floor_number == 1 && (key_x == 2 && key_y == 1) do return

	key_room := &game.floor_layout[key_y][key_x]
	key_room.tiles[ROOM_CENTRE][ROOM_CENTRE - 1] = .KEY

	lock_x := key_x
	lock_y := key_y
	if key_x < end_x {
		lock_x += 1
		game.floor_layout[key_y][key_x].locked_exits[.EAST] = true
		game.floor_layout[key_y][lock_x].locked_exits[.WEST] = true
	} else if key_x > end_x {
		lock_x -= 1
		game.floor_layout[key_y][key_x].locked_exits[.WEST] = true
		game.floor_layout[key_y][lock_x].locked_exits[.EAST] = true
	} else if key_y < end_y {
		lock_y += 1
		game.floor_layout[key_y][key_x].locked_exits[.SOUTH] = true
		game.floor_layout[lock_y][key_x].locked_exits[.NORTH] = true
	} else if key_y > end_y {
		lock_y -= 1
		game.floor_layout[key_y][key_x].locked_exits[.NORTH] = true
		game.floor_layout[lock_y][key_x].locked_exits[.SOUTH] = true
	}
}

place_sword_and_shield :: proc(start_x, start_y, end_x, end_y: i32) {
	valid_rooms: [dynamic]Vec2
	defer delete(valid_rooms)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if room_exists(i32(x), i32(y)) {
				is_title := game.floor_number == 1 && x == 1 && y == 1
				is_options := game.floor_number == 1 && x == 2 && y == 1
				is_start := i32(x) == start_x && i32(y) == start_y
				is_end := i32(x) == end_x && i32(y) == end_y

				if !is_title && !is_options && !is_start && !is_end {
					append(&valid_rooms, Vec2{i32(x), i32(y)})
				}
			}
		}
	}

	if len(valid_rooms) >= 2 {
		sword_room_idx := rand.int31() % i32(len(valid_rooms))
		sword_room_pos := valid_rooms[sword_room_idx]
		sword_room := &game.floor_layout[sword_room_pos.y][sword_room_pos.x]

		sword_x := 1 + rand.int31() % (ROOM_SIZE - 2)
		sword_y := 1 + rand.int31() % (ROOM_SIZE - 2)
		for sword_room.tiles[sword_y][sword_x] != .GRASS {
			sword_x = 1 + rand.int31() % (ROOM_SIZE - 2)
			sword_y = 1 + rand.int31() % (ROOM_SIZE - 2)
		}
		sword_room.tiles[sword_y][sword_x] = .SWORD

		shield_room_idx: i32
		for shield_room_idx == sword_room_idx {
			shield_room_idx = rand.int31() % i32(len(valid_rooms))
		}
		shield_room_pos := valid_rooms[shield_room_idx]
		shield_room := &game.floor_layout[shield_room_pos.y][shield_room_pos.x]

		shield_x := 1 + rand.int31() % (ROOM_SIZE - 2)
		shield_y := 1 + rand.int31() % (ROOM_SIZE - 2)
		for shield_room.tiles[shield_y][shield_x] != .GRASS {
			shield_x = 1 + rand.int31() % (ROOM_SIZE - 2)
			shield_y = 1 + rand.int31() % (ROOM_SIZE - 2)
		}
		shield_room.tiles[shield_y][shield_x] = .SHIELD
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
	is_end := room_x == end_x && room_y == end_y

	if is_end {
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

generate_room_enemies :: proc(room: ^Room, room_x, room_y, start_x, start_y, end_x, end_y: i32) {
	is_title := game.floor_number == 1 && room_x == 1 && room_y == 1
	is_options := game.floor_number == 1 && room_x == 2 && room_y == 1
	is_start := room_x == start_x && room_y == start_y
	is_end := room_x == end_x && room_y == end_y

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
