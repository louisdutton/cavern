package main

import "core:math/rand"
import rl "vendor:raylib"

GAME_SIZE :: 64
WINDOW_SIZE :: 256

TILES_SIZE :: 16
CENTRE :: TILES_SIZE / 2
TILE_COUNT :: TILES_SIZE * TILES_SIZE
FLOOR_SIZE :: 5

MOVE_DELAY :: 0.1
ENEMY_DELAY :: 0.3
DUST_LIFE :: 0.5

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

Enemy :: struct {
	x, y:             i32,
	direction:        i32,
	min_pos, max_pos: i32,
	axis:             u8,
}

DustParticle :: struct {
	x, y:     i32,
	life:     f32,
	max_life: f32,
}

Tile :: enum {
	GRASS,
	STONE,
	WATER,
	EXIT,
}

Direction :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

GameState :: enum {
	EXPLORATION,
	BATTLE,
}

BattleEntity :: struct {
	x, y: i32,
	is_player: bool,
	health: i32,
	max_health: i32,
}

BattleGrid :: struct {
	size: i32,
	entities: [dynamic]BattleEntity,
	turn: i32,
}

Room :: struct {
	id:          i32,
	x, y:        i32,
	connections: [Direction]bool,
	is_start:    bool,
	is_end:      bool,
	has_enemies: bool,
}


Game :: struct {
	player:         Player,
	world:          [TILES_SIZE][TILES_SIZE]Tile,
	render_texture: rl.RenderTexture2D,
	current_room:   i32,
	move_timer:     f32,
	enemies:        [dynamic]Enemy,
	enemy_timer:    f32,
	dust_particles: [dynamic]DustParticle,
	water_time:     f32,
	music:          rl.Music,
	click_sound:    rl.Sound,
	floor_layout:   [FLOOR_SIZE][FLOOR_SIZE]Room,
	room_coords:    [2]i32,
	state:          GameState,
	battle_grid:    BattleGrid,
}


game: Game

generate_floor :: proc() {

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			game.floor_layout[y][x] = Room {
				id = i32(y * FLOOR_SIZE + x),
				x  = i32(x),
				y  = i32(y),
			}
		}
	}

	start_x := rand.int31() % FLOOR_SIZE
	start_y := rand.int31() % FLOOR_SIZE
	game.floor_layout[start_y][start_x].is_start = true

	end_x := rand.int31() % FLOOR_SIZE
	end_y := rand.int31() % FLOOR_SIZE
	for end_x == start_x && end_y == start_y {
		end_x = rand.int31() % FLOOR_SIZE
		end_y = rand.int31() % FLOOR_SIZE
	}
	game.floor_layout[end_y][end_x].is_end = true

	current_x, current_y := start_x, start_y
	for current_x != end_x || current_y != end_y {

		if current_x < end_x {
			next_x, next_y := current_x + 1, current_y
			game.floor_layout[current_y][current_x].connections[.EAST] = true
			game.floor_layout[next_y][next_x].connections[.WEST] = true
			current_x = next_x
		} else if current_x > end_x {
			next_x, next_y := current_x - 1, current_y
			game.floor_layout[current_y][current_x].connections[.WEST] = true
			game.floor_layout[next_y][next_x].connections[.EAST] = true
			current_x = next_x
		} else if current_y < end_y {
			next_x, next_y := current_x, current_y + 1
			game.floor_layout[current_y][current_x].connections[.SOUTH] = true
			game.floor_layout[next_y][next_x].connections[.NORTH] = true
			current_y = next_y
		} else if current_y > end_y {
			next_x, next_y := current_x, current_y - 1
			game.floor_layout[current_y][current_x].connections[.NORTH] = true
			game.floor_layout[next_y][next_x].connections[.SOUTH] = true
			current_y = next_y
		}
	}

	for y in 0 ..< FLOOR_SIZE {
		for x in 0 ..< FLOOR_SIZE {
			if !game.floor_layout[y][x].is_start && !game.floor_layout[y][x].is_end {
				game.floor_layout[y][x].has_enemies = rand.int31() % 3 == 0
			}
		}
	}

	game.room_coords = {start_x, start_y}
}

