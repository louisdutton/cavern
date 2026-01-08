package synth

import "core:math/rand"

WaveKind :: enum {
	SQUARE,
	SAWTOOTH,
	TRIANGLE,
	NOISE,
}

generate_wave :: proc(wave_type: WaveKind, phase: f32, duty_cycle: f32) -> f32 {
	switch wave_type {
	case .SQUARE: return square(phase, duty_cycle)
	case .SAWTOOTH: return sawtooth(phase)
	case .TRIANGLE: return triangle(phase)
	case .NOISE: return noise_white()
	}
	return 0
}

square :: proc(phase, duty_cycle: f32) -> f32 {
	return phase < duty_cycle ? 1 : -1
}

triangle :: proc(phase: f32) -> f32 {
	return phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase
}

sawtooth :: proc(phase: f32) -> f32 {
	return 2 * phase - 1
}

noise_white :: proc() -> f32 {
	return f32(rand.float32()) * 2 - 1
}
