package render

import "core:math/rand"
import rl "vendor:raylib"

@(private)
render_texture: rl.RenderTexture2D
@(private)
game_size: f32
@(private)
window_size: f32

init :: proc(_window_size, _game_size: int) {
	window_size = f32(_window_size)
	game_size = f32(_game_size)
	render_texture = rl.LoadRenderTexture(i32(_game_size), i32(_game_size))
}

fini :: proc() {
	rl.UnloadRenderTexture(render_texture)
}

begin :: proc() {
	rl.BeginTextureMode(render_texture)
	clear_background()
}

end :: proc() {
	rl.EndTextureMode()
}

draw :: proc(screen_shake: int) {
	rl.BeginDrawing()

	shake_x := f32(0)
	shake_y := f32(0)
	if screen_shake > 0 {
		shake_x = (f32(rand.int31() % 5) - 2) * f32(screen_shake)
		shake_y = (f32(rand.int31() % 5) - 2) * f32(screen_shake)
	}

	dest_rect := rl.Rectangle{shake_x, shake_y, window_size, window_size}
	source_rect := rl.Rectangle{0, 0, game_size, -game_size}

	rl.DrawTexturePro(render_texture.texture, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)

	rl.EndDrawing()
}
