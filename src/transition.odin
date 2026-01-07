package main

import "core:math"
import "core:math/rand"
import "render"
import rl "vendor:raylib"

TRANSITION_DURATION :: FPS * 0.75
BLOCK_SIZE :: 1

Transition :: struct {
	kind:   Transition_Kind,
	frames: int,
}

// TODO: implement more transitions
Transition_Kind :: enum {
	CIRCLE,
}

transition_init :: proc() {
	game.transition.frames = TRANSITION_DURATION
	game.transition.kind = rand.choice_enum(Transition_Kind)
}

transition_update :: proc() {
	game.transition.frames -= 1
	if game.transition.frames == 0 do transition_fini()
}

transition_draw :: proc() {
	progress := 1 - f32(game.transition.frames) / f32(TRANSITION_DURATION)

	switch game.transition.kind {
	case .CIRCLE: transition_draw_circle(progress)
	}
}

transition_draw_circle :: proc(progress: f32) {
	max_dist := math.sqrt(f32(GAME_SIZE * GAME_SIZE * 2))
	threshold := progress * max_dist
	center := f32(GAME_SIZE) / 2

	for y := i32(0); y < GAME_SIZE; y += BLOCK_SIZE {
		for x := i32(0); x < GAME_SIZE; x += BLOCK_SIZE {
			block_center_x := f32(x) + f32(BLOCK_SIZE) / 2
			block_center_y := f32(y) + f32(BLOCK_SIZE) / 2

			dx := block_center_x - center
			dy := block_center_y - center
			dist := math.sqrt(dx * dx + dy * dy)

			if dist <= threshold {
				rl.DrawRectangle(x, y, BLOCK_SIZE, BLOCK_SIZE, render.theme[.BASE])
			}
		}
	}
}

transition_fini :: proc() {
	combat_init()
}
