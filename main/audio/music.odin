package audio

import rl "vendor:raylib"

@(private)
music: rl.Music

@(private)
music_init :: proc() {
	music = rl.LoadMusicStream("res/music.mp3")
	rl.PlayMusicStream(music)
}

music_update :: proc() {
	rl.UpdateMusicStream(music)
}
