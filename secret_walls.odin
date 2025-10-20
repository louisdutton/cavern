package main

import "core:math/rand"

place_secret_walls :: proc() {
	for room_y in 0 ..< FLOOR_SIZE {
		for room_x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[room_y][room_x]
			if room.id == 0 do continue

			if rand.int31() % 8 == 0 {
				if room.connections[.NORTH] {
					wall_x := CENTRE - 1 + rand.int31() % 3
					if wall_x != CENTRE - 1 && wall_x != CENTRE {
						append(&room.secret_walls, [2]i32{wall_x, 0})
					}
				}
				if room.connections[.SOUTH] {
					wall_x := CENTRE - 1 + rand.int31() % 3
					if wall_x != CENTRE - 1 && wall_x != CENTRE {
						append(&room.secret_walls, [2]i32{wall_x, TILES_SIZE - 1})
					}
				}
				if room.connections[.WEST] {
					wall_y := CENTRE - 1 + rand.int31() % 3
					if wall_y != CENTRE - 1 && wall_y != CENTRE {
						append(&room.secret_walls, [2]i32{0, wall_y})
					}
				}
				if room.connections[.EAST] {
					wall_y := CENTRE - 1 + rand.int31() % 3
					if wall_y != CENTRE - 1 && wall_y != CENTRE {
						append(&room.secret_walls, [2]i32{TILES_SIZE - 1, wall_y})
					}
				}
			}
		}
	}
}