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
	id:             int,
	using position: Vec2,
	connections:    [Direction]bool,
	locked_exits:   [Direction]bool,
	tiles:          [ROOM_SIZE][ROOM_SIZE]Tile,
}

rand_vec2 :: proc(n: int) -> Vec2 {
	return {rand.int_max(n), rand.int_max(n)}
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

	start := rand_vec2(FLOOR_SIZE)
	end := rand_vec2(FLOOR_SIZE)
	min_distance := 3
	for (end.x == start.x && end.y == start.y) ||
	    (abs(end.x - start.x) + abs(end.y - start.y) < min_distance) {
		end = rand_vec2(FLOOR_SIZE)
	}

	create_path_start_to_end(start, end)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if room_exists({x, y}) {
				room := &game.floor_layout[y][x]
				generate_room_tiles(room, start, end)
				generate_room_enemies(room, start, end)
				place_room_locked_doors(room)
			}
		}
	}

	place_lock_and_key_on_path(start, end)
	place_sword_and_shield(start, end)
	game.room_coords = start
}

room_exists :: proc(pos: Vec2) -> bool {
	if !is_in_bounds(pos, FLOOR_SIZE) do return false
	room := &game.floor_layout[pos.y][pos.x]
	return(
		room.connections[.UP] ||
		room.connections[.DOWN] ||
		room.connections[.RIGHT] ||
		room.connections[.LEFT] \
	)
}

create_path_start_to_end :: proc(start, end: Vec2) {
	current := start

	for current.x != end.x {
		if current.x < end.x {
			game.floor_layout[current.y][current.x].connections[.RIGHT] = true
			game.floor_layout[current.y][current.x + 1].connections[.LEFT] = true
			current.x += 1
		} else {
			game.floor_layout[current.y][current.x].connections[.LEFT] = true
			game.floor_layout[current.y][current.x - 1].connections[.RIGHT] = true
			current.x -= 1
		}
	}

	for current.y != end.y {
		if current.y < end.y {
			game.floor_layout[current.y][current.x].connections[.DOWN] = true
			game.floor_layout[current.y + 1][current.x].connections[.UP] = true
			current.y += 1
		} else {
			game.floor_layout[current.y][current.x].connections[.UP] = true
			game.floor_layout[current.y - 1][current.x].connections[.DOWN] = true
			current.y -= 1
		}
	}
}

place_lock_and_key_on_path :: proc(start, end: Vec2) {
	key := start + (end - start) / 2

	if key == start {
		if end.x != start.x {
			key = start.x + 1
		} else {
			key.y = start.y + 1
		}
	}

	if key == end {
		if end.x != start.x {
			key = end.x - 1
		} else {
			key.y = end.y - 1
		}
	}

	key_room := &game.floor_layout[key.y][key.x]
	key_room.tiles[ROOM_CENTRE][ROOM_CENTRE - 1] = .KEY

	lock := key
	if key.x < end.x {
		lock.x += 1
		game.floor_layout[key.y][key.x].locked_exits[.RIGHT] = true
		game.floor_layout[key.y][lock.x].locked_exits[.LEFT] = true
	} else if key.x > end.x {
		lock.x -= 1
		game.floor_layout[key.y][key.x].locked_exits[.LEFT] = true
		game.floor_layout[key.y][lock.x].locked_exits[.RIGHT] = true
	} else if key.y < end.y {
		lock.y += 1
		game.floor_layout[key.y][key.x].locked_exits[.DOWN] = true
		game.floor_layout[lock.y][key.x].locked_exits[.UP] = true
	} else if key.y > end.y {
		lock.y -= 1
		game.floor_layout[key.y][key.x].locked_exits[.UP] = true
		game.floor_layout[lock.y][key.x].locked_exits[.DOWN] = true
	}
}

