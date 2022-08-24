package main

import (
	"os"
	"os/signal"

	"time"

	"github.com/ansonyuu/gesture/tui"
	"github.com/gosuri/uilive"
	"tinygo.org/x/bluetooth"
)

var adapter = bluetooth.DefaultAdapter
var Writer = uilive.New()

type ReceiverCtx struct {
	isScanning bool
	uuid       bluetooth.UUID
	device     *bluetooth.Device
	datastream *bluetooth.DeviceCharacteristic
}

var DEFAULT_PARAMS = bluetooth.ConnectionParams{
	ConnectionTimeout: bluetooth.NewDuration(10 * time.Second),
}

func main() {
	tui.Header()

	gesture_service_uuid, _ := bluetooth.ParseUUID("f4f8cc56-30e7-4a68-9d38-da0b16a20e82")
	ctx := ReceiverCtx{
		isScanning: true,
		uuid:       gesture_service_uuid,
	}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	go func() {
		<-c
		if ctx.device != nil {
			ctx.device.Disconnect()
		}
		os.Exit(1)
	}()

	adapter.SetConnectHandler(func(addr bluetooth.Addresser, connected bool) {
		tui.ConnectionChange(connected)
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

	// Writer.Start()

	ctx.datastream = &(chars[0])
	err = ctx.datastream.EnableNotifications(HandleInput)
	must("enable notifications on characteristic stream", err)
	select {}
}

func must(action string, err error) {
	if err != nil {
		tui.Error("Failed to " + action + ": " + err.Error())
	}
}
