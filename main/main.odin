package main

import "audio"
import "render"
import rl "vendor:raylib"

GAME_SIZE :: 64
WINDOW_SIZE :: GAME_SIZE * 5
WINDOW_TITLE :: "cavern"
FPS :: 32

MOVE_DELAY :: 3
ENEMY_DELAY :: 8

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
	mode:           GameMode,
	transition:     Transition,

	// explore
	player:         Player,
	world:          ^[ROOM_SIZE][ROOM_SIZE]Tile,
	current_room:   int,
	move_timer:     int, // the number of frames until the player is allowed to act again
	enemy_timer:    int,
	floor_layout:   [FLOOR_SIZE][FLOOR_SIZE]Room,
	floor_number:   int,
	room_coords:    Vec2,
	unlocked_doors: map[[3]int]bool,

	// combat
	combat:         CombatGrid,
}

game: Game

explore_init :: proc() {
	game.player.position = {ROOM_CENTRE, ROOM_CENTRE}
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0
	game.transition = {}

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
	rl.SetTargetFPS(FPS)

	render.init(WINDOW_SIZE, GAME_SIZE)
	audio.init()

	explore_init()

	for !rl.WindowShouldClose() {
		// logic
		is_transition := game.transition.frames != 0
		if is_transition {
			transition_update()
		} else {
			switch game.mode {
			case .EXPLORATION:
				player_update()
				update_enemies()
				update_screen_shake()
				if is_enemy_collision() do transition_init()

			case .COMBAT:
				combat_update()
				update_dust()
				update_screen_shake()
			}
		}

		// audio
		audio.music_update()

		// visual
		render.begin()
		switch game.mode {
		case .EXPLORATION:
			world_draw()
			draw_floor_number()
			inventory_draw()
			draw_player()

		case .COMBAT:
			draw_combat_grid()
			draw_combat_entities()
		}
		if is_transition do transition_draw()
		render.end()

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
