package main

import (
	"flag"
	"os"
	"os/signal"

	"time"

	"github.com/ansonyuu/gesture/tui"
	"github.com/gosuri/uilive"
	"tinygo.org/x/bluetooth"
)

var adapter = bluetooth.DefaultAdapter
var Writer = uilive.New()

var IsServerMode = flag.Bool("server", false, "whether to start Gesture in Websocket server mode (default is virtual mouse input)")

type ReceiverCtx struct {
	isScanning bool
	uuid       bluetooth.UUID
	device     *bluetooth.Device
	datastream *bluetooth.DeviceCharacteristic
}

var DEFAULT_PARAMS = bluetooth.ConnectionParams{
	ConnectionTimeout: bluetooth.NewDuration(10 * time.Second),
}

var TERM = make(chan os.Signal, 1)
var isConnected = false

func main() {
  flag.Parse()
	tui.Header()

	gesture_service_uuid, _ := bluetooth.ParseUUID("f4f8cc56-30e7-4a68-9d38-da0b16a20e82")
	ctx := ReceiverCtx{
		isScanning: true,
		uuid:       gesture_service_uuid,
	}

	signal.Notify(TERM, os.Interrupt)
	go func() {
		<-TERM
		if ctx.device != nil {
			ctx.device.Disconnect()
		}
		os.Exit(1)
	}()

	adapter.SetConnectHandler(func(addr bluetooth.Addresser, connected bool) {
		tui.ConnectionChange(connected)
		isConnected = connected
	})
	scan(&ctx)
}

func scan(ctx *ReceiverCtx) {
	must("enable BLE stack", adapter.Enable())

	ch := make(chan bluetooth.ScanResult, 1)
	err := adapter.Scan(func(adapter *bluetooth.Adapter, device bluetooth.ScanResult) {
		if device.HasServiceUUID(ctx.uuid) && device.RSSI >= -50 {
			adapter.StopScan()
			ch <- device
		}
	})

	must("start scan", err)
	select {
	case result := <-ch:
		connect(ctx, result)
	}
}

func connect(ctx *ReceiverCtx, res bluetooth.ScanResult) {
	tui.DeviceFound(res.Address.String())
	uuid_arr := []bluetooth.UUID{ctx.uuid}
	device, err := adapter.Connect(res.Address, DEFAULT_PARAMS)
	ctx.device = device
	must("connect to device properly", err)
	services, discoveryErr := device.DiscoverServices(uuid_arr)
	must("discover list of services", discoveryErr)

	svc := services[0]
	chars, err := svc.DiscoverCharacteristics(uuid_arr)
	must("discover characteristics for service", err)

	Writer.Start()

	ctx.datastream = &(chars[0])
	err = ctx.datastream.EnableNotifications(HandleInput)
	must("enable notifications on characteristic stream", err)

  if *IsServerMode {
    StartWSServer()
  } else {
    // block forever to process events
    select {}
  }
}

func must(action string, err error) {
	if err != nil {
		tui.Error("Failed to " + action + ": " + err.Error())
	}
}

