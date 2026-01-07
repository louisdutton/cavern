package main

import "core:math/rand"

update_enemies :: proc() {
	game.enemy_timer -= 1
	if game.enemy_timer > 0 do return

	for y in 0 ..< ROOM_SIZE {
		for x in 0 ..< ROOM_SIZE {
			if game.world[y][x] == .ENEMY {
				new_x, new_y := x, y

				if rand.int31() % 2 == 0 {
					if rand.int31() % 2 == 0 {
						new_x += (int(rand.int31()) % 2) * 2 - 1
					} else {
						new_y += (int(rand.int31()) % 2) * 2 - 1
					}
				}

				if new_x >= 1 &&
				   new_x < ROOM_SIZE - 1 &&
				   new_y >= 1 &&
				   new_y < ROOM_SIZE - 1 &&
				   game.world[new_y][new_x] == .GRASS {
					game.world[y][x] = .GRASS
					game.world[new_y][new_x] = .ENEMY
				}
			}
		}
	}

	game.enemy_timer = ENEMY_DELAY
}

is_enemy_collision :: proc() -> bool {
	return world_get(game.player.position) == .ENEMY
}
