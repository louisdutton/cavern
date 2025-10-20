package main

import "core:math/rand"

generate_room_tiles :: proc(room: ^Room) {
	// Initialize with grass
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			room.tiles[y][x] = .GRASS
		}
	}

	// Generate walls
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			is_wall := false

			if y == 0 && !room.connections[.NORTH] {
				is_wall = true
			} else if y == TILES_SIZE - 1 && !room.connections[.SOUTH] {
				is_wall = true
			} else if x == 0 && !room.connections[.WEST] {
				is_wall = true
			} else if x == TILES_SIZE - 1 && !room.connections[.EAST] {
				is_wall = true
			}

			if y == 0 && room.connections[.NORTH] && (x < CENTRE - 1 || x > CENTRE) {
				is_wall = true
			} else if y == TILES_SIZE - 1 && room.connections[.SOUTH] && (x < CENTRE - 1 || x > CENTRE) {
				is_wall = true
			} else if x == 0 && room.connections[.WEST] && (y < CENTRE - 1 || y > CENTRE) {
				is_wall = true
			} else if x == TILES_SIZE - 1 && room.connections[.EAST] && (y < CENTRE - 1 || y > CENTRE) {
				is_wall = true
			}

			if is_wall {
				room.tiles[y][x] = .STONE
			}
		}
	}

	// Place special tiles
	if room.is_end {
		room.tiles[CENTRE][CENTRE] = .EXIT
	} else if !room.is_start {
		water_count := 2 + (room.id % 3)
		for _ in 0 ..< water_count {
			water_x := 1 + rand.int31() % (TILES_SIZE - 2)
			water_y := 1 + rand.int31() % (TILES_SIZE - 2)
			if room.tiles[water_y][water_x] == .GRASS {
				room.tiles[water_y][water_x] = .WATER
			}
		}
	}

	// Place key if room has one
	if room.has_key {
		key_x := CENTRE - 2 + (room.id % 3)
		key_y := CENTRE - 1 + (room.id % 2)
		room.tiles[key_y][key_x] = .KEY
	}
}