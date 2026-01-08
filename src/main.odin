package main

import "audio"
import "core:fmt"
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

Game :: struct {
	screen_shake:   int,

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
}

game: Game

game_init :: proc() {
	game.player.position = {ROOM_CENTRE, ROOM_CENTRE}
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0
	game.unlocked_doors = make(map[[3]int]bool)

	generate_floor()
	load_current_room()
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, WINDOW_TITLE)
	rl.SetTargetFPS(FPS)

	render.init(WINDOW_SIZE, GAME_SIZE)
	audio.init()

	game_init()

	for !rl.WindowShouldClose() {
		// logic
		player_update()
		update_enemies()
		shake_update()
		if is_enemy_collision() {
			fmt.println("enemy collision")
		}

		// audio
		audio.music_update()

		// visual
		render.begin()
		world_draw()
		inventory_draw()
		draw_player()
		render.draw_text(fmt.tprint(game.floor_number), {})
		render.end()

		render.draw(game.screen_shake)
	}

	audio.fini()
	render.fini()

	rl.CloseWindow()
}

load_current_room :: proc() {
	game.world = &game.floor_layout[game.room_coords.y][game.room_coords.x].tiles
	inventory_collapse(game.player.position)
}
