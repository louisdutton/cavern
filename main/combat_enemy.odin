package main

import "audio"
import "core:math/rand"

update_enemy_ai :: proc(enemy: ^CombatEntity) {
	player: ^CombatEntity
	for &entity in game.combat.entities {
		if entity.is_player {
			player = &entity
			break
		}
	}

	if player == nil do return

	if enemy.is_telegraphing {
		target := combat_get_entity_at(enemy.target)
		if target != nil && target.is_player {
			damage := 1 - inventory_get_count(.SHIELD)
			if damage > 0 {
				target.health -= damage
			}
			spawn_damage_indicator(enemy.target)
			add_screen_shake(14)

			audio.play_sound(.CLICK)
		}
		enemy.is_telegraphing = false

		for i := len(game.combat.attack_indicators) - 1; i >= 0; i -= 1 {
			indicator := game.combat.attack_indicators[i]
			if indicator == enemy.target {
				ordered_remove(&game.combat.attack_indicators, i)
				break
			}
		}
	} else {
		dx := player.x - enemy.x
		dy := player.y - enemy.y

		if abs(dx) + abs(dy) <= 1 && rand.int31() % 2 == 0 {
			if combat_is_position_valid(player.position) {
				enemy.is_telegraphing = true
				enemy.target = player.position
				append(&game.combat.attack_indicators, [2]int{player.x, player.y})
				return
			}
		}

		if rand.int31() % 4 != 0 {
			new_pos := enemy.position

			if abs(dx) > abs(dy) {
				if dx > 0 {
					new_pos.x += 1
				} else if dx < 0 {
					new_pos.x -= 1
				}
			} else {
				if dy > 0 {
					new_pos.y += 1
				} else if dy < 0 {
					new_pos.y -= 1
				}
			}

			if is_valid_enemy_move(new_pos) {
				enemy.position = new_pos
			}
		}
	}
}

is_valid_enemy_move :: proc(pos: Vec2) -> bool {
	if !combat_is_position_valid(pos) {
		return false
	}

	existing_entity := combat_get_entity_at(pos)
	if existing_entity != nil {
		return false
	}

	return true
}