package main

import smarr "core:container/small_array"
import "render"

INVENTORY_SIZE :: 8

Item :: struct {
	kind:           Tile,
	using position: Vec2,
}

@(private = "file")
inventory: smarr.Small_Array(8, Item)

inventory_draw :: proc() {
	for item in smarr.slice(&inventory) {
		sprite := tile_to_sprite[item.kind]
		render.draw_sprite(sprite, item.position)
	}
}

// Returns the current number of the specified item
// in the players inventory
inventory_get_count :: proc(kind: Tile) -> int {
	count := 0
	for item in smarr.slice(&inventory) {
		if item.kind == kind {
			count += 1
		}
	}
	return count
}

// Returns true if the item was successfully added to inventory
// otherwise the inventory is full and the item could not be added.
inventory_push :: proc(kind: Tile) -> bool {
	return smarr.push(&inventory, Item{kind = kind})
}

// Consumes an item of the specified kind from the inventory
inventory_consume :: proc(kind: Tile) -> bool {
	for item, idx in smarr.slice(&inventory) {
		if item.kind == kind {
			smarr.ordered_remove(&inventory, idx)
			return true
		}
	}

	return false
}

inventory_update :: proc(player_pos: Vec2) {
	prev := player_pos

	for &item in smarr.slice(&inventory) {
		old := item.position
		item.position = prev
		prev = old
	}
}

// collapses the location all items to the given position
inventory_collapse :: proc(pos: Vec2) {
	for &item in smarr.slice(&inventory) {
		item.position = pos
	}
}
