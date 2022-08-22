package tui

import (
	"fmt"
	"time"
	"os"

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

func ConnectionChange(connected bool) {
  if connected {
    str := fmt.Sprintf("\nConnected!")
    fmt.Println(chalk.Green.Color(str))
    s.Stop()
  } else {
    str := fmt.Sprintf("\nDisconnected.")
    fmt.Println(chalk.Red.Color(str))
  }
}

func Error(str string) {
    fmt.Println("\n" + chalk.Red.Color(str))
		os.Exit(1)
}

func DeviceFound(localname string) {
  s.Stop()
  str := fmt.Sprintf("Discovered device '%s' nearby!", localname)
  fmt.Println(chalk.Green.Color(str))
  s.Suffix = " Attempting to connect..."
  s.Start()
}

