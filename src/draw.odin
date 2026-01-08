package main

import "render"

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

draw_player :: proc() {
	render.draw_sprite(&render.spr_player, game.player.position)
}
