package main

import "core:math/rand"

generate_room_tiles :: proc(room: ^Room) {
	// Initialize with grass
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			room.tiles[y][x] = .GRASS
		}
	}

	// Generate perimeter walls - ALWAYS place walls on all edges
	// Top wall
	for x in 0 ..< TILES_SIZE {
		room.tiles[0][x] = .STONE
	}
	// Bottom wall
	for x in 0 ..< TILES_SIZE {
		room.tiles[TILES_SIZE - 1][x] = .STONE
	}
	// Left wall
	for y in 0 ..< TILES_SIZE {
		room.tiles[y][0] = .STONE
	}
	// Right wall
	for y in 0 ..< TILES_SIZE {
		room.tiles[y][TILES_SIZE - 1] = .STONE
	}

	// Only AFTER walls are guaranteed, create door openings
	if room.connections[.NORTH] {
		room.tiles[0][CENTRE - 1] = .GRASS
		room.tiles[0][CENTRE] = .GRASS
	}
	if room.connections[.SOUTH] {
		room.tiles[TILES_SIZE - 1][CENTRE - 1] = .GRASS
		room.tiles[TILES_SIZE - 1][CENTRE] = .GRASS
	}
	if room.connections[.WEST] {
		room.tiles[CENTRE - 1][0] = .GRASS
		room.tiles[CENTRE][0] = .GRASS
	}
	if room.connections[.EAST] {
		room.tiles[CENTRE - 1][TILES_SIZE - 1] = .GRASS
		room.tiles[CENTRE][TILES_SIZE - 1] = .GRASS
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