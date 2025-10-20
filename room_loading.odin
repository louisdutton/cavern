package main

import "core:math/rand"

load_current_room :: proc() {
	clear(&game.enemies)

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	// Copy pre-generated tiles
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			game.world[y][x] = room.tiles[y][x]
		}
	}

	// Generate enemies if room has them
	if room.has_enemies {
		enemy_count := 2 + (room.id % 3)
		for _ in 0 ..< enemy_count {
			enemy_x := rand.int31() % TILES_SIZE
			enemy_y := rand.int31() % TILES_SIZE
			if is_tile_walkable(enemy_x, enemy_y) {
				enemy_direction := (rand.int31() % 2) * 2 - 1
				enemy_axis := u8(rand.int31() % 2)
				min_pos, max_pos: i32
				if enemy_axis == 0 {
					min_pos = max(1, enemy_x - 3)
					max_pos = min(TILES_SIZE - 2, enemy_x + 3)
				} else {
					min_pos = max(1, enemy_y - 3)
					max_pos = min(TILES_SIZE - 2, enemy_y + 3)
				}
				append(
					&game.enemies,
					Enemy {
						x         = enemy_x,
						y         = enemy_y,
						direction = enemy_direction,
						min_pos   = min_pos,
						max_pos   = max_pos,
						axis      = enemy_axis,
					},
				)
			}
		}
	}

	place_locked_doors_at_exits(room)
}