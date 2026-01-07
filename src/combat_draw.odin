package main

import "render"

draw_combat_grid :: proc() {
	grid_size := GAME_SIZE / game.combat.size

	for y in 0 ..< game.combat.size {
		for x in 0 ..< game.combat.size {
			tile_x := x * grid_size
			tile_y := y * grid_size

			for py in 0 ..< grid_size {
				for px in 0 ..< grid_size {
					render.draw_pixel(
						{tile_x + px, tile_y + py},
						(x + y) % 2 == 0 ? .SURFACE : .BASE,
					)
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
				render.draw_pixel({pixel_x + px, pixel_y + py}, .RED)
			}
		}
	}

	for damage in game.combat.damage_indicators {
		pixel_x := damage.x * grid_size
		pixel_y := damage.y * grid_size
		alpha := f32(damage.life) / f32(damage.max_life)

		for py in 0 ..< grid_size {
			for px in 0 ..< grid_size {
				if (px + py) % 2 == 0 {
					render.draw_pixel_alpha({pixel_x + px, pixel_y + py}, .RED, alpha)
				}
			}
		}
	}

	for entity in game.combat.entities {
		pos := entity.position * grid_size

		if entity.is_player {
			render.draw_combat_sprite(&render.combat_player_sprite, pos)

			for i in 0 ..< entity.health {
				heart := pos + {i * 2, -3}
				if heart.x >= 0 && heart.x < GAME_SIZE && heart.y >= 0 {
					render.draw_pixel(heart, .GREEN)
				}
			}
		} else {
			flash_white := entity.flash_timer > 0
			render.draw_combat_sprite(&render.combat_enemy_sprite, pos, flash_white)
		}
	}
}
