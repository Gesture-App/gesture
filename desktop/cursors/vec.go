package cursors

import "math"

type Vec struct {
  X float64
  Y float64
  Z float64
}

func (v Vec) Dist(u Vec) float64 {
  dx2 := math.Pow((v.X - u.X), 2)
  dy2 := math.Pow((v.Y - u.Y), 2)
  dz2 := math.Pow((v.Z - u.Z), 2)
  return math.Sqrt(dx2 + dy2 + dz2) 
}
