package hollie

import rl "vendor:raylib"

GAME_WIDTH :: 64
GAME_HEIGHT :: 64
WINDOW_WIDTH :: 256
WINDOW_HEIGHT :: 256
SCALE :: 4
TILE_SIZE :: 4
TILES_X :: 16
TILES_Y :: 16
MOVE_DELAY :: 0.2

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

Tile :: enum {
    GRASS,
    STONE,
    WATER,
}

Game :: struct {
    player: Player,
    world: [TILES_Y][TILES_X]Tile,
    render_texture: rl.RenderTexture2D,
    current_room: i32,
    move_timer: f32,
}

grass_sprite := [4][4]u8{
    {0, 0, 0, 0},
    {0, 1, 0, 0},
    {0, 0, 0, 1},
    {0, 0, 0, 0},
}

stone_sprite := [4][4]u8{
    {1, 1, 2, 1},
    {1, 2, 1, 1},
    {2, 1, 1, 2},
    {1, 1, 2, 1},
}

water_sprite := [4][4]u8{
    {3, 5, 3, 5},
    {5, 3, 5, 3},
    {3, 5, 3, 5},
    {5, 3, 5, 3},
}

player_sprite := [4][4]u8{
    {0, 4, 4, 0},
    {4, 4, 4, 4},
    {4, 4, 4, 4},
    {0, 4, 4, 0},
}

sprite_colors := [6]rl.Color{
    CATPPUCCIN_BASE,
    CATPPUCCIN_SURFACE0,
    CATPPUCCIN_OVERLAY0,
    CATPPUCCIN_BLUE,
    CATPPUCCIN_RED,
    {74, 144, 226, 255},
}

game: Game

load_room :: proc(room_id: i32) {
    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            game.world[y][x] = .GRASS
        }
    }

    if room_id == 0 {
        for y in 0..<TILES_Y {
            for x in 0..<TILES_X {
                if x == 0 || y == 0 || y == TILES_Y-1 {
                    game.world[y][x] = .STONE
                } else if x == TILES_X-1 && (y < 7 || y > 8) {
                    game.world[y][x] = .STONE
                } else if (x >= 3 && x <= 5 && y >= 4 && y <= 6) ||
                          (x >= 10 && x <= 12 && y >= 8 && y <= 10) ||
                          (x >= 7 && x <= 8 && y >= 2 && y <= 3) {
                    game.world[y][x] = .WATER
                }
            }
        }
    } else if room_id == 1 {
        for y in 0..<TILES_Y {
            for x in 0..<TILES_X {
                if y == 0 || y == TILES_Y-1 || x == TILES_X-1 {
                    game.world[y][x] = .STONE
                } else if x == 0 && (y < 7 || y > 8) {
                    game.world[y][x] = .STONE
                } else if (x >= 4 && x <= 11 && y >= 6 && y <= 9) {
                    game.world[y][x] = .WATER
                }
            }
        }
    }
}

init_game :: proc() {
    game.player = Player{x = 8, y = 8}
    game.render_texture = rl.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)
    game.current_room = 0
    game.move_timer = 0
    load_room(0)
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

    if new_x >= TILES_X {
        if game.current_room == 0 && new_y >= 7 && new_y <= 8 {
            game.current_room = 1
            game.player.x = 1
            game.move_timer = MOVE_DELAY
            load_room(1)
            return
        }
    }

    if new_x < 0 {
        if game.current_room == 1 && new_y >= 7 && new_y <= 8 {
            game.current_room = 0
            game.player.x = TILES_X - 2
            game.move_timer = MOVE_DELAY
            load_room(0)
            return
        }
    }

    if is_tile_walkable(new_x, new_y) {
        game.player.x = new_x
        game.player.y = new_y
        game.move_timer = MOVE_DELAY
    }
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
            case .WATER: sprite = &water_sprite
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

main :: proc() {
    rl.SetConfigFlags({.WINDOW_UNDECORATED})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hollie RPG")
    rl.SetTargetFPS(60)

    init_game()

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        update_player(dt)

        rl.BeginTextureMode(game.render_texture)
        rl.ClearBackground(CATPPUCCIN_BASE)
        draw_world()
        draw_player()
        rl.EndTextureMode()

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        dest_rect := rl.Rectangle{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT}
        source_rect := rl.Rectangle{0, 0, GAME_WIDTH, -GAME_HEIGHT}

        rl.DrawTexturePro(game.render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

        rl.EndDrawing()
    }

    rl.UnloadRenderTexture(game.render_texture)
    rl.CloseWindow()
} 
