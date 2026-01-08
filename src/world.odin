package main

import "render"

world_draw :: proc() {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			tile := world_get({x, y})
			sprite := tile_to_sprite[tile]
			render.draw_sprite(sprite, {x, y})
		}
	}

	render.draw_rect({2, 2}, {ROOM_SIZE, ROOM_SIZE} - 4, .WHITE, 0.02)
	render.draw_rect({3, 3}, {ROOM_SIZE, ROOM_SIZE} - 6, .WHITE, 0.02)
	render.draw_rect({4, 4}, {ROOM_SIZE, ROOM_SIZE} - 8, .WHITE, 0.02)
}

// Gets the tile at position
world_get :: proc(pos: Vec2) -> Tile {
	assert(is_in_bounds(pos))
	return game.world[pos.y][pos.x]
}

// Sets the tile at position
world_set :: proc(pos: Vec2, tile: Tile) {
	assert(is_in_bounds(pos))
	game.world[pos.y][pos.x] = tile
}
