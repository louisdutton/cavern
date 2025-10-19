package main

import rl "vendor:raylib"

TILE_SIZE :: 4

draw_sprite :: proc(sprite: ^Sprite, x, y: i32, transparent_index: u8 = 255) {
	for py in 0 ..< TILE_SIZE {
		for px in 0 ..< TILE_SIZE {
			color_index := sprite[py][px]
			if color_index != transparent_index {
				pixel_x := x + i32(px)
				pixel_y := y + i32(py)
				rl.DrawPixel(pixel_x, pixel_y, sprite_colors[color_index])
			}
		}
	}
}

draw_world :: proc() {
	for y in 0 ..< TILES_X {
		for x in 0 ..< TILES_X {
			tile_x := i32(x * TILE_SIZE)
			tile_y := i32(y * TILE_SIZE)

			sprite: ^Sprite
			switch game.world[y][x] {
			case .GRASS: sprite = &grass_sprite
			case .STONE: sprite = &stone_sprite
			case .WATER:
				wave_offset := i32(game.water_time * 4) % 2
				if (i32(x) + i32(y) + wave_offset) % 2 == 0 {
					sprite = &water_sprite_a
				} else {
					sprite = &water_sprite_b
				}
			case .EXIT: sprite = &exit_sprite
			}

			draw_sprite(sprite, tile_x, tile_y)
		}
	}
}

draw_player :: proc() {
	pixel_x := game.player.x * TILE_SIZE
	pixel_y := game.player.y * TILE_SIZE
	draw_sprite(&player_sprite, pixel_x, pixel_y, 0)
}

draw_enemies :: proc() {
	for enemy in game.enemies {
		pixel_x := enemy.x * TILE_SIZE
		pixel_y := enemy.y * TILE_SIZE
		draw_sprite(&enemy_sprite, pixel_x, pixel_y, 0)
	}
}

draw_dust_sprite :: proc(sprite: ^Sprite, x, y: i32, alpha: u8) {
	for py in 0 ..< TILE_SIZE {
		for px in 0 ..< TILE_SIZE {
			color_index := sprite[py][px]
			if color_index != 0 {
				pixel_x := x + i32(px)
				pixel_y := y + i32(py)

				base_color := sprite_colors[color_index]
				dust_color := rl.Color{base_color.r, base_color.g, base_color.b, alpha}

				rl.DrawPixel(pixel_x, pixel_y, dust_color)
			}
		}
	}
}

draw_dust :: proc() {
	for dust in game.dust_particles {
		life_ratio := dust.life / dust.max_life
		alpha_u8 := u8(life_ratio * 255)

		pixel_x := dust.x * TILE_SIZE
		pixel_y := dust.y * TILE_SIZE

		if life_ratio > 0.3 {
			draw_dust_sprite(&dust_sprite, pixel_x, pixel_y, alpha_u8)
		} else {
			dust_color := rl.Color {
				CATPPUCCIN_OVERLAY0.r,
				CATPPUCCIN_OVERLAY0.g,
				CATPPUCCIN_OVERLAY0.b,
				alpha_u8,
			}
			center_x := pixel_x + 2
			center_y := pixel_y + 2
			rl.DrawPixel(center_x, center_y, dust_color)
		}
	}
}
