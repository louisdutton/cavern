package hollie

import rl "vendor:raylib"
import "core:math"

GAME_WIDTH :: 64
GAME_HEIGHT :: 64
WINDOW_WIDTH :: 256
WINDOW_HEIGHT :: 256
SCALE :: 4
TILE_SIZE :: 8

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
    world: [8][8]Tile,
    render_texture: rl.RenderTexture2D,
}

init_game :: proc(game: ^Game) {
    game.player = Player{x = 32, y = 32}
    game.render_texture = rl.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)

    for y in 0..<8 {
        for x in 0..<8 {
            if x == 0 || x == 7 || y == 0 || y == 7 {
                game.world[y][x] = .STONE
            } else if (x + y) % 4 == 0 {
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

    player.x = math.clamp(player.x, 0, GAME_WIDTH - 1)
    player.y = math.clamp(player.y, 0, GAME_HEIGHT - 1)
}

draw_world :: proc(game: ^Game) {
    for y in 0..<8 {
        for x in 0..<8 {
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
    rl.DrawRectangle(player.x, player.y, 2, 2, rl.RED)
}

main :: proc() {
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
