package main

import rl "vendor:raylib"
import "core:math/rand"

GAME_WIDTH :: 64
GAME_HEIGHT :: 64
WINDOW_WIDTH :: 256
WINDOW_HEIGHT :: 256
SCALE :: 4
TILE_SIZE :: 4
TILES_X :: 16
TILES_Y :: 16
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
    x, y: i32,
    direction: i32,
    min_pos, max_pos: i32,
    axis: u8,
}

DustParticle :: struct {
    x, y: i32,
    life: f32,
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

Room :: struct {
    id: i32,
    x, y: i32,
    connections: [4]bool,
    is_start: bool,
    is_end: bool,
    has_enemies: bool,
}

FLOOR_WIDTH :: 5
FLOOR_HEIGHT :: 5

Game :: struct {
    player: Player,
    world: [TILES_Y][TILES_X]Tile,
    render_texture: rl.RenderTexture2D,
    current_room: i32,
    move_timer: f32,
    enemies: [dynamic]Enemy,
    enemy_timer: f32,
    dust_particles: [dynamic]DustParticle,
    water_time: f32,
    music: rl.Music,
    click_sound: rl.Sound,
    floor_layout: [FLOOR_HEIGHT][FLOOR_WIDTH]Room,
    room_coords: [2]i32,
}


game: Game

generate_floor :: proc() {

    for y in 0..<FLOOR_HEIGHT {
        for x in 0..<FLOOR_WIDTH {
            game.floor_layout[y][x] = Room{
                id = i32(y * FLOOR_WIDTH + x),
                x = i32(x),
                y = i32(y),
            }
        }
    }

    start_x := rand.int31() % FLOOR_WIDTH
    start_y := rand.int31() % FLOOR_HEIGHT
    game.floor_layout[start_y][start_x].is_start = true

    end_x := rand.int31() % FLOOR_WIDTH
    end_y := rand.int31() % FLOOR_HEIGHT
    for end_x == start_x && end_y == start_y {
        end_x = rand.int31() % FLOOR_WIDTH
        end_y = rand.int31() % FLOOR_HEIGHT
    }
    game.floor_layout[end_y][end_x].is_end = true

    current_x, current_y := start_x, start_y
    for current_x != end_x || current_y != end_y {

        if current_x < end_x {
            next_x, next_y := current_x + 1, current_y
            game.floor_layout[current_y][current_x].connections[int(Direction.EAST)] = true
            game.floor_layout[next_y][next_x].connections[int(Direction.WEST)] = true
            current_x = next_x
        } else if current_x > end_x {
            next_x, next_y := current_x - 1, current_y
            game.floor_layout[current_y][current_x].connections[int(Direction.WEST)] = true
            game.floor_layout[next_y][next_x].connections[int(Direction.EAST)] = true
            current_x = next_x
        } else if current_y < end_y {
            next_x, next_y := current_x, current_y + 1
            game.floor_layout[current_y][current_x].connections[int(Direction.SOUTH)] = true
            game.floor_layout[next_y][next_x].connections[int(Direction.NORTH)] = true
            current_y = next_y
        } else if current_y > end_y {
            next_x, next_y := current_x, current_y - 1
            game.floor_layout[current_y][current_x].connections[int(Direction.NORTH)] = true
            game.floor_layout[next_y][next_x].connections[int(Direction.SOUTH)] = true
            current_y = next_y
        }
    }

    for y in 0..<FLOOR_HEIGHT {
        for x in 0..<FLOOR_WIDTH {
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

    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            game.world[y][x] = .GRASS
        }
    }

    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            if y == 0 && !room.connections[int(Direction.NORTH)] {
                game.world[y][x] = .STONE
            } else if y == TILES_Y-1 && !room.connections[int(Direction.SOUTH)] {
                game.world[y][x] = .STONE
            } else if x == 0 && !room.connections[int(Direction.WEST)] {
                game.world[y][x] = .STONE
            } else if x == TILES_X-1 && !room.connections[int(Direction.EAST)] {
                game.world[y][x] = .STONE
            }
        }
    }

    for y in 7..=8 {
        if room.connections[int(Direction.NORTH)] && game.world[0][y] == .STONE {
            game.world[0][y] = .GRASS
        }
        if room.connections[int(Direction.SOUTH)] && game.world[TILES_Y-1][y] == .STONE {
            game.world[TILES_Y-1][y] = .GRASS
        }
    }
    for x in 7..=8 {
        if room.connections[int(Direction.WEST)] && game.world[x][0] == .STONE {
            game.world[x][0] = .GRASS
        }
        if room.connections[int(Direction.EAST)] && game.world[x][TILES_X-1] == .STONE {
            game.world[x][TILES_X-1] = .GRASS
        }
    }

    if room.is_end {
        game.world[8][8] = .EXIT
    } else {
        water_count := 2 + (room.id % 3)
        for i in 0..<water_count {
            wx := 3 + (i * 4) % 10
            wy := 3 + (i * 3) % 10
            for dy in 0..<2 {
                for dx in 0..<2 {
                    if i32(wx) + i32(dx) < TILES_X-1 && i32(wy) + i32(dy) < TILES_Y-1 {
                        game.world[i32(wy) + i32(dy)][i32(wx) + i32(dx)] = .WATER
                    }
                }
            }
        }
    }

    if room.has_enemies {
        enemy_count := 1 + (room.id % 3)
        for i in 0..<enemy_count {
            ex := 2 + (i * 5) % 12
            ey := 2 + (i * 7) % 12
            axis := u8(i % 2)
            if axis == 0 {
                append(&game.enemies, Enemy{x = ex, y = ey, direction = 1, min_pos = 2, max_pos = 13, axis = axis})
            } else {
                append(&game.enemies, Enemy{x = ex, y = ey, direction = 1, min_pos = 2, max_pos = 13, axis = axis})
            }
        }
    }
}

