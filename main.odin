package game

import "core:fmt"
import la "core:math/linalg"
import rl "vendor:raylib"

Vec2 :: [2]f32

main :: proc() {
	rl.InitWindow(1280, 720, "Galactic Unwanted Guests")

	player := rl.LoadTexture("player.png")
	player_pos: Vec2

	for !rl.WindowShouldClose() {
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
		player_pos += la.normalize0(input) * rl.GetFrameTime() * 200 * 1000

		fmt.printf("Player position: %v\n", player_pos)
		fmt.printf("Input: %v\n", input)

		rl.BeginDrawing()
		rl.ClearBackground({160, 200, 255, 255})
		rl.DrawTextureV(player, player_pos, rl.WHITE)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
