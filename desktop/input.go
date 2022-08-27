package main

import (
	"encoding/json"
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
  return Vec3 {
    X: x,
    Y: y,
    Z: z,
    Shape: input.Shape,
  }
}

func HandleInput(buf []byte) {
	input := InputJson{}
	json.Unmarshal(buf, &input)
  
  if *IsServerMode {
    CurInput = &InputJson{
      Left: adjustVec3(input.Left),
      Right: adjustVec3(input.Right),
    }
  } else {
    sx, sy := robotgo.GetScreenSize()
    adjustedInput := adjustVec3(input.Right)

    x := clamp(int(adjustedInput.X * float32(sx)), 0, sx)
    y := clamp(int(adjustedInput.Y * float32(sy)), 0, sy)
    right_click := input.Left.Shape == "closed"
    left_click := input.Right.Shape == "closed"

    fmt.Fprintf(Writer, "Left hand   x:%0.2f y:%0.2f z:%0.2f\nRight hand  x:%0.2f y:%0.2f z:%0.2f\nMouse pos   x:%00d y:%00d l_click: %t r_click: %t\n", input.Left.X, input.Left.Y, input.Left.Z, input.Right.X, input.Right.Y, input.Right.Z, x, y, left_click, right_click)
    // handle events
    // interp position
    cursors.Cursor.AddPoint(cursors.Vec{
      X: float64(x),
      Y: float64(y),
    })

    // click
    robotgo.Toggle("left", mapToMouseState(left_click))
  }
}
