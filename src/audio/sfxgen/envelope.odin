package main

Envelope :: struct {
	attack:  f32,
	decay:   f32,
	sustain: f32,
	release: f32,
}

apply_envelope :: proc(t, duration: f32, env: Envelope) -> f32 {
	attack_end := env.attack
	decay_end := attack_end + env.decay
	release_start := duration - env.release

	if t < attack_end {
		return t / attack_end
	} else if t < decay_end {
		return 1.0 - (1.0 - env.sustain) * (t - attack_end) / env.decay
	} else if t < release_start {
		return env.sustain
	} else {
		return env.sustain * (1.0 - (t - release_start) / env.release)
	}
}
