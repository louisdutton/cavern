package main

import "core:math"
import "core:math/rand"

WaveType :: enum {
	SQUARE,
	SAWTOOTH,
	TRIANGLE,
	NOISE,
}

SFXParams :: struct {
	wave_type:    WaveType,
	frequency:    f32,
	duration:     f32,
	envelope:     Envelope,
	freq_sweep:   f32,
	duty_cycle:   f32,
	vibrato_freq: f32,
	vibrato_amt:  f32,
}

generate_wave :: proc(wave_type: WaveType, phase: f32, duty_cycle: f32) -> f32 {
	switch wave_type {
	case .SQUARE: return phase < duty_cycle ? 1 : -1
	case .SAWTOOTH: return 2 * phase - 1
	case .TRIANGLE: return phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase
	case .NOISE: return f32(rand.float64()) * 2 - 1
	}
	return 0
}

generate_sfx :: proc(params: SFXParams, allocator := context.allocator) -> []i16 {
	num_samples := int(params.duration * SAMPLE_RATE)
	samples := make([]i16, num_samples, allocator)

	phase: f32 = 0.0
	frequency := params.frequency

	for i in 0 ..< num_samples {
		t := f32(i) / SAMPLE_RATE

		if params.freq_sweep != 0 {
			frequency = params.frequency + params.freq_sweep * t
		}

		if params.vibrato_freq > 0 {
			freq_mod :=
				1.0 + params.vibrato_amt * math.sin(2.0 * math.PI * params.vibrato_freq * t)
			frequency *= freq_mod
		}

		wave := generate_wave(params.wave_type, phase, params.duty_cycle)
		envelope := apply_envelope(t, params.duration, params.envelope)
		sample := wave * envelope

		samples[i] = i16(sample * 32767.0)

		phase += frequency / SAMPLE_RATE
		phase = math.mod(phase, 1.0)
	}

	return samples
}
