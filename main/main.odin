package main

import "audio"
import "core:math/rand"
import "render"
import rl "vendor:raylib"

GAME_SIZE :: 64
WINDOW_SIZE :: 256

MOVE_DELAY :: 2
ENEMY_DELAY :: 7

Player :: struct {
	x, y: int,
}

Item :: struct {
	x, y:               int,
	target_x, target_y: int,
	kind:               Tile,
}

Enemy :: struct {
	x, y:             int,
	direction:        int,
	min_pos, max_pos: int,
	axis:             u8,
}


Tile :: enum {
	GRASS,
	STONE,
	BOULDER,
	EXIT,
	KEY,
	SWORD,
	SHIELD,
	LOCKED_DOOR,
	SECRET_WALL,
	ENEMY,
}

Direction :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

GameState :: enum {
	EXPLORATION,
	COMBAT,
}

CombatEntity :: struct {
	x, y:               int,
	is_player:          bool,
	health:             int,
	max_health:         int,
	is_telegraphing:    bool,
	target_x, target_y: int,
	flash_timer:        int,
}

DamageIndicator :: struct {
	x, y:     int,
	life:     int,
	max_life: int,
}

CombatGrid :: struct {
	size:              int,
	entities:          [dynamic]CombatEntity,
	turn:              int,
	attack_indicators: [dynamic]Vec2,
	damage_indicators: [dynamic]DamageIndicator,
	screen_shake:      int,
}

Room :: struct {
	id:           int,
	x, y:         int,
	connections:  [Direction]bool,
	locked_exits: [Direction]bool,
	tiles:        [ROOM_SIZE][ROOM_SIZE]Tile,
}

Game :: struct {
	player:         Player,
	world:          ^[ROOM_SIZE][ROOM_SIZE]Tile,
	render_texture: rl.RenderTexture2D,
	current_room:   int,
	move_timer:     int,
	enemy_timer:    int,
	floor_layout:   [FLOOR_SIZE][FLOOR_SIZE]Room,
	floor_number:   int,
	room_coords:    Vec2,
	state:          GameState,
	combat_grid:    CombatGrid,
	inventory:      [dynamic]Item,
	unlocked_doors: map[[3]int]bool,
}

game: Game


spawn_damage_indicator :: proc(x, y: int) {
	append(
		&game.combat_grid.damage_indicators,
		DamageIndicator{x = x, y = y, life = 7, max_life = 7},
	)
}

add_screen_shake :: proc(intensity: int) {
	game.combat_grid.screen_shake = max(game.combat_grid.screen_shake, intensity)
}

init_game :: proc() {
	game.player.x = ROOM_CENTRE
	game.player.y = ROOM_CENTRE
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0
	if game.inventory == nil {
		game.inventory = make([dynamic]Item)
	}
	game.unlocked_doors = make(map[[3]int]bool)
	game.state = .EXPLORATION
	game.combat_grid.entities = make([dynamic]CombatEntity)
	game.combat_grid.attack_indicators = make([dynamic][2]int)
	game.combat_grid.damage_indicators = make([dynamic]DamageIndicator)

	generate_floor()
	load_current_room()
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "cavern")
	rl.SetTargetFPS(24)

	audio.init()
	// perform one-time setup here
	game.render_texture = rl.LoadRenderTexture(GAME_SIZE, GAME_SIZE)
	init_game()

	for !rl.WindowShouldClose() {
		audio.music_update()

		switch game.state {
		case .EXPLORATION:
			update_player()
			update_enemies()

			if check_player_enemy_collision() {
				continue
			}

			if game.world[game.player.y][game.player.x] == .EXIT {
				game.floor_number += 1
				init_game()
				continue
			}

			rl.BeginTextureMode(game.render_texture)
			render.clear_background()
			draw_world()
			draw_floor_number()
			draw_following_items()
			draw_player()
			rl.EndTextureMode()

		case .COMBAT:
			combat_update()
			update_dust()
			update_screen_shake()

			rl.BeginTextureMode(game.render_texture)
			render.clear_background()
			draw_combat_grid()
			draw_combat_entities()
			rl.EndTextureMode()
		}

		rl.BeginDrawing()

		shake_x := f32(0)
		shake_y := f32(0)
		if game.combat_grid.screen_shake > 0 {
			shake_x = (f32(rand.int31() % 5) - 2) * f32(game.combat_grid.screen_shake)
			shake_y = (f32(rand.int31() % 5) - 2) * f32(game.combat_grid.screen_shake)
		}

		dest_rect := rl.Rectangle{shake_x, shake_y, WINDOW_SIZE, WINDOW_SIZE}
		source_rect := rl.Rectangle{0, 0, GAME_SIZE, -GAME_SIZE}

		rl.DrawTexturePro(game.render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

		rl.EndDrawing()
	}

	audio.fini()

	rl.UnloadRenderTexture(game.render_texture)
	rl.CloseWindow()
}
