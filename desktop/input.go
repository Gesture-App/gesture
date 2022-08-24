package main

import (
	"encoding/json"
	"fmt"

	"github.com/ansonyuu/gesture/cursors"
	"github.com/go-vgo/robotgo"
)

type Vec3 struct {
	X float32 `json:"x"`
	Y float32 `json:"y"`
	Z float32 `json:"z"`
}

type InputJson struct {
	Left  Vec3 `json:"left"`
	Right Vec3 `json:"right"`
}

func normalize(f float32, mult int) int {
	r := int(((f + 1) / 2) * float32(mult))
	if r < 0 {
		return 0
	} else {
		return r
	}
}

func HandleInput(buf []byte) {
	input := InputJson{}
	json.Unmarshal(buf, &input)

	sx, sy := robotgo.GetScreenSize()
	x, y := normalize(input.Left.X, sx), normalize(-input.Left.Y, sy)

	fmt.Fprintf(Writer, "Left hand   x:%0.2f y:%0.2f z:%0.2f\nRight hand  x:%0.2f y:%0.2f z:%0.2f\nMouse pos   x:%00d y:%00d\n", input.Left.X, input.Left.Y, input.Left.Z, input.Right.X, input.Right.Y, input.Right.Z, x, y)
	cursors.Cursor.AddPoint(cursors.Vec {
    X: float64(x),
    Y: float64(y),
	})
}
