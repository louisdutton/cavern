package main

import "../synth"
import "core:reflect"
import "core:strings"

Preset :: enum {
	JUMP,
	SHOOT,
	HIT,
	PICKUP,
	EXPLOSION,
	POWERUP,
	BLIP,
	LASER,
}

presets := [Preset]synth.SFXParams {
	.JUMP = {
		wave_type = .SQUARE,
		frequency = 200.0,
		duration = 0.3,
		envelope = {attack = 0.01, decay = 0.05, sustain = 0.3, release = 0.1},
		freq_sweep = 400.0,
		duty_cycle = 0.5,
	},
	.SHOOT = {
		wave_type = .SQUARE,
		frequency = 400.0,
		duration = 0.15,
		envelope = {attack = 0.01, decay = 0.02, sustain = 0.2, release = 0.05},
		freq_sweep = -800.0,
		duty_cycle = 0.25,
	},
	.HIT = {
		wave_type = .NOISE,
		frequency = 0,
		duration = 0.2,
		envelope = {attack = 0.01, decay = 0.05, sustain = 0.1, release = 0.08},
		freq_sweep = 0,
		duty_cycle = 0.5,
	},
	.PICKUP = {
		wave_type = .TRIANGLE,
		frequency = 600.0,
		duration = 0.25,
		envelope = {attack = 0.01, decay = 0.05, sustain = 0.5, release = 0.1},
		freq_sweep = 200.0,
		duty_cycle = 0.5,
	},
	.EXPLOSION = {
		wave_type = .NOISE,
		frequency = 0,
		duration = 0.5,
		envelope = {attack = 0.01, decay = 0.1, sustain = 0.2, release = 0.2},
		freq_sweep = 0,
		duty_cycle = 0.5,
	},
	.POWERUP = {
		wave_type = .SQUARE,
		frequency = 200.0,
		duration = 0.4,
		envelope = {attack = 0.02, decay = 0.1, sustain = 0.6, release = 0.15},
		freq_sweep = 600.0,
		duty_cycle = 0.5,
		vibrato_freq = 8.0,
		vibrato_amt = 0.1,
	},
	.BLIP = {
		wave_type = .SQUARE,
		frequency = 800.0,
		duration = 0.05,
		envelope = {attack = 0.01, decay = 0.01, sustain = 0.5, release = 0.02},
		freq_sweep = 0,
		duty_cycle = 0.5,
	},
	.LASER = {
		wave_type = .SAWTOOTH,
		frequency = 1000.0,
		duration = 0.2,
		envelope = {attack = 0.01, decay = 0.03, sustain = 0.3, release = 0.05},
		freq_sweep = -1500.0,
		duty_cycle = 0.5,
	},
}

get_preset :: proc(str: string) -> (sfx: synth.SFXParams, ok: bool) {
	upper := strings.to_upper(str, context.temp_allocator)
	preset := reflect.enum_from_name(Preset, upper) or_return
	return presets[preset], true
}