spawn_dust :: proc(x, y: i32) {
    append(&game.dust_particles, DustParticle{
        x = x,
        y = y,
        life = DUST_LIFE,
        max_life = DUST_LIFE,
    })
}

init_game :: proc() {
    game.player = Player{x = 8, y = 8}
    game.render_texture = rl.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)
    game.current_room = 0
    game.move_timer = 0
    game.enemy_timer = 0
    game.water_time = 0
    game.enemies = make([dynamic]Enemy)
    game.dust_particles = make([dynamic]DustParticle)
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
    if x < 0 || x >= TILES_X || y < 0 || y >= TILES_Y {
        return false
    }
    return game.world[y][x] != .STONE
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

    if new_x >= TILES_X && room.connections[int(Direction.EAST)] && new_y >= 7 && new_y <= 8 {
        game.room_coords.x += 1
        game.player.x = 1
        game.move_timer = MOVE_DELAY
        load_current_room()
        return
    }

    if new_x < 0 && room.connections[int(Direction.WEST)] && new_y >= 7 && new_y <= 8 {
        game.room_coords.x -= 1
        game.player.x = TILES_X - 2
        game.move_timer = MOVE_DELAY
        load_current_room()
        return
    }

    if new_y < 0 && room.connections[int(Direction.NORTH)] && new_x >= 7 && new_x <= 8 {
        game.room_coords.y -= 1
        game.player.y = TILES_Y - 2
        game.move_timer = MOVE_DELAY
        load_current_room()
        return
    }

    if new_y >= TILES_Y && room.connections[int(Direction.SOUTH)] && new_x >= 7 && new_x <= 8 {
        game.room_coords.y += 1
        game.player.y = 1
        game.move_timer = MOVE_DELAY
        load_current_room()
        return
    }

    if is_tile_walkable(new_x, new_y) {
        spawn_dust(game.player.x, game.player.y)
        game.player.x = new_x
        game.player.y = new_y
        game.move_timer = MOVE_DELAY

        pitch := 0.8 + f32((game.player.x + game.player.y) % 5) * 0.1
        rl.SetSoundPitch(game.click_sound, pitch)
        rl.PlaySound(game.click_sound)
    }
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

