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

Theme :: [ThemeColor]rl.Color

THEME_A :: Theme {
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

THEME_B :: Theme {
	.TRANSPARENT = {0, 0, 0, 0},
	.BASE        = {80, 100, 80, 255},
	.SURFACE     = {64, 150, 100, 255},
	.OVERLAY     = {64, 200, 100, 255},
	.BLUE        = {150, 180, 100, 255},
	.RED         = {243, 139, 168, 255},
	.TEAL        = {74, 144, 226, 255},
	.ORANGE      = {255, 220, 128, 255},
	.WHITE       = {220, 255, 220, 255},
	.GREEN       = {180, 255, 180, 255},
}

@(private)
themes := [?]Theme{THEME_A, THEME_B}
theme := themes[0]

change_theme :: proc(floor_number: int) {
	theme = themes[floor_number % 2]
}
