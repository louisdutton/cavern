package render

import rl "vendor:raylib"

TILE_SIZE :: 4
COMBAT_TILE_SIZE :: 8

Sprite :: [TILE_SIZE][TILE_SIZE]u8
CombatSprite :: [COMBAT_TILE_SIZE][COMBAT_TILE_SIZE]u8

draw_sprite :: proc(sprite: ^Sprite, position: [2]int, transparent_index: u8 = 0) {
	x0 := position.x * TILE_SIZE
	y0 := position.y * TILE_SIZE

	for py in 0 ..< TILE_SIZE {
		for px in 0 ..< TILE_SIZE {
			color_index := sprite[py][px]
			if color_index != transparent_index {
				rl.DrawPixel(i32(x0 + px), i32(y0 + py), sprite_colors[color_index])
			}
		}
	}
}

draw_combat_sprite :: proc(
	sprite: ^CombatSprite,
	x, y: int,
	transparent_index: u8 = 0,
	flash_white: bool = false,
) {
	for py in 0 ..< COMBAT_TILE_SIZE {
		for px in 0 ..< COMBAT_TILE_SIZE {
			color_index := sprite[py][px]
			if color_index != transparent_index {
				pixel_x := i32(x + px)
				pixel_y := i32(y + py)
				if flash_white {
					rl.DrawPixel(pixel_x, pixel_y, rl.WHITE)
				} else {
					rl.DrawPixel(pixel_x, pixel_y, sprite_colors[color_index])
				}
			}
		}
	}
}

// data

grass_sprite := Sprite{{0, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 0, 1}, {0, 0, 0, 0}}
stone_sprite := Sprite{{1, 1, 2, 1}, {1, 2, 1, 1}, {2, 1, 1, 2}, {1, 1, 2, 1}}
boulder_sprite := Sprite{{2, 2, 2, 2}, {2, 1, 1, 2}, {2, 1, 1, 2}, {2, 2, 2, 2}}
player_sprite := Sprite{{0, 7, 7, 0}, {7, 7, 7, 7}, {7, 7, 7, 7}, {0, 7, 7, 0}}
enemy_sprite := Sprite{{6, 6, 6, 6}, {6, 0, 0, 6}, {6, 0, 0, 6}, {6, 6, 6, 6}}
exit_sprite := Sprite{{8, 8, 8, 8}, {8, 7, 7, 8}, {8, 7, 7, 8}, {8, 8, 8, 8}}
key_sprite := Sprite{{0, 0, 8, 8}, {8, 8, 8, 8}, {8, 0, 8, 0}, {8, 8, 8, 0}}
sword_sprite := Sprite{{0, 0, 0, 6}, {6, 0, 6, 0}, {0, 6, 0, 0}, {6, 0, 6, 0}}
shield_sprite := Sprite{{3, 3, 3, 3}, {3, 3, 3, 3}, {3, 3, 3, 3}, {0, 3, 3, 0}}
locked_door_sprite := Sprite{{4, 4, 4, 4}, {4, 8, 8, 4}, {4, 8, 8, 4}, {4, 4, 4, 4}}
secret_wall_sprite := Sprite{{1, 2, 1, 2}, {2, 1, 2, 1}, {1, 2, 1, 2}, {2, 1, 2, 1}}

digit_sprites := [10]Sprite {
	{{7, 7, 7, 7}, {7, 0, 0, 7}, {7, 0, 0, 7}, {7, 7, 7, 7}},
	{{0, 0, 7, 0}, {0, 7, 7, 0}, {0, 0, 7, 0}, {0, 7, 7, 7}},
	{{7, 7, 7, 7}, {0, 0, 7, 7}, {7, 7, 0, 0}, {7, 7, 7, 7}},
	{{7, 7, 7, 7}, {0, 0, 7, 7}, {0, 0, 7, 7}, {7, 7, 7, 7}},
	{{7, 0, 0, 7}, {7, 0, 0, 7}, {7, 7, 7, 7}, {0, 0, 0, 7}},
	{{7, 7, 7, 7}, {7, 7, 0, 0}, {0, 0, 7, 7}, {7, 7, 7, 7}},
	{{7, 7, 7, 7}, {7, 0, 0, 0}, {7, 7, 7, 7}, {7, 7, 7, 7}},
	{{7, 7, 7, 7}, {0, 0, 0, 7}, {0, 0, 0, 7}, {0, 0, 0, 7}},
	{{7, 7, 7, 7}, {7, 7, 7, 7}, {7, 7, 7, 7}, {7, 7, 7, 7}},
	{{7, 7, 7, 7}, {7, 7, 7, 7}, {0, 0, 7, 7}, {7, 7, 7, 7}},
}


combat_player_sprite := CombatSprite {
	{0, 0, 7, 7, 7, 7, 0, 0},
	{0, 7, 7, 7, 7, 7, 7, 0},
	{7, 7, 7, 7, 7, 7, 7, 7},
	{7, 7, 7, 7, 7, 7, 7, 7},
	{7, 7, 7, 7, 7, 7, 7, 7},
	{7, 7, 7, 7, 7, 7, 7, 7},
	{0, 7, 7, 7, 7, 7, 7, 0},
	{0, 0, 7, 7, 7, 7, 0, 0},
}

combat_enemy_sprite := CombatSprite {
	{6, 6, 6, 6, 6, 6, 6, 6},
	{6, 6, 0, 6, 6, 0, 6, 6},
	{6, 6, 0, 6, 6, 0, 6, 6},
	{6, 6, 6, 6, 6, 6, 6, 6},
	{6, 6, 6, 6, 6, 6, 6, 6},
	{6, 6, 0, 0, 0, 0, 6, 6},
	{6, 6, 6, 0, 0, 6, 6, 6},
	{6, 6, 6, 6, 6, 6, 6, 6},
}

sprite_colors := [9]rl.Color {
	CATPPUCCIN_BASE,
	CATPPUCCIN_SURFACE0,
	CATPPUCCIN_OVERLAY0,
	CATPPUCCIN_BLUE,
	CATPPUCCIN_RED,
	{74, 144, 226, 255},
	{255, 184, 108, 255},
	{255, 255, 255, 255},
	CATPPUCCIN_GREEN,
}
