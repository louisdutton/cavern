package main

import "render"
import rl "vendor:raylib"

tile_to_sprite: [Tile]^render.Sprite = {
	.GRASS       = &render.grass_sprite,
	.STONE       = &render.stone_sprite,
	.BOULDER     = &render.boulder_sprite,
	.EXIT        = &render.exit_sprite,
	.KEY         = &render.key_sprite,
	.SWORD       = &render.sword_sprite,
	.SHIELD      = &render.shield_sprite,
	.LOCKED_DOOR = &render.locked_door_sprite,
	.ENEMY       = &render.enemy_sprite,
	.SECRET_WALL = &render.secret_wall_sprite,
}

draw_world :: proc() {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			tile := game.world[y][x]
			sprite := tile_to_sprite[tile]
			render.draw_sprite(sprite, x, y)
		}
	}
}

draw_player :: proc() {
	render.draw_sprite(&render.player_sprite, game.player.x, game.player.y)
}

draw_following_items :: proc() {
	for item in game.following_items {
		sprite := tile_to_sprite[item.item_type]
		render.draw_sprite(sprite, item.x, item.y)
	}
}

draw_floor_number :: proc() {
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
				sprite_x := px * render.TILE_SIZE / digit_width
				sprite_y := py * render.TILE_SIZE / digit_height

				if sprite_x < render.TILE_SIZE && sprite_y < render.TILE_SIZE {
					color_index := render.digit_sprites[digit][sprite_y][sprite_x]
					if color_index != 0 {
						for tile_py in 0 ..< render.TILE_SIZE {
							for tile_px in 0 ..< render.TILE_SIZE {
								pixel_x := i32((digit_x + px) * render.TILE_SIZE + tile_px)
								pixel_y := i32((digit_y + py) * render.TILE_SIZE + tile_py)
								rl.DrawPixel(pixel_x, pixel_y, low_alpha_white)
							}
						}
					}
				}
			}
		}
	}
}
