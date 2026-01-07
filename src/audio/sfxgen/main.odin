package main

import "core:fmt"
import "core:os"
import "core:strings"

SAMPLE_RATE :: 22050
BITS_PER_SAMPLE :: 16
CHANNELS :: 1

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usage: sfx_tool <preset> [-w]")
		fmt.println("Presets: jump, shoot, hit, pickup, explosion, powerup, blip, laser")
		fmt.println("Options:")
		fmt.println("  -w    Write to file instead of playing")
		return
	}

	preset := os.args[1]
	write_mode := len(os.args) > 2 && os.args[2] == "-w"

	sfx, ok := get_preset(preset)
	if !ok {
		fmt.printf("Unknown preset: %s\n", preset)
		return
	}

	samples := generate_sfx(sfx)
	defer delete(samples)

	if write_mode {
		filename := strings.concatenate({preset, ".wav"}, context.temp_allocator)
		write_file(filename, samples)
	} else {
		fmt.printf("Playing: %s\n", preset)
		play_samples(samples)
	}
}
