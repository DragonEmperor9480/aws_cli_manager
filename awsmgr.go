package main

import (
	"fmt"
	"os/exec"
)

func main() {
	cmd := exec.Command("echo", "Hello World")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	fmt.Println(string(output))
}
