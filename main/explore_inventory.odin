package main

import "render"

Item :: struct {
	kind:           Tile,
	using position: Vec2,
	target:         Vec2,
}

inventory_draw :: proc() {
	for item in game.inventory {
		sprite := tile_to_sprite[item.kind]
		render.draw_sprite(sprite, item.position)
	}
}

// Returns the current number of the specified item
// in the players inventory
inventory_get_count :: proc(kind: Tile) -> int {
	count := 0
	for item in game.inventory {
		if item.kind == kind {
			count += 1
		}
	}
	return count
}

// Consumes an item of the specified kind from the inventory
inventory_consume :: proc(kind: Tile) -> bool {
	for item, idx in game.inventory {
		if item.kind == kind {
			ordered_remove(&game.inventory, idx)
			return true
		}
	}

	return false
}

inventory_update :: proc(player_pos: Vec2) {
	prev := player_pos

	for &item in game.inventory {
		old := item.position
		item.position = prev
		prev = old
	}
}
