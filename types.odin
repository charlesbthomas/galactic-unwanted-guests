
package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

RectCollider :: struct {
    offset: Vec2, // Offset from the owner's position
    height: f32,
    width:  f32,
}

Vec2 :: [2]f32

Entity :: struct {
    is_player: bool,
    pos:       Vec2,
    tex:       rl.Texture,
    collider:  ^RectCollider,
}
World :: struct {
    entities: [dynamic]Entity,
}
