package main

import "audio"
import "core:math/rand"
import rl "vendor:raylib"

CombatEntity :: struct {
	x, y:               int,
	is_player:          bool,
	health:             int,
	max_health:         int,
	is_telegraphing:    bool,
	target_x, target_y: int,
	flash_timer:        int,
}

CombatGrid :: struct {
	size:              int,
	entities:          [dynamic]CombatEntity,
	turn:              int,
	attack_indicators: [dynamic]Vec2,
	damage_indicators: [dynamic]DamageIndicator,
	screen_shake:      int,
}

combat_init :: proc(enemy_x, enemy_y: int) {
	game.mode = .COMBAT
	game.combat.size = 8
	game.combat.turn = 0
	clear(&game.combat.entities)
	clear(&game.combat.attack_indicators)
	clear(&game.combat.damage_indicators)
	game.combat.screen_shake = 0

	append(
		&game.combat.entities,
		CombatEntity{x = 2, y = 6, is_player = true, health = 3, max_health = 3},
	)

	enemy_count := 2 + rand.int_max(3)
	enemy_positions := []Vec2{{5, 1}, {1, 1}, {6, 2}, {0, 3}, {7, 4}, {3, 0}, {4, 7}, {6, 6}}

	for i in 0 ..< enemy_count {
		if i < len(enemy_positions) {
			pos := enemy_positions[i]
			append(
				&game.combat.entities,
				CombatEntity{x = pos.x, y = pos.y, is_player = false, health = 2, max_health = 2},
			)
		}
	}
}

combat_fini :: proc() {
	game.mode = .EXPLORATION

	defeated_enemy_x, defeated_enemy_y := game.player.x, game.player.y

	game.world[defeated_enemy_y][defeated_enemy_x] = .GRASS
	game.combat.screen_shake = 0

	clear(&game.combat.entities)
	clear(&game.combat.attack_indicators)
	clear(&game.combat.damage_indicators)
}

combat_get_entity_at :: proc(x, y: int) -> ^CombatEntity {
	for &entity in game.combat.entities {
		if entity.x == x && entity.y == y {
			return &entity
		}
	}
	return nil
}

combat_is_position_valid :: proc(x, y: int) -> bool {
	return x >= 0 && x < game.combat.size && y >= 0 && y < game.combat.size
}

update_enemy_ai :: proc(enemy: ^CombatEntity) {
	player_entity: ^CombatEntity
	for &entity in game.combat.entities {
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

		for i := len(game.combat.attack_indicators) - 1; i >= 0; i -= 1 {
			indicator := game.combat.attack_indicators[i]
			if indicator.x == enemy.target_x && indicator.y == enemy.target_y {
				ordered_remove(&game.combat.attack_indicators, i)
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
				append(&game.combat.attack_indicators, [2]int{player_entity.x, player_entity.y})
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
	if len(game.combat.entities) == 1 {
		combat_fini()
	}

	for &entity in game.combat.entities {
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
	for &entity in game.combat.entities {
		if entity.is_player {
			player_entity = &entity
			break
		}
	}
	if player_entity == nil do return

	dir := input_get_direction()
	if is_zero_vec2(dir) do return

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
			for i := len(game.combat.entities) - 1; i >= 0; i -= 1 {
				if &game.combat.entities[i] == target {
					ordered_remove(&game.combat.entities, i)
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

	for &enemy in game.combat.entities {
		if !enemy.is_player {
			update_enemy_ai(&enemy)
		}
	}

	// restart game immediately on player death
	for i := len(game.combat.entities) - 1; i >= 0; i -= 1 {
		entity := &game.combat.entities[i]
		if entity.is_player && entity.health <= 0 {
			explore_init()
			return
		}
	}
}

update_dust :: proc() {
	for i := len(game.combat.damage_indicators) - 1; i >= 0; i -= 1 {
		game.combat.damage_indicators[i].life -= 1
		if game.combat.damage_indicators[i].life <= 0 {
			ordered_remove(&game.combat.damage_indicators, i)
		}
	}
}

add_screen_shake :: proc(intensity: int) {
	game.combat.screen_shake = max(game.combat.screen_shake, intensity)
}

update_screen_shake :: proc() {
	game.combat.screen_shake = max(0, game.combat.screen_shake - 8)
}

spawn_damage_indicator :: proc(x, y: int) {
	append(&game.combat.damage_indicators, DamageIndicator{x = x, y = y, life = 7, max_life = 7})
}
