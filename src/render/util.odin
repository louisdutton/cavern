package render

import rl "vendor:raylib"

clear_background :: proc() {
	rl.ClearBackground(theme[.BASE])
}

draw_pixel :: proc(pos: Vec2, colour: ThemeColor) {
	rl.DrawPixel(i32(pos.x), i32(pos.y), theme[colour])
}

draw_pixel_alpha :: proc(pos: Vec2, colour: ThemeColor, alpha: f32 = 1) {
	col := rl.ColorAlpha(theme[colour], alpha)
	rl.DrawPixel(i32(pos.x), i32(pos.y), col)
}

draw_rect :: proc(pos: Vec2, size: Vec2, colour: ThemeColor, alpha: f32 = 1) {
	col := rl.ColorAlpha(theme[colour], alpha)
	rl.DrawRectangle(
		i32(pos.x * TILE_SIZE),
		i32(pos.y * TILE_SIZE),
		i32(size.x * TILE_SIZE),
		i32(size.y * TILE_SIZE),
		col,
	)
}
