package main

import "core:container/rbtree"
import "render"
import rl "vendor:raylib"

tile_to_sprite: [Tile]^render.Sprite = {
	.GRASS       = &render.spr_grass,
	.STONE       = &render.spr_stone,
	.BOULDER     = &render.spr_boulder,
	.EXIT        = &render.spr_exit,
	.KEY         = &render.spr_key,
	.SWORD       = &render.spr_sword,
	.SHIELD      = &render.spr_shield,
	.LOCKED_DOOR = &render.spr_locked_door,
	.ENEMY       = &render.spr_enemy,
	.SECRET_WALL = &render.spr_secret_wall,
}

draw_world :: proc() {
	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			tile := game.world[y][x]
			sprite := tile_to_sprite[tile]
			render.draw_sprite(sprite, {x, y})
		}
	}
}

draw_player :: proc() {
	render.draw_sprite(&render.spr_player, game.player.position)
}

draw_floor_number :: proc() {
	NUMBER_ALPHA :: 0.05

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
		digit_pos := Vec2{start_x + i * digit_width, start_y}

		for py in 0 ..< digit_height {
			for px in 0 ..< digit_width {
				sprite := Vec2 {
					px * render.TILE_SIZE / digit_width,
					py * render.TILE_SIZE / digit_height,
				}
				if sprite.x >= render.TILE_SIZE || sprite.y >= render.TILE_SIZE do continue

				color_index := render.digit_sprites[digit][sprite.y][sprite.x]
				if color_index == .TRANSPARENT do continue

				for ty in 0 ..< render.TILE_SIZE {
					for tx in 0 ..< render.TILE_SIZE {
						pos := (digit_pos + {px, py}) * render.TILE_SIZE + {tx, ty}
						render.draw_pixel_alpha(pos, .WHITE, NUMBER_ALPHA)
					}
				}
			}
		}
	}
}
