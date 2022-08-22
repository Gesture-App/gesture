package tui

import (
	"fmt"
	"time"

	"github.com/briandowns/spinner"
	"github.com/ttacon/chalk"
)

var s *spinner.Spinner

func Header() {
	fmt.Println(chalk.Bold.TextStyle("👋 Welcome to Gesture!"))
	fmt.Println(chalk.Dim.TextStyle("On the iPhone App, press 'Start Pairing to device'."))

	s = spinner.New(spinner.CharSets[14], 100 * time.Millisecond)
	s.Suffix = " Looking for nearby devices to pair with..."
	s.Start()
}

func DeviceFound(localname string) {
  s.Stop()
  str := fmt.Sprintf("Discovered device '%s' nearby!", localname)
  fmt.Println(chalk.Green.Color(str))
  s.Suffix = " Attempting to connect..."
  s.Start()
}

