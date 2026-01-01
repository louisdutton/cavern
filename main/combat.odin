package main

import "audio"
import "core:math/rand"
import rl "vendor:raylib"

combat_init :: proc(enemy_x, enemy_y: int) {
	game.state = .COMBAT
	game.combat_grid.size = 8
	game.combat_grid.turn = 0
	clear(&game.combat_grid.entities)
	clear(&game.combat_grid.attack_indicators)
	clear(&game.combat_grid.damage_indicators)
	game.combat_grid.screen_shake = 0

	append(
		&game.combat_grid.entities,
		CombatEntity{x = 2, y = 6, is_player = true, health = 3, max_health = 3},
	)

	enemy_count := 2 + rand.int_max(3)
	enemy_positions := []Vec2{{5, 1}, {1, 1}, {6, 2}, {0, 3}, {7, 4}, {3, 0}, {4, 7}, {6, 6}}

	for i in 0 ..< enemy_count {
		if i < len(enemy_positions) {
			pos := enemy_positions[i]
			append(
				&game.combat_grid.entities,
				CombatEntity{x = pos.x, y = pos.y, is_player = false, health = 2, max_health = 2},
			)
		}
	}
}

combat_fini :: proc() {
	game.state = .EXPLORATION

	defeated_enemy_x, defeated_enemy_y := game.player.x, game.player.y

	game.world[defeated_enemy_y][defeated_enemy_x] = .GRASS
	game.combat_grid.screen_shake = 0

	clear(&game.combat_grid.entities)
	clear(&game.combat_grid.attack_indicators)
	clear(&game.combat_grid.damage_indicators)
}

combat_get_entity_at :: proc(x, y: int) -> ^CombatEntity {
	for &entity in game.combat_grid.entities {
		if entity.x == x && entity.y == y {
			return &entity
		}
	}
	return nil
}

combat_is_position_valid :: proc(x, y: int) -> bool {
	return x >= 0 && x < game.combat_grid.size && y >= 0 && y < game.combat_grid.size
}

update_enemy_ai :: proc(enemy: ^CombatEntity) {
	player_entity: ^CombatEntity
	for &entity in game.combat_grid.entities {
		if entity.is_player {
			player_entity = &entity
			break
		}
	}

	if player_entity == nil do return

	if enemy.is_telegraphing {
		target := combat_get_entity_at(enemy.target_x, enemy.target_y)
		if target != nil && target.is_player {
			damage := 1 - get_defense_bonus()
			if damage > 0 {
				target.health -= damage
			}
			spawn_damage_indicator(enemy.target_x, enemy.target_y)
			add_screen_shake(14)

			audio.play(.CLICK)
		}
		enemy.is_telegraphing = false

		for i := len(game.combat_grid.attack_indicators) - 1; i >= 0; i -= 1 {
			indicator := game.combat_grid.attack_indicators[i]
			if indicator.x == enemy.target_x && indicator.y == enemy.target_y {
				ordered_remove(&game.combat_grid.attack_indicators, i)
				break
			}
		}
	} else {
		dx := player_entity.x - enemy.x
		dy := player_entity.y - enemy.y

		if abs(dx) + abs(dy) <= 1 && rand.int31() % 2 == 0 {
			if combat_is_position_valid(player_entity.x, player_entity.y) {
				enemy.is_telegraphing = true
				enemy.target_x = player_entity.x
				enemy.target_y = player_entity.y
				append(
					&game.combat_grid.attack_indicators,
					[2]int{player_entity.x, player_entity.y},
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

			if combat_is_position_valid(new_x, new_y) &&
			   combat_get_entity_at(new_x, new_y) == nil {
				enemy.x = new_x
				enemy.y = new_y
			}
		}
	}
}

combat_update :: proc() {
	// return to exploration mode upon defeating all enemies
	// (only the player entity remains)
	if len(game.combat_grid.entities) == 1 {
		combat_fini()
	}

	for &entity in game.combat_grid.entities {
		if entity.flash_timer > 0 {
			entity.flash_timer -= 1
			if entity.flash_timer < 0 {
				entity.flash_timer = 0
			}
		}
	}

	game.move_timer -= 1
	if game.move_timer > 0 do return

	player_entity := combat_get_entity_at(-1, -1)
	for &entity in game.combat_grid.entities {
		if entity.is_player {
			player_entity = &entity
			break
		}
	}
	if player_entity == nil do return

	dir := input_get_direction()
	if vec2_is_zero(dir) do return

	target_pos := dir + Vec2{player_entity.x, player_entity.y}
	if !combat_is_position_valid(target_pos.x, target_pos.y) do return

	// attack
	target := combat_get_entity_at(target_pos.x, target_pos.y)
	if target != nil && !target.is_player {
		damage := 1 + get_attack_bonus()
		target.health -= damage
		target.flash_timer = 2
		spawn_damage_indicator(target.x, target.y)
		add_screen_shake(19)

		audio.play(.HURT)

		if target.health <= 0 {
			for i := len(game.combat_grid.entities) - 1; i >= 0; i -= 1 {
				if &game.combat_grid.entities[i] == target {
					ordered_remove(&game.combat_grid.entities, i)
					break
				}
			}
		}
		game.move_timer = MOVE_DELAY
		return
	}

	// regular movement
	if target == nil {
		player_entity.x = target_pos.x
		player_entity.y = target_pos.y
		game.move_timer = MOVE_DELAY

		audio.play(.CLICK)
	}

	for &enemy in game.combat_grid.entities {
		if !enemy.is_player {
			update_enemy_ai(&enemy)
		}
	}

	// restart game immediately on player death
	for i := len(game.combat_grid.entities) - 1; i >= 0; i -= 1 {
		entity := &game.combat_grid.entities[i]
		if entity.is_player && entity.health <= 0 {
			init_game()
			return
		}
	}
}

update_dust :: proc() {
	for i := len(game.combat_grid.damage_indicators) - 1; i >= 0; i -= 1 {
		game.combat_grid.damage_indicators[i].life -= 1
		if game.combat_grid.damage_indicators[i].life <= 0 {
			ordered_remove(&game.combat_grid.damage_indicators, i)
		}
	}
}

add_screen_shake :: proc(intensity: int) {
	game.combat_grid.screen_shake = max(game.combat_grid.screen_shake, intensity)
}

update_screen_shake :: proc() {
	game.combat_grid.screen_shake = max(0, game.combat_grid.screen_shake - 8)
}

input_get_direction :: proc() -> Vec2 {
	return {
		int(rl.IsKeyDown(.D)) - int(rl.IsKeyDown(.A)),
		int(rl.IsKeyDown(.S)) - int(rl.IsKeyDown(.W)),
	}
}

// TODO: make this generic for any int array
vec2_is_zero :: proc(v: Vec2) -> bool {
	return v.x == 0 && v.y == 0
}

spawn_damage_indicator :: proc(x, y: int) {
	append(
		&game.combat_grid.damage_indicators,
		DamageIndicator{x = x, y = y, life = 7, max_life = 7},
	)
}
