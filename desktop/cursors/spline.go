package cursors

type Spline struct {
	Points      []Vec
	Lengths     []float64
	Prev        *Vec
	TotalLength float64
}

func NewSpline() *Spline {
	return &Spline{
		Points:  []Vec{},
		Lengths: []float64{},
		Prev:    nil,
	}
}

func (s *Spline) AddPoint(v Vec) {
  if s.Prev != nil {
    length := v.Dist(*s.Prev)
    s.Lengths = append(s.Lengths, length)
    s.TotalLength += length
    s.Points = append(s.Points, v)
  }

  s.Prev = &v
}

func (s *Spline) Clear() {
  if s.Prev != nil {
    s.Points = []Vec{*s.Prev}
  } else {
    s.Points = []Vec{}
  }
  s.TotalLength = 0
}

func min(a, b int) int {
    if a < b {
        return a
    }
    return b
}

// wizardry from https://github.com/steveruizok/perfect-cursors/blob/9758dedee9c562427d33b539cee51de3abfbb764/perfect-cursors/src/spline.ts#L33
func (s *Spline) PredictPointFromSpline(rt float64) Vec {
  l := len(s.Points) - 1
  d := int(rt)
  p1 := min(d + 1, l)
  p2 := min(p1 + 1, l)
  p3 := min(p2 + 1, l)
  p0 := p1 - 1
  t := rt - float64(d)
  tt := t * t
  ttt := tt * t
  q1 := -ttt + 2 * tt - t
  q2 := 3 * ttt - 5 * tt + 2
  q3 := -3 * ttt + 4 * tt + t
  q4 := ttt - tt

  x := (s.Points[p0].X * q1 + s.Points[p1].X * q2 + s.Points[p2].X * q3 + s.Points[p3].X * q4) / 2
  y := (s.Points[p0].Y * q1 + s.Points[p1].Y * q2 + s.Points[p2].Y * q3 + s.Points[p3].Y * q4) / 2
  return Vec {
    X: x,
    Y: y,
  }
}