load_current_room :: proc() {
	clear(&game.enemies)

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	// floor
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			game.world[y][x] = .GRASS
		}
	}

	// walls
	for y in 0 ..< TILES_SIZE {
		for x in 0 ..< TILES_SIZE {
			if (y == 0 && !room.connections[.NORTH]) ||
			   (y == TILES_SIZE - 1 && !room.connections[.SOUTH]) ||
			   (x == 0 && !room.connections[.WEST]) ||
			   (x == TILES_SIZE - 1 && !room.connections[.EAST]) {
				game.world[y][x] = .STONE
			}
		}
	}

	// misc
	if room.is_end {
		game.world[CENTRE][CENTRE] = .EXIT
	} else {
		water_count := 2 + (room.id % 3)
		for i in 0 ..< water_count {
			wx := 3 + (i * 4) % 10
			wy := 3 + (i * 3) % 10
			for dy in 0 ..< 2 {
				for dx in 0 ..< 2 {
					if i32(wx) + i32(dx) < TILES_SIZE - 1 && i32(wy) + i32(dy) < TILES_SIZE - 1 {
						game.world[i32(wy) + i32(dy)][i32(wx) + i32(dx)] = .WATER
					}
				}
			}
		}
	}

	// enemies
	if room.has_enemies {
		enemy_count := 1 + (room.id % 3)
		for i in 0 ..< enemy_count {
			ex := 2 + (i * 5) % 12
			ey := 2 + (i * 7) % 12
			axis := u8(i % 2)
			append(
				&game.enemies,
				Enemy{x = ex, y = ey, direction = 1, min_pos = 2, max_pos = 13, axis = axis},
			)
		}
	}
}

spawn_dust :: proc(x, y: i32) {
	append(
		&game.dust_particles,
		DustParticle{x = x, y = y, life = DUST_LIFE, max_life = DUST_LIFE},
	)
}

init_battle :: proc(enemy_x, enemy_y: i32) {
	game.state = .BATTLE
	game.battle_grid.size = 8
	game.battle_grid.turn = 0
	clear(&game.battle_grid.entities)

	append(&game.battle_grid.entities, BattleEntity{
		x = 2, y = 6, is_player = true, health = 3, max_health = 3,
	})

	append(&game.battle_grid.entities, BattleEntity{
		x = 5, y = 1, is_player = false, health = 2, max_health = 2,
	})
}

end_battle :: proc() {
	game.state = .EXPLORATION
	clear(&game.battle_grid.entities)
}

init_game :: proc() {
	game.player = Player {
		x = CENTRE,
		y = CENTRE,
	}
	game.render_texture = rl.LoadRenderTexture(GAME_SIZE, GAME_SIZE)
	game.current_room = 0
	game.move_timer = 0
	game.enemy_timer = 0
	game.water_time = 0
	game.enemies = make([dynamic]Enemy)
	game.dust_particles = make([dynamic]DustParticle)
	game.state = .EXPLORATION
	game.battle_grid.entities = make([dynamic]BattleEntity)
	generate_floor()
	load_current_room()
}

init_audio :: proc() {
	rl.InitAudioDevice()
	game.music = rl.LoadMusicStream("res/music.mp3")
	game.click_sound = rl.LoadSound("res/click.wav")
	rl.PlayMusicStream(game.music)
}

is_tile_walkable :: proc(x, y: i32) -> bool {
	return game.world[y][x] != .STONE
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

update_battle :: proc(dt: f32) {
	game.move_timer -= dt
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
	} else if rl.IsKeyDown(.R) {
		end_battle()
		return
	}

	if !moved do return

	if !is_battle_position_valid(new_x, new_y) do return

	target := get_battle_entity_at(new_x, new_y)
	if target != nil && !target.is_player {
		target.health -= 1
		spawn_dust(target.x, target.y)
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
		spawn_dust(player_entity.x, player_entity.y)
		player_entity.x = new_x
		player_entity.y = new_y
		game.move_timer = MOVE_DELAY

		pitch := 0.8 + f32((player_entity.x + player_entity.y) % 5) * 0.1
		rl.SetSoundPitch(game.click_sound, pitch)
		rl.PlaySound(game.click_sound)
	}

	enemy_count := 0
	for entity in game.battle_grid.entities {
		if !entity.is_player {
			enemy_count += 1
		}
	}
	if enemy_count == 0 {
		end_battle()
	}
}

