package main

import "core:math/rand"
import rl "vendor:raylib"

GAME_SIZE :: 64
WINDOW_SIZE :: 256

MOVE_DELAY :: 2
ENEMY_DELAY :: 7

CATPPUCCIN_BASE :: rl.Color{30, 30, 46, 255}
CATPPUCCIN_SURFACE0 :: rl.Color{49, 50, 68, 255}
CATPPUCCIN_OVERLAY0 :: rl.Color{108, 112, 134, 255}
CATPPUCCIN_BLUE :: rl.Color{137, 180, 250, 255}
CATPPUCCIN_GREEN :: rl.Color{166, 227, 161, 255}
CATPPUCCIN_RED :: rl.Color{243, 139, 168, 255}
CATPPUCCIN_LAVENDER :: rl.Color{180, 190, 254, 255}

Player :: struct {
	x, y: i32,
}

FollowingItem :: struct {
	x, y:               i32,
	target_x, target_y: i32,
}

Enemy :: struct {
	x, y:             i32,
	direction:        i32,
	min_pos, max_pos: i32,
	axis:             u8,
}


Tile :: enum {
	GRASS,
	STONE,
	WATER,
	EXIT,
	KEY,
	LOCKED_DOOR,
	SECRET_WALL,
}

Direction :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

SoundEffect :: enum {
	CLICK,
	COLLECT,
	DESTROY,
	GROWL,
	HURT,
	LOCKED,
	METAL,
	PICKUP,
	UNLOCK,
}

GameState :: enum {
	EXPLORATION,
	BATTLE,
}


BattleEntity :: struct {
	x, y:               i32,
	is_player:          bool,
	health:             i32,
	max_health:         i32,
	is_telegraphing:    bool,
	target_x, target_y: i32,
	flash_timer:        i32,
}

DamageIndicator :: struct {
	x, y:     i32,
	life:     i32,
	max_life: i32,
}

BattleGrid :: struct {
	size:              i32,
	entities:          [dynamic]BattleEntity,
	turn:              i32,
	attack_indicators: [dynamic][2]i32,
	damage_indicators: [dynamic]DamageIndicator,
	screen_shake:      i32,
}

Room :: struct {
	id:           i32,
	x, y:         i32,
	connections:  [Direction]bool,
	locked_exits: [Direction]bool,
	is_start:     bool,
	is_end:       bool,
	has_enemies:  bool,
	has_key:      bool,
	tiles:        [ROOM_SIZE][ROOM_SIZE]Tile,
}

Game :: struct {
	player:          Player,
	world:           [ROOM_SIZE][ROOM_SIZE]Tile,
	render_texture:  rl.RenderTexture2D,
	current_room:    i32,
	move_timer:      i32,
	enemies:         [dynamic]Enemy,
	enemy_timer:     i32,
	water_time:      i32,
	music:           rl.Music,
	sounds:          [SoundEffect]rl.Sound,
	floor_layout:    [FLOOR_SIZE][FLOOR_SIZE]Room,
	room_coords:     [2]i32,
	state:           GameState,
	battle_grid:     BattleGrid,
	floor_number:    i32,
	following_items: [dynamic]FollowingItem,
	unlocked_doors:  map[[3]i32]bool,
}

game: Game


spawn_damage_indicator :: proc(x, y: i32) {
	append(
		&game.battle_grid.damage_indicators,
		DamageIndicator{x = x, y = y, life = 7, max_life = 7},
	)
}

add_screen_shake :: proc(intensity: i32) {
	game.battle_grid.screen_shake = max(game.battle_grid.screen_shake, intensity)
}


init_game :: proc() {
	game.player = Player {
		x = ROOM_CENTRE,
		y = ROOM_CENTRE,
	}
	game.render_texture = rl.LoadRenderTexture(GAME_SIZE, GAME_SIZE)
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0
	game.water_time = 0
	game.enemies = make([dynamic]Enemy)
	game.following_items = make([dynamic]FollowingItem)
	game.unlocked_doors = make(map[[3]i32]bool)
	game.state = .EXPLORATION
	game.battle_grid.entities = make([dynamic]BattleEntity)
	game.battle_grid.attack_indicators = make([dynamic][2]i32)
	game.battle_grid.damage_indicators = make([dynamic]DamageIndicator)
	if game.floor_number == 0 {
		game.floor_number = 1
	}
	generate_floor()
	load_current_room()
}