check_player_death :: proc() -> bool {
    for enemy in game.enemies {
        if game.player.x == enemy.x && game.player.y == enemy.y {
            return true
        }
    }
    return false
}

draw_sprite :: proc(sprite: ^[4][4]u8, x, y: i32, transparent_index: u8 = 255) {
    for py in 0..<4 {
        for px in 0..<4 {
            color_index := sprite[py][px]
            if color_index != transparent_index {
                pixel_x := x + i32(px)
                pixel_y := y + i32(py)
                rl.DrawPixel(pixel_x, pixel_y, sprite_colors[color_index])
            }
        }
    }
}

draw_world :: proc() {
    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            tile_x := i32(x * TILE_SIZE)
            tile_y := i32(y * TILE_SIZE)

            sprite: ^[4][4]u8
            switch game.world[y][x] {
            case .GRASS: sprite = &grass_sprite
            case .STONE: sprite = &stone_sprite
            case .WATER:
                wave_offset := i32(game.water_time * 4) % 2
                if (i32(x) + i32(y) + wave_offset) % 2 == 0 {
                    sprite = &water_sprite_a
                } else {
                    sprite = &water_sprite_b
                }
            case .EXIT: sprite = &exit_sprite
            }

            draw_sprite(sprite, tile_x, tile_y)
        }
    }
}

draw_player :: proc() {
    pixel_x := game.player.x * TILE_SIZE
    pixel_y := game.player.y * TILE_SIZE
    draw_sprite(&player_sprite, pixel_x, pixel_y, 0)
}

draw_enemies :: proc() {
    for enemy in game.enemies {
        pixel_x := enemy.x * TILE_SIZE
        pixel_y := enemy.y * TILE_SIZE
        draw_sprite(&enemy_sprite, pixel_x, pixel_y, 0)
    }
}

draw_dust_sprite :: proc(sprite: ^[4][4]u8, x, y: i32, alpha: u8) {
    for py in 0..<4 {
        for px in 0..<4 {
            color_index := sprite[py][px]
            if color_index != 0 {
                pixel_x := x + i32(px)
                pixel_y := y + i32(py)

                base_color := sprite_colors[color_index]
                dust_color := rl.Color{
                    base_color.r,
                    base_color.g,
                    base_color.b,
                    alpha,
                }

                rl.DrawPixel(pixel_x, pixel_y, dust_color)
            }
        }
    }
}

draw_dust :: proc() {
    for dust in game.dust_particles {
        life_ratio := dust.life / dust.max_life
        alpha_u8 := u8(life_ratio * 255)

        pixel_x := dust.x * TILE_SIZE
        pixel_y := dust.y * TILE_SIZE

        if life_ratio > 0.3 {
            draw_dust_sprite(&dust_sprite, pixel_x, pixel_y, alpha_u8)
        } else {
            dust_color := rl.Color{
                CATPPUCCIN_OVERLAY0.r,
                CATPPUCCIN_OVERLAY0.g,
                CATPPUCCIN_OVERLAY0.b,
                alpha_u8,
            }
            center_x := pixel_x + 2
            center_y := pixel_y + 2
            rl.DrawPixel(center_x, center_y, dust_color)
        }
    }
}

main :: proc() {
    rl.SetConfigFlags({.WINDOW_UNDECORATED})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "cavern")
    rl.SetTargetFPS(60)

    init_audio()
    init_game()

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        rl.UpdateMusicStream(game.music)

        update_player(dt)
        update_enemies(dt)
        update_dust(dt)
        game.water_time += dt

        if check_player_death() {
            init_game()
            continue
        }

        room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
        if room.is_end && game.player.x == 8 && game.player.y == 8 {
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

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        dest_rect := rl.Rectangle{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT}
        source_rect := rl.Rectangle{0, 0, GAME_WIDTH, -GAME_HEIGHT}

        rl.DrawTexturePro(game.render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

        rl.EndDrawing()
    }

    rl.UnloadMusicStream(game.music)
    rl.UnloadSound(game.click_sound)
    rl.CloseAudioDevice()
    rl.UnloadRenderTexture(game.render_texture)
    rl.CloseWindow()
} 
