package hollie

import rl "vendor:raylib"
import "core:math"

GAME_WIDTH :: 64
GAME_HEIGHT :: 64
WINDOW_WIDTH :: 256
WINDOW_HEIGHT :: 256
SCALE :: 4
TILE_SIZE :: 4
TILES_X :: 16
TILES_Y :: 16

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
}

init_game :: proc(game: ^Game) {
    game.player = Player{x = 8, y = 8}
    game.render_texture = rl.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)

    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            if x == 0 || x == TILES_X-1 || y == 0 || y == TILES_Y-1 {
                game.world[y][x] = .STONE
            } else if (x + y) % 3 == 0 {
                game.world[y][x] = .WATER
            } else {
                game.world[y][x] = .GRASS
            }
        }
    }
}

update_player :: proc(player: ^Player) {
    if rl.IsKeyPressed(.W) do player.y -= 1
    if rl.IsKeyPressed(.S) do player.y += 1
    if rl.IsKeyPressed(.A) do player.x -= 1
    if rl.IsKeyPressed(.D) do player.x += 1

    player.x = math.clamp(player.x, 1, TILES_X - 2)
    player.y = math.clamp(player.y, 1, TILES_Y - 2)
}

draw_world :: proc(game: ^Game) {
    for y in 0..<TILES_Y {
        for x in 0..<TILES_X {
            tile_x := f32(x * TILE_SIZE)
            tile_y := f32(y * TILE_SIZE)

            color: rl.Color
            switch game.world[y][x] {
            case .GRASS: color = rl.GREEN
            case .STONE: color = rl.GRAY
            case .WATER: color = rl.BLUE
            }

            rl.DrawRectangle(i32(tile_x), i32(tile_y), TILE_SIZE, TILE_SIZE, color)
        }
    }
}

draw_player :: proc(player: ^Player) {
    pixel_x := player.x * TILE_SIZE
    pixel_y := player.y * TILE_SIZE
    rl.DrawRectangle(pixel_x, pixel_y, TILE_SIZE, TILE_SIZE, rl.RED)
}

main :: proc() {
    rl.SetConfigFlags({.WINDOW_UNDECORATED})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hollie RPG")
    rl.SetTargetFPS(60)

    game := Game{}
    init_game(&game)

    for !rl.WindowShouldClose() {
        update_player(&game.player)

        rl.BeginTextureMode(game.render_texture)
        rl.ClearBackground(rl.BLACK)
        draw_world(&game)
        draw_player(&game.player)
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
