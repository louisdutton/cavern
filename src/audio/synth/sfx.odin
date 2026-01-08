package synth

import "core:math"

SFXParams :: struct {
	wave_type:    WaveKind,
	frequency:    f32,
	duration:     f32,
	envelope:     Envelope,
	freq_sweep:   f32,
	duty_cycle:   f32,
	vibrato_freq: f32,
	vibrato_amt:  f32,
}

generate_sfx :: proc(
	params: SFXParams,
	sample_rate: f32,
	allocator := context.allocator,
) -> []i16 {
	num_samples := int(params.duration * sample_rate)
	samples := make([]i16, num_samples, allocator)

	phase: f32 = 0
	frequency := params.frequency

	for i in 0 ..< num_samples {
		t := f32(i) / sample_rate

		if params.freq_sweep != 0 {
			frequency = params.frequency + params.freq_sweep * t
		}

		if params.vibrato_freq > 0 {
			freq_mod := 1 + params.vibrato_amt * math.sin(math.TAU * params.vibrato_freq * t)
			frequency *= freq_mod
		}

		wave := generate_wave(params.wave_type, phase, params.duty_cycle)
		envelope := apply_envelope(t, params.duration, params.envelope)
		sample := wave * envelope

		samples[i] = i16(sample * 32767)

		phase += frequency / sample_rate
		phase = math.mod(phase, 1)
	}

	return samples
}
