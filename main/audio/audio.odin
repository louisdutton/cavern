package audio

import rl "vendor:raylib"

SoundKind :: enum {
	CLICK,
	COLLECT,
	DESTROY,
	GROWL,
	HURT,
	LOCKED,
	METAL,
	PICKUP,
	UNLOCK,
}

@(private)
sound_paths := [SoundKind]cstring {
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

@(private)
sounds: [SoundKind]rl.Sound

DEFAULT_VOLUME :: 0.2

init :: proc() {
	rl.InitAudioDevice()
	rl.SetMasterVolume(DEFAULT_VOLUME)
	for kind in SoundKind {
		sounds[kind] = rl.LoadSound(sound_paths[kind])
	}

	music_init()
}

play :: proc(kind: SoundKind, base_pitch: f32 = 1.0) {
	final_pitch := base_pitch
	rl.SetSoundPitch(sounds[kind], final_pitch)
	rl.PlaySound(sounds[kind])
}

fini :: proc() {
	rl.UnloadMusicStream(music)
	for sound in sounds {
		rl.UnloadSound(sound)
	}

	rl.CloseAudioDevice()
}
