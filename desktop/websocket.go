package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{}
var ticker = time.NewTicker(time.Second / 60)

func StartWSServer() {
  // TODO: make this more secure
  upgrader.CheckOrigin = func (r *http.Request) bool { return true }
  http.HandleFunc("/", serve)
  http.ListenAndServe("localhost:8888", nil)
}

func serve(w http.ResponseWriter, r *http.Request) {
  conn, err := upgrader.Upgrade(w, r, nil)
  if err != nil {
    fmt.Printf("upgrade err: %s", err.Error())
  }
  defer conn.Close()

  for {
    select {
    case <-TERM:
      ticker.Stop()
      return
    case <-ticker.C:
      if CurInput != nil {
        err = conn.WriteJSON(*CurInput)
        if err != nil {
          fmt.Printf("message write err: %s", err.Error())
        }
      }
    }
  }
}
