package cursors

import "math"

type Vec struct {
  X float64
  Y float64
}

func (v Vec) Dist(u Vec) float64 {
  return math.Hypot(v.X - u.X, v.Y - u.Y)
}
