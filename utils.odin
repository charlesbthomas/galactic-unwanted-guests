package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"


textures: map[string]rl.Texture
load_texture :: proc(path: string) -> rl.Texture {
    if cached, ok := textures[path]; ok {
        return cached
    }

    loaded := rl.LoadTexture(
        strings.clone_to_cstring(path, context.temp_allocator),
    )

    if loaded.id != 0 {
        textures[path] = loaded
    }

    return loaded
}


get_rect_bounds :: proc(
    pos: Vec2,
    collider: RectCollider,
) -> (
    min: Vec2,
    max: Vec2,
) {
    center := pos + collider.offset
    return Vec2 {
        center.x - collider.width / 2,
        center.y - collider.height / 2,
    }, Vec2{center.x + collider.width / 2, center.y + collider.height / 2}
}

aabb_intersect :: proc(
    a_pos: Vec2,
    a: RectCollider,
    b_pos: Vec2,
    b: RectCollider,
) -> bool {
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

    rl.DrawRectangleLines(
        i32(min[0]),
        i32(min[1]),
        i32(width),
        i32(height),
        rl.RED,
    )
}

add_entity :: proc(world: ^World, e: Entity) {
    append(&world.entities, e)
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
