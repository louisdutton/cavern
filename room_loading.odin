package main

load_current_room :: proc() {
	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
	game.world = &room.tiles
}