place_sword_and_shield :: proc(start, end: Vec2) {
	valid_rooms: [dynamic]Vec2
	defer delete(valid_rooms)

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			p := Vec2{x, y}
			if room_exists(p) && p != start && p != end {
				append(&valid_rooms, p)
			}
		}
	}

	if len(valid_rooms) >= 2 {
		sword_room_idx := rand.int_max(len(valid_rooms))
		sword_room_pos := valid_rooms[sword_room_idx]
		sword_room := &game.floor_layout[sword_room_pos.y][sword_room_pos.x]

		// TODO: support supplying min to rand_vec2()
		sword := rand_vec2(ROOM_SIZE - 2) + {1, 1}
		for sword_room.tiles[sword.y][sword.x] != .GRASS {
			sword = rand_vec2(ROOM_SIZE - 2) + {1, 1}
		}
		sword_room.tiles[sword.y][sword.x] = .SWORD

		shield_room_idx: int
		for shield_room_idx == sword_room_idx {
			shield_room_idx = rand.int_max(len(valid_rooms))
		}
		shield_room_pos := valid_rooms[shield_room_idx]
		shield_room := &game.floor_layout[shield_room_pos.y][shield_room_pos.x]

		shield := rand_vec2(ROOM_SIZE - 2) + {1, 1}
		for shield_room.tiles[shield.y][shield.x] != .GRASS {
			shield = rand_vec2(ROOM_SIZE - 2) + {1, 1}
		}
		shield_room.tiles[shield.y][shield.x] = .SHIELD
	}
}


generate_room_tiles :: proc(room: ^Room, start, end: Vec2) {
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

	if room.connections[.UP] {
		room.tiles[0][ROOM_CENTRE - 1] = .GRASS
		room.tiles[0][ROOM_CENTRE] = .GRASS
	}
	if room.connections[.DOWN] {
		room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .GRASS
		room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .GRASS
	}
	if room.connections[.LEFT] {
		room.tiles[ROOM_CENTRE - 1][0] = .GRASS
		room.tiles[ROOM_CENTRE][0] = .GRASS
	}
	if room.connections[.RIGHT] {
		room.tiles[ROOM_CENTRE - 1][ROOM_SIZE - 1] = .GRASS
		room.tiles[ROOM_CENTRE][ROOM_SIZE - 1] = .GRASS
	}

	switch room {
	case start: // no-op
	case end: room.tiles[ROOM_CENTRE][ROOM_CENTRE] = .EXIT
	case:
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

generate_room_enemies :: proc(room: ^Room, start, end: Vec2) {
	is_start := room.position == start
	is_end := room.position == end

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

place_room_locked_doors :: proc(room: ^Room) {
	door_key := [3]int{room.x, room.y, 0}

	if room.locked_exits[.UP] {
		door_key.z = int(Direction.UP)
		if !game.unlocked_doors[door_key] {
			room.tiles[0][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[0][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.DOWN] {
		door_key.z = int(Direction.DOWN)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE - 1] = .LOCKED_DOOR
			room.tiles[ROOM_SIZE - 1][ROOM_CENTRE] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.LEFT] {
		door_key.z = int(Direction.LEFT)
		if !game.unlocked_doors[door_key] {
			room.tiles[ROOM_CENTRE - 1][0] = .LOCKED_DOOR
			room.tiles[ROOM_CENTRE][0] = .LOCKED_DOOR
		}
	}
	if room.locked_exits[.RIGHT] {
		door_key.z = int(Direction.RIGHT)
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
				if !room.connections[.UP] && ry > 0 {
					tx := 1 + rand.int_max(TILE_END)
					room.tiles[0][tx] = .SECRET_WALL
				}
				if !room.connections[.DOWN] && ry < FLOOR_END {
					tx := 1 + rand.int_max(TILE_END)
					room.tiles[ROOM_END][tx] = .SECRET_WALL
				}
				if !room.connections[.LEFT] && rx > 0 {
					ty := 1 + rand.int_max(TILE_END)
					room.tiles[ty][0] = .SECRET_WALL
				}
				if !room.connections[.RIGHT] && rx < FLOOR_END {
					ty := 1 + rand.int_max(TILE_END)
					room.tiles[ty][ROOM_END] = .SECRET_WALL
				}
			}
		}
	}
}
