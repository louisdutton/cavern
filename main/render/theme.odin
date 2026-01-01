package render

import rl "vendor:raylib"

ThemeColor :: enum {
	TRANSPARENT,
	BASE,
	SURFACE,
	OVERLAY,
	GREEN,
	BLUE,
	ORANGE,
	WHITE,
	TEAL,
	RED,
}

theme := [ThemeColor]rl.Color {
	.TRANSPARENT = {0, 0, 0, 0},
	.BASE        = {30, 30, 46, 255},
	.SURFACE     = {49, 50, 68, 255},
	.OVERLAY     = {108, 112, 134, 255},
	.BLUE        = {137, 180, 250, 255},
	.RED         = {243, 139, 168, 255},
	.TEAL        = {74, 144, 226, 255},
	.ORANGE      = {255, 184, 108, 255},
	.WHITE       = {255, 255, 255, 255},
	.GREEN       = {166, 227, 161, 255},
}
