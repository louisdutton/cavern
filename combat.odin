package main

import "core:math/rand"
import rl "vendor:raylib"

init_battle :: proc(enemy_x, enemy_y: i32) {
	game.state = .BATTLE
	game.battle_grid.size = 8
	game.battle_grid.turn = 0
	clear(&game.battle_grid.entities)
	clear(&game.battle_grid.attack_indicators)
	clear(&game.battle_grid.damage_indicators)
	game.battle_grid.screen_shake = 0

	append(
		&game.battle_grid.entities,
		BattleEntity{x = 2, y = 6, is_player = true, health = 3, max_health = 3},
	)

	enemy_count := 2 + (len(game.enemies) % 3)
	enemy_positions := [][2]i32{{5, 1}, {1, 1}, {6, 2}, {0, 3}, {7, 4}, {3, 0}, {4, 7}, {6, 6}}

	for i in 0 ..< enemy_count {
		if i < len(enemy_positions) {
			pos := enemy_positions[i]
			append(
				&game.battle_grid.entities,
				BattleEntity{x = pos.x, y = pos.y, is_player = false, health = 2, max_health = 2},
			)
		}
	}
}

end_battle :: proc() {
	game.state = .EXPLORATION

	for i := len(game.enemies) - 1; i >= 0; i -= 1 {
		if game.enemies[i].x == game.player.x && game.enemies[i].y == game.player.y {
			ordered_remove(&game.enemies, i)
			break
		}
	}

	current_room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
	current_room.has_enemies = false

	clear(&game.battle_grid.entities)
	clear(&game.battle_grid.attack_indicators)
	clear(&game.battle_grid.damage_indicators)
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

update_enemy_ai :: proc(enemy: ^BattleEntity) {
	player_entity: ^BattleEntity
	for &entity in game.battle_grid.entities {
		if entity.is_player {
			player_entity = &entity
			break
		}
	}

	if player_entity == nil do return

	if enemy.is_telegraphing {
		target := get_battle_entity_at(enemy.target_x, enemy.target_y)
		if target != nil && target.is_player {
			target.health -= 1
			spawn_damage_indicator(enemy.target_x, enemy.target_y)
			add_screen_shake(14)

			play_sound(.CLICK)
		}
		enemy.is_telegraphing = false

		for i := len(game.battle_grid.attack_indicators) - 1; i >= 0; i -= 1 {
			indicator := game.battle_grid.attack_indicators[i]
			if indicator.x == enemy.target_x && indicator.y == enemy.target_y {
				ordered_remove(&game.battle_grid.attack_indicators, i)
				break
			}
		}
	} else {
		dx := player_entity.x - enemy.x
		dy := player_entity.y - enemy.y

		if abs(dx) + abs(dy) <= 1 && rand.int31() % 2 == 0 {
			if is_battle_position_valid(player_entity.x, player_entity.y) {
				enemy.is_telegraphing = true
				enemy.target_x = player_entity.x
				enemy.target_y = player_entity.y
				append(
					&game.battle_grid.attack_indicators,
					[2]i32{player_entity.x, player_entity.y},
				)
				return
			}
		}

		if rand.int31() % 4 != 0 {
			new_x := enemy.x
			new_y := enemy.y

			if abs(dx) > abs(dy) {
				if dx > 0 {
					new_x += 1
				} else if dx < 0 {
					new_x -= 1
				}
			} else {
				if dy > 0 {
					new_y += 1
				} else if dy < 0 {
					new_y -= 1
				}
			}

			if is_battle_position_valid(new_x, new_y) &&
			   get_battle_entity_at(new_x, new_y) == nil {
				enemy.x = new_x
				enemy.y = new_y
			}
		}
	}
}

update_battle :: proc() {
	for &entity in game.battle_grid.entities {
		if entity.flash_timer > 0 {
			entity.flash_timer -= 1
			if entity.flash_timer < 0 {
				entity.flash_timer = 0
			}
		}
	}

	game.move_timer -= 1
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
		target.flash_timer = 2
		spawn_damage_indicator(target.x, target.y)
		add_screen_shake(19)

		play_sound(.HURT)

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
		player_entity.x = new_x
		player_entity.y = new_y
		game.move_timer = MOVE_DELAY

		play_sound(.DESTROY)
	}

	enemy_count := 0
	for entity in game.battle_grid.entities {
		if !entity.is_player {
			enemy_count += 1
		}
	}
	for &enemy in game.battle_grid.entities {
		if !enemy.is_player {
			update_enemy_ai(&enemy)
		}
	}

	for i := len(game.battle_grid.entities) - 1; i >= 0; i -= 1 {
		entity := &game.battle_grid.entities[i]
		if entity.is_player && entity.health <= 0 {
			init_game()
			return
		}
	}

	enemy_count = 0
	for entity in game.battle_grid.entities {
		if !entity.is_player {
			enemy_count += 1
		}
	}
	if enemy_count == 0 {
		end_battle()
	}
}
