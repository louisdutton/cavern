package main

can_push :: proc(pos: Vec2) -> bool {
	return is_in_bounds(pos) && world_get(pos) == .GRASS
}

push_tile :: proc(from, to: Vec2) {
	world_set(from, .GRASS)
	world_set(to, .BOULDER)
}
