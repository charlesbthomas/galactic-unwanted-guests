package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

DEBUG :: true
NUM_RAYS :: 100
RAY_LENGTH :: 100

main :: proc() {
    rl.InitWindow(1280, 720, "Raycasting Fun")
    rl.SetTargetFPS(60)

    world: World

    player_entity := Entity {
        is_player = true,
        pos       = Vec2{200, 200},
        tex       = load_texture("player.png"),
        collider  = &RectCollider {
            offset = Vec2{30, 36},
            width = 65,
            height = 73,
        },
    }
    add_entity(&world, player_entity)

    // add 4 boxes to the world
    for i in 0 ..< 4 {
        pos := Vec2{f32(i * 100 + 200), f32(i * 100 + 200)}
        box := Entity {
            pos      = pos,
            collider = &RectCollider {
                offset = Vec2{0, 0},
                width = 50,
                height = 50,
            },
        }


        add_entity(&world, box)
    }


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

        for &e in world.entities {

            if e.is_player {
                e.pos += linalg.normalize0(input) * rl.GetFrameTime() * 2000
                continue
            }
        }


        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)


        for e in world.entities {
            rl.DrawTextureV(e.tex, e.pos, rl.WHITE)
            if e.collider != nil && DEBUG {
                draw_rect_collider(e.pos, e.collider^)
            }
        }

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
            rl.DrawLineV(
                origin,
                rl.Vector2{end[0], end[1]},
                hit ? rl.YELLOW : rl.GRAY,
            )
        }
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    rl.CloseWindow()
}
