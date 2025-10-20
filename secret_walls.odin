package main

import "core:math/rand"

place_secret_walls :: proc() {
	for room_y in 0 ..< FLOOR_SIZE {
		for room_x in 0 ..< FLOOR_SIZE {
			room := &game.floor_layout[room_y][room_x]
			if room.id == 0 do continue

			if rand.int31() % 8 == 0 {
				if !room.connections[.NORTH] && room_y > 0 && game.floor_layout[room_y - 1][room_x].id != 0 {
					wall_x := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[0][wall_x] == .STONE {
						room.tiles[0][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.SOUTH] && room_y < FLOOR_SIZE - 1 && game.floor_layout[room_y + 1][room_x].id != 0 {
					wall_x := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[TILES_SIZE - 1][wall_x] == .STONE {
						room.tiles[TILES_SIZE - 1][wall_x] = .SECRET_WALL
					}
				}
				if !room.connections[.WEST] && room_x > 0 && game.floor_layout[room_y][room_x - 1].id != 0 {
					wall_y := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[wall_y][0] == .STONE {
						room.tiles[wall_y][0] = .SECRET_WALL
					}
				}
				if !room.connections[.EAST] && room_x < FLOOR_SIZE - 1 && game.floor_layout[room_y][room_x + 1].id != 0 {
					wall_y := 1 + rand.int31() % (TILES_SIZE - 2)
					if room.tiles[wall_y][TILES_SIZE - 1] == .STONE {
						room.tiles[wall_y][TILES_SIZE - 1] = .SECRET_WALL
					}
				}
			}
		}
	}
}