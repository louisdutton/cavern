package main

import rl "vendor:raylib"

Sprite :: [TILE_SIZE][TILE_SIZE]u8

grass_sprite := Sprite{{0, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 0, 1}, {0, 0, 0, 0}}

stone_sprite := Sprite{{1, 1, 2, 1}, {1, 2, 1, 1}, {2, 1, 1, 2}, {1, 1, 2, 1}}

water_sprite_a := Sprite{{3, 3, 5, 5}, {3, 5, 5, 3}, {5, 5, 3, 3}, {5, 3, 3, 5}}

water_sprite_b := Sprite{{5, 5, 3, 3}, {5, 3, 3, 5}, {3, 3, 5, 5}, {3, 5, 5, 3}}

player_sprite := Sprite{{0, 7, 7, 0}, {7, 7, 7, 7}, {7, 7, 7, 7}, {0, 7, 7, 0}}

enemy_sprite := Sprite{{6, 6, 6, 6}, {6, 0, 0, 6}, {6, 0, 0, 6}, {6, 6, 6, 6}}

dust_sprite := Sprite{{0, 2, 0, 2}, {2, 0, 2, 0}, {0, 2, 0, 2}, {2, 0, 2, 0}}

exit_sprite := Sprite{{8, 8, 8, 8}, {8, 7, 7, 8}, {8, 7, 7, 8}, {8, 8, 8, 8}}

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
