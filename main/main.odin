package main

import "audio"
import smarr "core:container/small_array"
import "core:math/rand"
import "render"
import rl "vendor:raylib"

GAME_SIZE :: 64
WINDOW_SIZE :: 384
WINDOW_TITLE :: "cavern"

MOVE_DELAY :: 2
ENEMY_DELAY :: 7

Player :: struct {
	using position: Vec2,
}

Enemy :: struct {
	using position:   Vec2,
	direction:        int,
	min_pos, max_pos: int,
	axis:             u8,
}

GameMode :: enum {
	EXPLORATION,
	COMBAT,
}

Game :: struct {
	player:         Player,
	world:          ^[ROOM_SIZE][ROOM_SIZE]Tile,
	current_room:   int,
	move_timer:     int, // the number of frames until the player is allowed to act again
	enemy_timer:    int,
	floor_layout:   [FLOOR_SIZE][FLOOR_SIZE]Room,
	floor_number:   int,
	room_coords:    Vec2,
	mode:           GameMode,
	combat:         CombatGrid,
	unlocked_doors: map[[3]int]bool,
}

game: Game

explore_init :: proc() {
	game.player.position = {ROOM_CENTRE, ROOM_CENTRE}
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0

	game.unlocked_doors = make(map[[3]int]bool)
	game.mode = .EXPLORATION
	game.combat.entities = make([dynamic]CombatEntity)
	game.combat.attack_indicators = make([dynamic][2]int)
	game.combat.damage_indicators = make([dynamic]DamageIndicator)

	generate_floor()
	load_current_room()
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, WINDOW_TITLE)
	rl.SetTargetFPS(24)

	render.init(WINDOW_SIZE, GAME_SIZE)
	audio.init()

	explore_init()

	for !rl.WindowShouldClose() {
		audio.music_update()

		switch game.mode {
		case .EXPLORATION:
			player_update()
			update_enemies()

			if check_player_enemy_collision() {
				continue
			}

			render.begin()
			world_draw()
			draw_floor_number()
			inventory_draw()
			draw_player()
			render.end()

		case .COMBAT:
			combat_update()
			update_dust()
			update_screen_shake()

			render.begin()
			draw_combat_grid()
			draw_combat_entities()
			render.end()
		}

		render.draw(game.combat.screen_shake)
	}

	audio.fini()
	render.fini()

	rl.CloseWindow()
}

load_current_room :: proc() {
	game.world = &game.floor_layout[game.room_coords.y][game.room_coords.x].tiles
	inventory_collapse(game.player.position)
}
