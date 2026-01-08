package main

import "../render"
import "core:math"
import "core:math/rand"

FPS :: 32
TRANSITION_DURATION :: FPS * 0.75
SCREEN_SIZE :: 256
BLOCK_SIZE :: 1

Transition :: struct {
	kind:   Transition_Kind,
	frames: int,
	// TODO add on-completion callback
}

// TODO: implement more transitions
Transition_Kind :: enum {
	CIRCLE,
}

transition_init :: proc(t: ^Transition) {
	t.frames = TRANSITION_DURATION
	t.kind = rand.choice_enum(Transition_Kind)
}

transition_update :: proc(t: ^Transition) {
	t.frames -= 1
	if t.frames == 0 {
		// TODO: completion callback
	}
}

transition_draw :: proc(t: ^Transition) {
	progress := 1 - f32(t.frames) / f32(TRANSITION_DURATION)

	switch t.kind {
	case .CIRCLE: transition_draw_circle(progress)
	}
}

transition_draw_circle :: proc(progress: f32) {
	max_dist := math.sqrt(f32(SCREEN_SIZE * SCREEN_SIZE * 2))
	threshold := progress * max_dist
	center := f32(SCREEN_SIZE) / 2

	for y := 0; y < SCREEN_SIZE; y += BLOCK_SIZE {
		for x := 0; x < SCREEN_SIZE; x += BLOCK_SIZE {
			block_center_x := f32(x) + f32(BLOCK_SIZE) / 2
			block_center_y := f32(y) + f32(BLOCK_SIZE) / 2

			dx := block_center_x - center
			dy := block_center_y - center
			dist := math.sqrt(dx * dx + dy * dy)

			if dist <= threshold {
				render.draw_rect({x, y}, {BLOCK_SIZE, BLOCK_SIZE}, .BASE)
			}
		}
	}
}
