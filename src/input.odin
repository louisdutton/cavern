package main

import rl "vendor:raylib"

Direction :: enum {
	UP,
	DOWN,
	RIGHT,
	LEFT,
}

dir_to_vec2 := [Direction]Vec2 {
	.UP    = {0, -1},
	.DOWN  = {0, 1},
	.LEFT  = {-1, 0},
	.RIGHT = {1, 0},
}

@(private = "file")
prev_input: Vec2 = {}
@(private = "file")
current_input: Vec2 = {}

get_raw_input :: proc() -> Vec2 {
	return {
		int(rl.IsKeyDown(.D) || rl.IsKeyDown(.L)) - int(rl.IsKeyDown(.A) || rl.IsKeyDown(.H)),
		int(rl.IsKeyDown(.S) || rl.IsKeyDown(.J)) - int(rl.IsKeyDown(.W) || rl.IsKeyDown(.K)),
	}
}

// FIXME: new direction (from diagonal input) is only correct for one
// step and then it reverts to the old direction even though inputs haven't changed
input_get_direction :: proc() -> Vec2 {
	prev_input = current_input
	current_input = get_raw_input()

	if current_input == {} do return {}

	if current_input.x != 0 && current_input.y != 0 {
		if prev_input.x == 0 {
			return {current_input.x, 0}
		} else if prev_input.y == 0 {
			return {0, current_input.y}
		} else {
			return {current_input.x, 0}
		}
	}

	return current_input
}

// TODO: make this generic for any int array
is_zero_vec2 :: proc(v: Vec2) -> bool {
	return v.x == 0 && v.y == 0
}
