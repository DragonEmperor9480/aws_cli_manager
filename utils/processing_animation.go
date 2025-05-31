package utils

import (
	"fmt"
	"time"
)

func ShowProcessingAnimation(duration time.Duration) {
	frames := []string{"|", "/", "-", "\\"}
	for i := 0; i < int(duration.Seconds()*4); i++ {
		fmt.Printf("\rProcessing... %s", frames[i%len(frames)])
		time.Sleep(250 * time.Millisecond)
	}
	fmt.Print("\rDone!           \n")
}
