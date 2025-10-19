package main

import rl "vendor:raylib"

init_battle :: proc(enemy_x, enemy_y: i32) {
	game.state = .BATTLE
	game.battle_grid.size = 8
	game.battle_grid.turn = 0
	clear(&game.battle_grid.entities)

	append(&game.battle_grid.entities, BattleEntity{
		x = 2, y = 6, is_player = true, health = 3, max_health = 3,
	})

	append(&game.battle_grid.entities, BattleEntity{
		x = 5, y = 1, is_player = false, health = 2, max_health = 2,
	})
}

end_battle :: proc() {
	game.state = .EXPLORATION

	for i := len(game.enemies) - 1; i >= 0; i -= 1 {
		if game.enemies[i].x == game.player.x && game.enemies[i].y == game.player.y {
			ordered_remove(&game.enemies, i)
			break
		}
	}

	clear(&game.battle_grid.entities)
}

get_battle_entity_at :: proc(x, y: i32) -> ^BattleEntity {
	for &entity in game.battle_grid.entities {
		if entity.x == x && entity.y == y {
			return &entity
		}
	}
	return nil
}

is_battle_position_valid :: proc(x, y: i32) -> bool {
	return x >= 0 && x < game.battle_grid.size && y >= 0 && y < game.battle_grid.size
}

update_battle :: proc(dt: f32) {
	game.move_timer -= dt
	if game.move_timer > 0 do return

	player_entity := get_battle_entity_at(-1, -1)
	for &entity in game.battle_grid.entities {
		if entity.is_player {
			player_entity = &entity
			break
		}
	}

	if player_entity == nil do return

	new_x := player_entity.x
	new_y := player_entity.y
	moved := false

	if rl.IsKeyDown(.W) {
		new_y -= 1
		moved = true
	} else if rl.IsKeyDown(.S) {
		new_y += 1
		moved = true
	} else if rl.IsKeyDown(.A) {
		new_x -= 1
		moved = true
	} else if rl.IsKeyDown(.D) {
		new_x += 1
		moved = true
	}

	if !moved do return

	if !is_battle_position_valid(new_x, new_y) do return

	target := get_battle_entity_at(new_x, new_y)
	if target != nil && !target.is_player {
		target.health -= 1
		spawn_dust(target.x, target.y)
		if target.health <= 0 {
			for i := len(game.battle_grid.entities) - 1; i >= 0; i -= 1 {
				if &game.battle_grid.entities[i] == target {
					ordered_remove(&game.battle_grid.entities, i)
					break
				}
			}
		}
		game.move_timer = MOVE_DELAY
		return
	}

	if target == nil {
		spawn_dust(player_entity.x, player_entity.y)
		player_entity.x = new_x
		player_entity.y = new_y
		game.move_timer = MOVE_DELAY

		pitch := 0.8 + f32((player_entity.x + player_entity.y) % 5) * 0.1
		rl.SetSoundPitch(game.click_sound, pitch)
		rl.PlaySound(game.click_sound)
	}

	enemy_count := 0
	for entity in game.battle_grid.entities {
		if !entity.is_player {
			enemy_count += 1
		}
	}
	if enemy_count == 0 {
		end_battle()
	}
}