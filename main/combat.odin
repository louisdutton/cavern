package main

import "audio"
import "core:math/rand"

CombatEntity :: struct {
	using position:  Vec2,
	is_player:       bool,
	health:          int,
	max_health:      int,
	is_telegraphing: bool,
	target:          Vec2,
	flash_timer:     int,
}

DamageIndicator :: struct {
	using position: Vec2,
	life:           int,
	max_life:       int,
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

	game.world[game.player.y][game.player.x] = .GRASS
	game.combat.screen_shake = 0

	clear(&game.combat.entities)
	clear(&game.combat.attack_indicators)
	clear(&game.combat.damage_indicators)
}

combat_get_entity_at :: proc(pos: Vec2) -> ^CombatEntity {
	for &entity in game.combat.entities {
		if entity.position == pos {
			return &entity
		}
	}
	return nil
}

combat_is_position_valid :: proc(pos: Vec2) -> bool {
	return is_in_bounds(pos, game.combat.size)
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

	player_entity := combat_get_entity_at({-1, -1})
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
	if !combat_is_position_valid(target_pos) do return

	// attack
	target := combat_get_entity_at(target_pos)
	if target != nil && !target.is_player {
		damage := 1 + inventory_get_count(.SWORD)
		target.health -= damage
		target.flash_timer = 2
		spawn_damage_indicator(target)
		add_screen_shake(19)

		audio.play_sound(.HURT)

		if target.health <= 0 {
			cleanup_enemy_attack_indicators(target)
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

		audio.play_sound(.CLICK)
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

spawn_damage_indicator :: proc(pos: Vec2) {
	append(&game.combat.damage_indicators, DamageIndicator{position = pos, life = 7, max_life = 7})
}
