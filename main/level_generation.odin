package main

import "core:math/rand"

FLOOR_SIZE :: 5 // equalateral length of a floor
ROOM_COUNT :: FLOOR_SIZE * FLOOR_SIZE // max rooms in a floor
ROOM_SIZE :: 16 // equalateral length of a room in tiles
ROOM_CENTRE :: ROOM_SIZE / 2 // the centerpoint of a room
TILE_COUNT :: ROOM_SIZE * ROOM_SIZE // number of tiles in a room

Vec2 :: [2]int

Tile :: enum {
	GRASS,
	STONE,
	BOULDER,
	EXIT,
	KEY,
	SWORD,
	SHIELD,
	LOCKED_DOOR,
	SECRET_WALL,
	ENEMY,
}

Room :: struct {
	id:           int,
	x, y:         int,
	connections:  [Direction]bool,
	locked_exits: [Direction]bool,
	tiles:        [ROOM_SIZE][ROOM_SIZE]Tile,
}

generate_floor :: proc() {
	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			game.floor_layout[y][x] = Room {
				id = y * FLOOR_SIZE + x,
				x  = x,
				y  = y,
			}
		}
	}

	start_x, start_y: int
	end_x, end_y: int

	start_x = rand.int_max(FLOOR_SIZE)
	start_y = rand.int_max(FLOOR_SIZE)

	end_x = rand.int_max(FLOOR_SIZE)
	end_y = rand.int_max(FLOOR_SIZE)
	min_distance := 3
	for (end_x == start_x && end_y == start_y) ||
	    (abs(end_x - start_x) + abs(end_y - start_y) < min_distance) {
		end_x = rand.int_max(FLOOR_SIZE)
		end_y = rand.int_max(FLOOR_SIZE)
	}

	create_path_start_to_end(start_x, start_y, end_x, end_y)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if room_exists(x, y) {
				room := &game.floor_layout[y][x]
				generate_room_tiles(room, x, y, start_x, start_y, end_x, end_y)
				generate_room_enemies(room, x, y, start_x, start_y, end_x, end_y)
				place_room_locked_doors(room, x, y)
			}
		}
	}

	place_lock_and_key_on_path(start_x, start_y, end_x, end_y)
	place_sword_and_shield(start_x, start_y, end_x, end_y)

	game.room_coords = {start_x, start_y}
}

room_exists :: proc(x, y: int) -> bool {
	if x < 0 || x >= FLOOR_SIZE || y < 0 || y >= FLOOR_SIZE do return false
	room := &game.floor_layout[y][x]
	return(
		room.connections[.NORTH] ||
		room.connections[.SOUTH] ||
		room.connections[.EAST] ||
		room.connections[.WEST] \
	)
}

create_path_start_to_end :: proc(start_x, start_y, end_x, end_y: int) {
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

place_lock_and_key_on_path :: proc(start_x, start_y, end_x, end_y: int) {
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

place_sword_and_shield :: proc(start_x, start_y, end_x, end_y: int) {
	valid_rooms: [dynamic]Vec2
	defer delete(valid_rooms)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if room_exists(x, y) {
				is_start := x == start_x && y == start_y
				is_end := x == end_x && y == end_y

				if !is_start && !is_end {
					append(&valid_rooms, Vec2{x, y})
				}
			}
		}
	}

	if len(valid_rooms) >= 2 {
		sword_room_idx := rand.int_max(len(valid_rooms))
		sword_room_pos := valid_rooms[sword_room_idx]
		sword_room := &game.floor_layout[sword_room_pos.y][sword_room_pos.x]

		sword_x := 1 + rand.int_max(ROOM_SIZE - 2)
		sword_y := 1 + rand.int_max(ROOM_SIZE - 2)
		for sword_room.tiles[sword_y][sword_x] != .GRASS {
			sword_x = 1 + rand.int_max(ROOM_SIZE - 2)
			sword_y = 1 + rand.int_max(ROOM_SIZE - 2)
		}
		sword_room.tiles[sword_y][sword_x] = .SWORD

		shield_room_idx: int
		for shield_room_idx == sword_room_idx {
			shield_room_idx = rand.int_max(len(valid_rooms))
		}
		shield_room_pos := valid_rooms[shield_room_idx]
		shield_room := &game.floor_layout[shield_room_pos.y][shield_room_pos.x]

		shield_x := 1 + rand.int_max(ROOM_SIZE - 2)
		shield_y := 1 + rand.int_max(ROOM_SIZE - 2)
		for shield_room.tiles[shield_y][shield_x] != .GRASS {
			shield_x = 1 + rand.int_max(ROOM_SIZE - 2)
			shield_y = 1 + rand.int_max(ROOM_SIZE - 2)
		}
		shield_room.tiles[shield_y][shield_x] = .SHIELD
	}
}


generate_room_tiles :: proc(room: ^Room, room_x, room_y, start_x, start_y, end_x, end_y: int) {
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

	is_start := room_x == start_x && room_y == start_y
	is_end := room_x == end_x && room_y == end_y

	if is_end {
		room.tiles[ROOM_CENTRE][ROOM_CENTRE] = .EXIT
	} else if !is_start {
		boulder_count := 2 + (room.id % 3)
		for _ in 0 ..< boulder_count {
			boulder_x := 1 + rand.int_max(ROOM_SIZE - 2)
			boulder_y := 1 + rand.int_max(ROOM_SIZE - 2)
			if room.tiles[boulder_y][boulder_x] == .GRASS {
				room.tiles[boulder_y][boulder_x] = .BOULDER
			}
		}
	}

}

generate_room_enemies :: proc(room: ^Room, room_x, room_y, start_x, start_y, end_x, end_y: int) {
	is_start := room_x == start_x && room_y == start_y
	is_end := room_x == end_x && room_y == end_y

	if !is_start && !is_end && rand.int_max(3) == 0 {
		enemy_count := 2 + (room.id % 3)
		for _ in 0 ..< enemy_count {
			enemy_x := 1 + rand.int_max(ROOM_SIZE - 2)
			enemy_y := 1 + rand.int_max(ROOM_SIZE - 2)
			if room.tiles[enemy_y][enemy_x] == .GRASS {
				room.tiles[enemy_y][enemy_x] = .ENEMY
			}
		}
	}
}

place_room_locked_doors :: proc(room: ^Room, room_x, room_y: int) {
	door_key := [3]int{room_x, room_y, 0}

	if room.locked_exits[.NORTH] {
		door_key.z = int(Direction.NORTH)
		if !game.unlocked_doors[door_key] {
			room.tiles[0][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[0][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.SOUTH] {
		door_key.z = int(Direction.SOUTH)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.WEST] {
		door_key.z = int(Direction.WEST)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_CENTRE - 1][0] = .LOCKED_DOOR
			room.tiles[ROOM_CENTRE][0] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.EAST] {
		door_key.z = int(Direction.EAST)
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
					tx := 1 + rand.int_max(TILE_END)
					room.tiles[0][tx] = .SECRET_WALL
				}
				if !room.connections[.SOUTH] && ry < FLOOR_END {
					tx := 1 + rand.int_max(TILE_END)
					room.tiles[ROOM_END][tx] = .SECRET_WALL
				}
				if !room.connections[.WEST] && rx > 0 {
					ty := 1 + rand.int_max(TILE_END)
					room.tiles[ty][0] = .SECRET_WALL
				}
				if !room.connections[.EAST] && rx < FLOOR_END {
					ty := 1 + rand.int_max(TILE_END)
					room.tiles[ty][ROOM_END] = .SECRET_WALL
				}
			}
		}
	}
}
