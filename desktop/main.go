package main

import (
	"time"

  
  "github.com/ansonyuu/gesture/tui"
	"tinygo.org/x/bluetooth"
)

var adapter = bluetooth.DefaultAdapter

type ReceiverCtx struct {
	isScanning bool
	uuid       bluetooth.UUID
}

var DEFAULT_PARAMS = bluetooth.ConnectionParams {
  ConnectionTimeout: bluetooth.NewDuration(5 * time.Second),
  MinInterval: bluetooth.NewDuration(time.Second / 60),
  MaxInterval: bluetooth.NewDuration(time.Second / 30),
}

func main() {
  tui.Header()
	gesture_service_uuid, _ := bluetooth.ParseUUID("f4f8cc56-30e7-4a68-9d38-da0b16a20e82")
	ctx := ReceiverCtx {
	  isScanning: true,
    uuid: gesture_service_uuid,
	}
	scan(&ctx)
}

func scan(ctx *ReceiverCtx) {
	must("enable BLE stack", adapter.Enable())
	err := adapter.Scan(func(adapter *bluetooth.Adapter, device bluetooth.ScanResult) {
		if device.HasServiceUUID(ctx.uuid) && device.RSSI >= -50 {
			poll(ctx, device)
			adapter.StopScan()
		}
	})
	must("start scan", err)
}

func poll(ctx *ReceiverCtx, res bluetooth.ScanResult) {
  tui.DeviceFound(res.Address.String())
  device, err := adapter.Connect(res.Address, DEFAULT_PARAMS)
  must("connect to device properly", err)
  services, discoveryErr := device.DiscoverServices([]bluetooth.UUID{ctx.uuid})
  print("%+v", services)
  must("discover list of services", discoveryErr)
}

func must(action string, err error) {
	if err != nil {
		panic("failed to " + action + ": " + err.Error())
	}
}
