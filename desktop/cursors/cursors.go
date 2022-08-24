package cursors

import (
	"time"

	"github.com/go-vgo/robotgo"
)

var Cursor *InterpolatedCursor

func init() {
  Cursor = NewInterpolatedCursor(func(point Vec) {
    robotgo.Move(int(point.X), int(point.Y))
  })
}

const (
	Stopped = iota
	Idle
	Animating
)

type Edge struct {
	From     Vec
	To       Vec
	Start    int
	Duration time.Duration
}

type InterpolatedCursor struct {
	State         int
	Queue         []Edge
	Timestamp     time.Time
	Timeout       *time.Timer
	PrevPoint     *Vec
	Spline        *Spline
	Cb            func(point Vec)
}

func NewInterpolatedCursor(cb func(point Vec)) *InterpolatedCursor {
  return &InterpolatedCursor {
    State: Stopped,
    Queue: []Edge{},
    Timestamp: time.Now(),
    Timeout: nil,
    PrevPoint: nil,
    Spline: NewSpline(),
    Cb: cb,
  }
}

const MAX_INTERVAL = time.Millisecond * 300
func clamp(t time.Duration) time.Duration {
  if t > MAX_INTERVAL {
    return MAX_INTERVAL
  }
  return t
}

func (c *InterpolatedCursor) AddPoint(point Vec) {
  if c.Timeout != nil {
    c.Timeout.Stop()
    c.Timeout = nil
  }

  now := time.Now()
  duration := clamp(now.Sub(c.Timestamp))
  if c.PrevPoint == nil {
    c.Spline.Clear()
    c.PrevPoint = &point
    c.Spline.AddPoint(point)
    c.Cb(point)
    c.State = Stopped
    return
  }

  if c.State == Stopped {
    if c.PrevPoint.Dist(point) < 4 {
      c.Cb(point)
      return
    }
    c.Spline.Clear()
    c.Spline.AddPoint(*c.PrevPoint)
    c.Spline.AddPoint(*c.PrevPoint)
    c.Spline.AddPoint(point)
    c.State = Idle
  } else {
    c.Spline.AddPoint(point)
  }

  if duration < (time.Second / 30) {
    c.PrevPoint = &point
    c.Timestamp = time.Now()
    c.Cb(point)
    return
  }

  animation := Edge {
    Start: len(c.Spline.Points) - 3,
    From: *c.PrevPoint,
    To: point,
    Duration: duration,
  }

  c.PrevPoint = &point
  c.Timestamp = time.Now()
  switch c.State {
    case Idle:
      c.State = Animating
      c.AnimateNext(animation)
      break
    case Animating:
      c.Queue = append(c.Queue, animation)
      break
  }
}

func (c *InterpolatedCursor) AnimateNext(anim Edge) {
  start := time.Now()
  tick := time.NewTicker(time.Second / 30)
  t := float64(0)

  // hack to make timer tick instantly
  f := func(t float64) {
    predicted := c.Spline.PredictPointFromSpline(t + float64(anim.Start))
    c.Cb(predicted)
  }

  for t <= 1 && len(c.Spline.Points) > 0 {
    f(t)
    select {
    case <-tick.C:
      t = float64(time.Now().Sub(start)) / float64(anim.Duration)
      continue
    }
  }
  tick.Stop()

  if len(c.Queue) > 0 {
    next, new_q := c.Queue[0], c.Queue[1:]
    c.Queue = new_q
    c.State = Animating
    c.AnimateNext(next)
  } else {
    c.State = Idle
    c.Timeout = time.NewTimer(MAX_INTERVAL)
    go func() {
      <-c.Timeout.C
      c.State = Stopped
    }()
  }
}

func (c *InterpolatedCursor) Dispose() {
  c.Timeout.Stop()
  c.Timeout = nil
}
