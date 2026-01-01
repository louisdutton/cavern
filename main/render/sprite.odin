package render

import rl "vendor:raylib"

TILE_SIZE :: 4
COMBAT_TILE_SIZE :: 8

Sprite :: [TILE_SIZE][TILE_SIZE]ThemeColor
CombatSprite :: [COMBAT_TILE_SIZE][COMBAT_TILE_SIZE]ThemeColor
TRANSPARENT :: 0

draw_sprite :: proc(sprite: ^Sprite, position: [2]int) {
	start := position * TILE_SIZE

	for y in 0 ..< TILE_SIZE {
		for x in 0 ..< TILE_SIZE {
			col := sprite[y][x]
			if col == .TRANSPARENT do continue

			draw_pixel(start + {x, y}, col)
		}
	}
}

draw_combat_sprite :: proc(sprite: ^CombatSprite, position: [2]int, flash_white: bool = false) {
	for y in 0 ..< COMBAT_TILE_SIZE {
		for x in 0 ..< COMBAT_TILE_SIZE {
			col := sprite[y][x]
			if col == .TRANSPARENT do continue

			draw_pixel(position + {x, y}, flash_white ? .WHITE : col)
		}
	}
}