update_player :: proc(dt: f32) {
	game.move_timer -= dt

	if game.move_timer > 0 do return

	new_x := game.player.x
	new_y := game.player.y
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

	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]

	if new_x >= TILES_SIZE && room.connections[.EAST] {
		game.room_coords.x += 1
		game.player.x = 1
	} else if new_x < 0 && room.connections[.WEST]  {
		game.room_coords.x -= 1
		game.player.x = TILES_SIZE - 2
	} else if new_y < 0 && room.connections[.NORTH]  {
		game.room_coords.y -= 1
		game.player.y = TILES_SIZE - 2
	} else if new_y >= TILES_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 1
	} else {
		if is_tile_walkable(new_x, new_y) {
			spawn_dust(game.player.x, game.player.y)
			game.player.x = new_x
			game.player.y = new_y
			game.move_timer = MOVE_DELAY

			pitch := 0.8 + f32((game.player.x + game.player.y) % 5) * 0.1
			rl.SetSoundPitch(game.click_sound, pitch)
			rl.PlaySound(game.click_sound)
		}
		return
	}

	game.move_timer = MOVE_DELAY
	load_current_room()
}

update_enemies :: proc(dt: f32) {
	game.enemy_timer -= dt
	if game.enemy_timer > 0 do return

	for &enemy in game.enemies {
		spawn_dust(enemy.x, enemy.y)

		if enemy.axis == 0 {
			enemy.x += enemy.direction
			if enemy.x <= enemy.min_pos || enemy.x >= enemy.max_pos {
				enemy.direction *= -1
			}
		} else {
			enemy.y += enemy.direction
			if enemy.y <= enemy.min_pos || enemy.y >= enemy.max_pos {
				enemy.direction *= -1
			}
		}
	}

	game.enemy_timer = ENEMY_DELAY
}

update_dust :: proc(dt: f32) {
	for i := len(game.dust_particles) - 1; i >= 0; i -= 1 {
		game.dust_particles[i].life -= dt
		if game.dust_particles[i].life <= 0 {
			ordered_remove(&game.dust_particles, i)
		}
	}
}

check_player_enemy_collision :: proc() -> bool {
	for enemy in game.enemies {
		if game.player.x == enemy.x && game.player.y == enemy.y {
			init_battle(enemy.x, enemy.y)
			return true
		}
	}
	return false
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "cavern")
	rl.SetTargetFPS(24)

	init_audio()
	init_game()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		rl.UpdateMusicStream(game.music)

		if game.state == .EXPLORATION {
			update_player(dt)
			update_enemies(dt)
			update_dust(dt)
			game.water_time += dt

			if check_player_enemy_collision() {
				continue
			}

			room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
			if room.is_end && game.player.x == CENTRE && game.player.y == CENTRE {
				init_game()
				continue
			}

			rl.BeginTextureMode(game.render_texture)
			rl.ClearBackground(CATPPUCCIN_BASE)
			draw_world()
			draw_dust()
			draw_enemies()
			draw_player()
			rl.EndTextureMode()
		} else if game.state == .BATTLE {
			update_battle(dt)
			update_dust(dt)

			rl.BeginTextureMode(game.render_texture)
			rl.ClearBackground(CATPPUCCIN_BASE)
			draw_battle_grid()
			draw_dust()
			draw_battle_entities()
			rl.EndTextureMode()
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		dest_rect := rl.Rectangle{0, 0, WINDOW_SIZE, WINDOW_SIZE}
		source_rect := rl.Rectangle{0, 0, GAME_SIZE, -GAME_SIZE}

		rl.DrawTexturePro(game.render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

		rl.EndDrawing()
	}

	rl.UnloadMusicStream(game.music)
	rl.UnloadSound(game.click_sound)
	rl.CloseAudioDevice()
	rl.UnloadRenderTexture(game.render_texture)
	rl.CloseWindow()
}
