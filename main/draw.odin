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

draw_battle_sprite :: proc(
	sprite: ^BattleSprite,
	x, y: i32,
	transparent_index: u8 = 255,
	flash_white: bool = false,
) {
	for py in 0 ..< 8 {
		for px in 0 ..< 8 {
			color_index := sprite[py][px]
			if color_index != transparent_index {
				pixel_x := x + i32(px)
				pixel_y := y + i32(py)
				if flash_white {
					rl.DrawPixel(pixel_x, pixel_y, rl.WHITE)
				} else {
					rl.DrawPixel(pixel_x, pixel_y, sprite_colors[color_index])
				}
			}
		}
	}
}

draw_world :: proc() {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			tile_x := i32(x * TILE_SIZE)
			tile_y := i32(y * TILE_SIZE)

			draw_sprite(&grass_sprite, tile_x, tile_y)

			sprite: ^Sprite
			switch game.world[y][x] {
			case .GRASS:
			case .STONE: sprite = &stone_sprite
			case .BOULDER: sprite = &boulder_sprite
			case .EXIT: sprite = &exit_sprite
			case .KEY: sprite = &key_sprite
			case .SWORD: sprite = &sword_sprite
			case .SHIELD: sprite = &shield_sprite
			case .LOCKED_DOOR: sprite = &locked_door_sprite
			case .SECRET_WALL: sprite = &secret_wall_sprite
			case .ENEMY: sprite = &enemy_sprite
			}

			if sprite != nil {
				draw_sprite(sprite, tile_x, tile_y)
			}
		}
	}
}

draw_player :: proc() {
	pixel_x := game.player.x * TILE_SIZE
	pixel_y := game.player.y * TILE_SIZE
	draw_sprite(&player_sprite, pixel_x, pixel_y, 0)
}


draw_following_items :: proc() {
	for item in game.following_items {
		pixel_x := item.x * TILE_SIZE
		pixel_y := item.y * TILE_SIZE

		sprite: ^Sprite
		#partial switch item.item_type {
		case .KEY: sprite = &key_sprite
		case .SWORD: sprite = &sword_sprite
		case .SHIELD: sprite = &shield_sprite
		}

		if sprite != nil {
			draw_sprite(sprite, pixel_x, pixel_y, 0)
		}
	}
}


draw_floor_number :: proc() {
	if game.floor_number == 1 && game.room_coords.x == 1 && game.room_coords.y == 1 {
		floor_str := [16]u8{}
	floor_len := 0
	num := game.floor_number

	if num == 0 {
		floor_str[0] = 0
		floor_len = 1
	} else {
		temp_num := num
		for temp_num > 0 {
			floor_str[floor_len] = u8(temp_num % 10)
			temp_num /= 10
			floor_len += 1
		}

		for i in 0 ..< floor_len / 2 {
			temp := floor_str[i]
			floor_str[i] = floor_str[floor_len - 1 - i]
			floor_str[floor_len - 1 - i] = temp
		}
	}

	digit_width := 8
	digit_height := 8
	total_width := floor_len * digit_width
	start_x := ROOM_CENTRE - total_width / 2
	start_y := ROOM_CENTRE - digit_height / 2

	low_alpha_white := rl.Fade(rl.WHITE, 0.05)

	for i in 0 ..< floor_len {
		digit := floor_str[i]
		digit_x := start_x + i * digit_width
		digit_y := start_y

		for py in 0 ..< digit_height {
			for px in 0 ..< digit_width {
				sprite_x := px * TILE_SIZE / digit_width
				sprite_y := py * TILE_SIZE / digit_height

				if sprite_x < TILE_SIZE && sprite_y < TILE_SIZE {
					color_index := digit_sprites[digit][sprite_y][sprite_x]
					if color_index != 0 {
						for tile_py in 0 ..< TILE_SIZE {
							for tile_px in 0 ..< TILE_SIZE {
								pixel_x := i32((digit_x + px) * TILE_SIZE + tile_px)
								pixel_y := i32((digit_y + py) * TILE_SIZE + tile_py)
								rl.DrawPixel(pixel_x, pixel_y, low_alpha_white)
							}
						}
					}
				}
			}
		}
	}
	}
}

draw_battle_grid :: proc() {
	grid_size := i32(GAME_SIZE / game.battle_grid.size)

	for y in 0 ..< game.battle_grid.size {
		for x in 0 ..< game.battle_grid.size {
			tile_x := x * grid_size
			tile_y := y * grid_size

			for py in 0 ..< grid_size {
				for px in 0 ..< grid_size {
					pixel_x := tile_x + px
					pixel_y := tile_y + py

					if (x + y) % 2 == 0 {
						rl.DrawPixel(pixel_x, pixel_y, CATPPUCCIN_SURFACE0)
					} else {
						rl.DrawPixel(pixel_x, pixel_y, CATPPUCCIN_BASE)
					}
				}
			}
		}
	}
}

draw_battle_entities :: proc() {
	grid_size := i32(GAME_SIZE / game.battle_grid.size)

	for indicator in game.battle_grid.attack_indicators {
		pixel_x := indicator.x * grid_size
		pixel_y := indicator.y * grid_size

		for py in 0 ..< grid_size {
			for px in 0 ..< grid_size {
				rl.DrawPixel(pixel_x + px, pixel_y + py, CATPPUCCIN_RED)
			}
		}
	}

	for damage in game.battle_grid.damage_indicators {
		pixel_x := damage.x * grid_size
		pixel_y := damage.y * grid_size
		life_ratio := damage.life / damage.max_life
		alpha := u8(life_ratio * 255)

		for py in 0 ..< grid_size {
			for px in 0 ..< grid_size {
				if (px + py) % 2 == 0 {
					damage_color := rl.Color {
						CATPPUCCIN_RED.r,
						CATPPUCCIN_RED.g,
						CATPPUCCIN_RED.b,
						alpha,
					}
					rl.DrawPixel(pixel_x + px, pixel_y + py, damage_color)
				}
			}
		}
	}

	for entity in game.battle_grid.entities {
		pixel_x := entity.x * grid_size
		pixel_y := entity.y * grid_size

		if entity.is_player {
			draw_battle_sprite(&battle_player_sprite, pixel_x, pixel_y, 0)

			for i in 0 ..< entity.health {
				heart_x := pixel_x + i * 2
				heart_y := pixel_y - 3
				if heart_x >= 0 && heart_x < GAME_SIZE && heart_y >= 0 {
					rl.DrawPixel(heart_x, heart_y, CATPPUCCIN_GREEN)
				}
			}
		} else {
			flash_white := entity.flash_timer > 0
			draw_battle_sprite(&battle_enemy_sprite, pixel_x, pixel_y, 0, flash_white)
		}
	}
}
