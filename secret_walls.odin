package main

import "core:math/rand"

place_secret_walls :: proc() {
	for room_y in 0 ..< FLOOR_SIZE {
		for room_x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[room_y][room_x]
			if room.id == 0 do continue

			if rand.int31() % 8 == 0 {
				// Only place secret walls on walls without connections (no doors)
				if !room.connections[.NORTH] {
					wall_x := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[0][wall_x] == .STONE {
						room.tiles[0][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.SOUTH] {
					wall_x := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[TILES_SIZE - 1][wall_x] == .STONE {
						room.tiles[TILES_SIZE - 1][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.WEST] {
					wall_y := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[wall_y][0] == .STONE {
						room.tiles[wall_y][0] = .SECRET_WALL
					}
				}
				if !room.connections[.EAST] {
					wall_y := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[wall_y][TILES_SIZE - 1] == .STONE {
						room.tiles[wall_y][TILES_SIZE - 1] = .SECRET_WALL
					}
				}
			}
		}
	}
}