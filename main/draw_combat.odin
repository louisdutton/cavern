package main

import "render"
import rl "vendor:raylib"

draw_combat_grid :: proc() {
	grid_size := GAME_SIZE / game.combat.size

	for y in 0 ..< game.combat.size {
		for x in 0 ..< game.combat.size {
			tile_x := x * grid_size
			tile_y := y * grid_size

			for py in 0 ..< grid_size {
				for px in 0 ..< grid_size {
					pixel_x := i32(tile_x + px)
					pixel_y := i32(tile_y + py)

					if (x + y) % 2 == 0 {
						rl.DrawPixel(pixel_x, pixel_y, render.CATPPUCCIN_SURFACE0)
					} else {
						rl.DrawPixel(pixel_x, pixel_y, render.CATPPUCCIN_BASE)
					}
				}
			}
		}
	}
}

draw_combat_entities :: proc() {
	grid_size := GAME_SIZE / game.combat.size

	for indicator in game.combat.attack_indicators {
		pixel_x := indicator.x * grid_size
		pixel_y := indicator.y * grid_size

		for py in 0 ..< grid_size {
			for px in 0 ..< grid_size {
				rl.DrawPixel(i32(pixel_x + px), i32(pixel_y + py), render.CATPPUCCIN_RED)
			}
		}
	}

	for damage in game.combat.damage_indicators {
		pixel_x := damage.x * grid_size
		pixel_y := damage.y * grid_size
		alpha := f32(damage.life) / f32(damage.max_life)
		damage_color := rl.ColorAlpha(render.CATPPUCCIN_RED, alpha)

		for py in 0 ..< grid_size {
			for px in 0 ..< grid_size {
				if (px + py) % 2 == 0 {
					rl.DrawPixel(i32(pixel_x + px), i32(pixel_y + py), damage_color)
				}
			}
		}
	}

	for entity in game.combat.entities {
		pixel_x := entity.x * grid_size
		pixel_y := entity.y * grid_size

		if entity.is_player {
			render.draw_combat_sprite(&render.combat_player_sprite, pixel_x, pixel_y, 0)

			for i in 0 ..< entity.health {
				heart_x := i32(pixel_x + i * 2)
				heart_y := i32(pixel_y - 3)
				if heart_x >= 0 && heart_x < GAME_SIZE && heart_y >= 0 {
					rl.DrawPixel(heart_x, heart_y, render.CATPPUCCIN_GREEN)
				}
			}
		} else {
			flash_white := entity.flash_timer > 0
			render.draw_combat_sprite(
				&render.combat_enemy_sprite,
				pixel_x,
				pixel_y,
				0,
				flash_white,
			)
		}
	}
}
