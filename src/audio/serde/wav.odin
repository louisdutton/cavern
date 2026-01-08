package serde

import "core:fmt"
import "core:os"

// writes the a wav file to the filesystem
write_wav :: proc(filename: string, samples: []i16, sample_rate, channels, bits_per_sample: int) {
	file, err := os.open(filename, os.O_CREATE | os.O_WRONLY | os.O_TRUNC, 0o644)
	if err != 0 {
		fmt.printf("Failed to create file: %s\n", filename)
		return
	}
	defer os.close(file)

	BITS_PER_BYTE :: 8

	// header
	data_size := len(samples) * size_of(i16)
	chunk_size := u32(36 + data_size)
	byte_rate := u32(sample_rate * channels * bits_per_sample / BITS_PER_BYTE)
	block_align := u16(channels * bits_per_sample / BITS_PER_BYTE)

	os.write_string(file, "RIFF")
	os.write_ptr(file, &chunk_size, size_of(u32))
	os.write_string(file, "WAVE")

	os.write_string(file, "fmt ")
	subchunk1_size := u32(16)
	audio_format := u16(1)
	channels := u16(channels)
	sample_rate := u32(sample_rate)
	bits_per_sample := u16(bits_per_sample)

	os.write_ptr(file, &subchunk1_size, size_of(u32))
	os.write_ptr(file, &audio_format, size_of(u16))
	os.write_ptr(file, &channels, size_of(u16))
	os.write_ptr(file, &sample_rate, size_of(u32))
	os.write_ptr(file, &byte_rate, size_of(u32))
	os.write_ptr(file, &block_align, size_of(u16))
	os.write_ptr(file, &bits_per_sample, size_of(u16))

	os.write_string(file, "data")
	data_size_u32 := u32(data_size)
	os.write_ptr(file, &data_size_u32, size_of(u32))

	// body
	os.write_ptr(file, raw_data(samples), data_size)
}