init_audio :: proc() {
	rl.InitAudioDevice()
	rl.SetMasterVolume(0.2)
	game.music = rl.LoadMusicStream("res/music.mp3")
	for sound_type in SoundEffect {
		game.sounds[sound_type] = rl.LoadSound(sound_paths[sound_type])
	}
	rl.PlayMusicStream(game.music)
}

update_dust :: proc() {
	if game.state == .BATTLE {
		for i := len(game.battle_grid.damage_indicators) - 1; i >= 0; i -= 1 {
			game.battle_grid.damage_indicators[i].life -= 1
			if game.battle_grid.damage_indicators[i].life <= 0 {
				ordered_remove(&game.battle_grid.damage_indicators, i)
			}
		}

		game.battle_grid.screen_shake = max(0, game.battle_grid.screen_shake - 8)
	}

	game.battle_grid.screen_shake = max(0, game.battle_grid.screen_shake - 8)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "cavern")
	rl.SetTargetFPS(24)

	init_audio()
	init_game()

	for !rl.WindowShouldClose() {

		rl.UpdateMusicStream(game.music)

		switch game.state {
		case .EXPLORATION:
			update_player()
			update_enemies()
			update_dust()
			game.water_time += 1

			if check_player_enemy_collision() {
				continue
			}

			room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
			if room.is_end && game.player.x == ROOM_CENTRE && game.player.y == ROOM_CENTRE {
				game.floor_number += 1
				init_game()
				continue
			}

			rl.BeginTextureMode(game.render_texture)
			rl.ClearBackground(CATPPUCCIN_BASE)
			draw_world()
			draw_floor_number()
			draw_enemies()
			draw_following_items()
			draw_player()
			rl.EndTextureMode()

		case .BATTLE:
			update_battle()
			update_dust()

			rl.BeginTextureMode(game.render_texture)
			rl.ClearBackground(CATPPUCCIN_BASE)
			draw_battle_grid()
			draw_battle_entities()
			rl.EndTextureMode()
		}

		rl.BeginDrawing()

		shake_x := f32(0)
		shake_y := f32(0)
		if game.battle_grid.screen_shake > 0 {
			shake_x = (f32(rand.int31() % 5) - 2) * f32(game.battle_grid.screen_shake)
			shake_y = (f32(rand.int31() % 5) - 2) * f32(game.battle_grid.screen_shake)
		}

		dest_rect := rl.Rectangle{shake_x, shake_y, WINDOW_SIZE, WINDOW_SIZE}
		source_rect := rl.Rectangle{0, 0, GAME_SIZE, -GAME_SIZE}

		rl.DrawTexturePro(game.render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

		rl.EndDrawing()
	}

	rl.UnloadMusicStream(game.music)
	for sound in game.sounds {
		rl.UnloadSound(sound)
	}
	rl.CloseAudioDevice()
	rl.UnloadRenderTexture(game.render_texture)
	rl.CloseWindow()
}

update :: proc() {
	switch game.state {
	case .EXPLORATION:
		update_player()
		update_enemies()
		update_dust()
		game.water_time += 1

		if check_player_enemy_collision() do return

		room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
		if room.is_end && game.player.x == ROOM_CENTRE && game.player.y == ROOM_CENTRE {
			game.floor_number += 1
			init_game()
			return
		}

	case .BATTLE:
		update_battle()
		update_dust()
	}
}

draw :: proc() {
	rl.BeginTextureMode(game.render_texture)
	rl.ClearBackground(CATPPUCCIN_BASE)
	defer rl.EndTextureMode()

	switch game.state {
	case .EXPLORATION:
		draw_world()
		draw_floor_number()
		draw_enemies()
		draw_following_items()
		draw_player()

	case .BATTLE:
		draw_battle_grid()
		draw_battle_entities()
	}
}
