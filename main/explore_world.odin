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
