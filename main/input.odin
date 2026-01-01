package main

import rl "vendor:raylib"

Direction :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

// FIXME: disable diagonal movement
input_get_direction :: proc() -> Vec2 {
	return {
		int(rl.IsKeyDown(.D)) - int(rl.IsKeyDown(.A)),
		int(rl.IsKeyDown(.S)) - int(rl.IsKeyDown(.W)),
	}
}

// TODO: make this generic for any int array
is_zero_vec2 :: proc(v: Vec2) -> bool {
	return v.x == 0 && v.y == 0
}
