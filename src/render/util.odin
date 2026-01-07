package render

import rl "vendor:raylib"

clear_background :: proc() {
	rl.ClearBackground(theme[.BASE])
}

draw_pixel :: proc(position: [2]int, colour: ThemeColor) {
	rl.DrawPixel(i32(position.x), i32(position.y), theme[colour])
}

draw_pixel_alpha :: proc(position: [2]int, colour: ThemeColor, alpha: f32 = 1.0) {
	col := rl.ColorAlpha(theme[colour], alpha)
	rl.DrawPixel(i32(position.x), i32(position.y), col)
}
