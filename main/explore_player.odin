package main

import "audio"

player_update :: proc() {
	game.move_timer -= 1
	if game.move_timer > 0 do return
	game.move_timer = MOVE_DELAY

	dir := input_get_direction()
	if is_zero_vec2(dir) do return
	next := dir + game.player.position

	if player_handle_room_boundary(next) do return

	kind := world_get(next)
	switch kind {

	// pickup items
	case .KEY, .SWORD, .SHIELD:
		world_set(next, .GRASS)
		audio.play_sound(.PICKUP)
		append(&game.inventory, Item{kind = kind, position = next, target = game.player.position})
		player_move(next)

	// destory secret walls
	case .SECRET_WALL:
		world_set(next, .GRASS)
		add_screen_shake(20)
		player_move(next)
		audio.play_sound(.DESTROY)

	// unlock door
	case .LOCKED_DOOR: if inventory_get_count(.KEY) > 0 {
				inventory_consume(.KEY)

				if dir, ok := get_door_direction(next).?; ok {
					unlock_door_connection(dir)
					add_screen_shake(15)
					audio.play_sound(.UNLOCK)
					audio.play_sound(.DESTROY)
				}

				player_move(next)
			}

	// push tiles
	case .BOULDER:
		push_dir := next - game.player.position

		if can_push_boulder(next, push_dir) {
			push_boulder(next, push_dir)
			player_move(next)
			audio.play_sound(.METAL)
		}

	// regular movement
	case .GRASS, .ENEMY:
		player_move(next)
		audio.play_sound(.CLICK)

	// proceed to next floor
	case .EXIT:
		game.floor_number += 1
		explore_init()
		audio.play_sound(.UNLOCK)

	// non-traversable tiles
	case .STONE:
	}
}

// Moves the player and their inventory
player_move :: proc(pos: Vec2) {
	inventory_update(game.player.position)
	game.player.position = pos
}

// Handles transitions at the room threshold and returns true if
// a transition has taken place
player_handle_room_boundary :: proc(pos: Vec2) -> bool {
	room := &game.floor_layout[game.room_coords.y][game.room_coords.x]
	if pos.x >= ROOM_SIZE && room.connections[.EAST] {
		game.room_coords.x += 1
		game.player.x = 0
		load_current_room()
		return true
	} else if pos.x < 0 && room.connections[.WEST] {
		game.room_coords.x -= 1
		game.player.x = ROOM_SIZE - 1
		load_current_room()
		return true
	} else if pos.y < 0 && room.connections[.NORTH] {
		game.room_coords.y -= 1
		game.player.y = ROOM_SIZE - 1
		load_current_room()
		return true
	} else if pos.y >= ROOM_SIZE && room.connections[.SOUTH] {
		game.room_coords.y += 1
		game.player.y = 0
		load_current_room()
		return true
	}

	return false
}
