package main

import rl "vendor:raylib"

sound_paths := [SoundEffect]cstring{
	.CLICK   = "res/click.wav",
	.COLLECT = "res/collect.wav",
	.DESTROY = "res/destroy.wav",
	.GROWL   = "res/growl.wav",
	.HURT    = "res/hurt.wav",
	.LOCKED  = "res/locked.wav",
	.METAL   = "res/metal.wav",
	.PICKUP  = "res/pickup.wav",
	.UNLOCK  = "res/unlock.wav",
}

play_sound :: proc(sound: SoundEffect, base_pitch: f32 = 1.0) {
	variation := 0.8 + f32((game.player.x + game.player.y) % 5) * 0.1
	final_pitch := base_pitch * variation
	rl.SetSoundPitch(game.sounds[sound], final_pitch)
	rl.PlaySound(game.sounds[sound])
}