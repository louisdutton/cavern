package main

Shake_Kind :: enum {
	SMALL  = 10,
	MEDIUM = 15,
	LARGE  = 20,
}

shake_add :: proc(kind: Shake_Kind) {
	game.screen_shake = max(game.screen_shake, int(kind))
}

shake_update :: proc() {
	SHAKE_DECAY :: 8
	game.screen_shake = max(0, game.screen_shake - SHAKE_DECAY)
}
