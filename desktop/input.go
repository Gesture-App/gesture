package main

import (
	"encoding/json"
	"flag"
	"fmt"

	"github.com/ansonyuu/gesture/cursors"
	"github.com/go-vgo/robotgo"
)

type Vec3 struct {
	X     float32 `json:"x"`
	Y     float32 `json:"y"`
	Z     float32 `json:"z"`
	Shape string  `json:"shape"`
}

type InputJson struct {
	Left  Vec3 `json:"left"`
	Right Vec3 `json:"right"`
}

var CurInput *InputJson

// Virtual mode (control mouse directly)
var VCursor *cursors.InterpolatedCursor

// Server mode (report via WebSockets)
var LCursor *cursors.InterpolatedCursor
var RCursor *cursors.InterpolatedCursor
var LShape = "unknown"
var RShape = "unknown"

func init() {
	flag.Parse()
	if *IsServerMode {
		LCursor = cursors.NewInterpolatedCursor(func(point cursors.Vec) {
			CurInput.Left = Vec3{
				X:     float32(point.X),
				Y:     float32(point.Y),
				Z:     float32(point.Z),
				Shape: LShape,
			}
		})
		RCursor = cursors.NewInterpolatedCursor(func(point cursors.Vec) {
			CurInput.Right = Vec3{
				X:     float32(point.X),
				Y:     float32(point.Y),
				Z:     float32(point.Z),
				Shape: RShape,
			}
		})
	} else {
		VCursor = cursors.NewInterpolatedCursor(func(point cursors.Vec) {
			robotgo.Move(int(point.X), int(point.Y))
		})
	}
}

func mapToMouseState(b bool) string {
	if b {
		return "down"
	} else {
		return "up"
	}
}

func clamp(x, min, max int) int {
	if x < min {
		return min
	} else if x > max {
		return max
	}
	return x
}

func adjustVec3(input Vec3) Vec3 {
	x := 1 - ((input.X + 0.7) / 1.2)
	y := 1 - (input.Y / 1.2)
	z := input.Z * 4
	return Vec3{
		X:     x,
		Y:     y,
		Z:     z,
		Shape: input.Shape,
	}
}

func HandleInput(buf []byte) {
	input := InputJson{}
	json.Unmarshal(buf, &input)

	LShape = input.Left.Shape
	RShape = input.Right.Shape
	if *IsServerMode {

		adjustedL := adjustVec3(input.Left)
		adjustedR := adjustVec3(input.Right)

		LCursor.AddPoint(cursors.Vec{
			X: float64(adjustedL.X),
			Y: float64(adjustedL.Y),
			Z: float64(adjustedL.Z),
		})

		RCursor.AddPoint(cursors.Vec{
			X: float64(adjustedR.X),
			Y: float64(adjustedR.Y),
			Z: float64(adjustedR.Z),
		})

	} else {
		sx, sy := robotgo.GetScreenSize()
		adjustedInput := adjustVec3(input.Right)

		x := clamp(int(adjustedInput.X*float32(sx)), 0, sx)
		y := clamp(int(adjustedInput.Y*float32(sy)), 0, sy)

		fmt.Fprintf(Writer, "Left hand   x:%0.2f y:%0.2f z:%0.2f\nRight hand  x:%0.2f y:%0.2f z:%0.2f\nMouse pos   x:%00d y:%00d Left Pose: %s   Right Pose: %s\n", input.Left.X, input.Left.Y, input.Left.Z, input.Right.X, input.Right.Y, input.Right.Z, x, y, LShape, RShape)

		// interp position
		VCursor.AddPoint(cursors.Vec{
			X: float64(x),
			Y: float64(y),
			Z: float64(adjustedInput.Z),
		})

		// click
		robotgo.Toggle("left", mapToMouseState(RShape == "closed"))
	}
}
