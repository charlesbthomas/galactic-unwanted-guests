package game

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

RectCollider :: struct {
	pos:    Vec2,
	height: f32,
	width:  f32,
}

Vec2 :: [2]f32
Entity :: struct {
	pos:      Vec2,
	tex:      rl.Texture,
	collider: ^RectCollider,
}
World :: struct {
	entities: [dynamic]Entity,
}


get_rect_bounds :: proc(pos: Vec2, collider: RectCollider) -> (min: Vec2, max: Vec2) {
	return Vec2 {
		pos.x - collider.width / 2,
		pos.y - collider.height / 2,
	}, Vec2{pos.x + collider.width / 2, pos.y + collider.height / 2}
}

aabb_intersect :: proc(a_pos: Vec2, a: RectCollider, b_pos: Vec2, b: RectCollider) -> bool {
	a_min, a_max := get_rect_bounds(a_pos, a)
	b_min, b_max := get_rect_bounds(b_pos, b)

	return(
		!(a_max[0] < b_min[0] ||
			a_min[0] > b_max[0] ||
			a_max[1] < b_min[1] ||
			a_min[1] > b_max[1]) \
	)
}

draw_rect_collider :: proc(pos: Vec2, collider: RectCollider) {
	min, max := get_rect_bounds(pos, collider)
	width := max[0] - min[0]
	height := max[1] - min[1]

	rl.DrawRectangleLines(i32(min[0]), i32(min[1]), i32(width), i32(height), rl.RED)
}

add_entity :: proc(world: ^World, e: Entity) {
	append(&world.entities, e)
}

textures: map[string]rl.Texture

load_texture :: proc(path: string) -> rl.Texture {
	if cached, ok := textures[path]; ok {
		return cached
	}

	loaded := rl.LoadTexture(strings.clone_to_cstring(path, context.temp_allocator))

	if loaded.id != 0 {
		textures[path] = loaded
	}

	return loaded
}


ray_aabb_intersect :: proc(
	origin: Vec2,
	dir: Vec2,
	max_dist: f32,
	aabb_min: Vec2,
	aabb_max: Vec2,
) -> (
	hit: bool,
	dist: f32,
) {
	inv_dir := Vec2{1.0 / dir[0], 1.0 / dir[1]}

	t1 := (aabb_min[0] - origin[0]) * inv_dir[0]
	t2 := (aabb_max[0] - origin[0]) * inv_dir[0]
	t3 := (aabb_min[1] - origin[1]) * inv_dir[1]
	t4 := (aabb_max[1] - origin[1]) * inv_dir[1]

	tmin := math.max(math.min(t1, t2), math.min(t3, t4))
	tmax := math.min(math.max(t1, t2), math.max(t3, t4))

	if tmax < 0 || tmin > tmax || tmin > max_dist {
		return false, max_dist
	}

	return true, tmin
}

NUM_RAYS :: 36
RAY_LENGTH :: 400

main :: proc() {
	rl.InitWindow(1280, 720, "Galactic Unwanted Guests")
	rl.SetTargetFPS(60)

	world: World
	player := load_texture("player.png")
	player_pos: Vec2


	box := Entity {
		pos      = Vec2{100, 100},
		collider = &RectCollider{pos = Vec2{0, 0}, width = 50, height = 50},
	}
	add_entity(&world, box)

	for !rl.WindowShouldClose() {
		origin := rl.GetMousePosition()

		input: Vec2

		kp := rl.GetKeyPressed()
		#partial switch kp {
		case .UP:
			input.y -= 1
		case .DOWN:
			input.y += 1
		case .LEFT:
			input.x -= 1
		case .RIGHT:
			input.x += 1
		}
		player_pos += la.normalize0(input) * rl.GetFrameTime() * 2000

		fmt.printf("Player position: %v\n", player_pos)
		fmt.printf("Input: %v\n", input)

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)


		for e in world.entities {
			// Draw each entity
			rl.DrawTextureV(e.tex, e.pos, rl.WHITE)

			if e.collider != nil {
				draw_rect_collider(e.pos, e.collider^)
			}
		}
		rl.DrawTextureV(player, player_pos, rl.WHITE)

		for i in 0 ..< NUM_RAYS {
			angle := (2.0 * math.PI) * f32(i) / f32(NUM_RAYS)
			dir := Vec2{math.cos(angle), math.sin(angle)}

			min_dist := RAY_LENGTH
			hit := false

			for e in world.entities {
				if e.collider == nil {
					continue
				}

				c := e.collider^
				aabb_min, aabb_max := get_rect_bounds(e.pos, c)

				did_hit, dist := ray_aabb_intersect(
					Vec2{origin.x, origin.y},
					dir,
					RAY_LENGTH,
					aabb_min,
					aabb_max,
				)

				if did_hit && int(dist) < min_dist {
					min_dist = int(dist)
					hit = true
				}
			}

			end := Vec2{origin.x, origin.y} + dir * f32(min_dist)
			rl.DrawLineV(origin, rl.Vector2{end[0], end[1]}, hit ? rl.YELLOW : rl.GRAY)
		}
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
