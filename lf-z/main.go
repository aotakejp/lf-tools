// Package main integrates zoxide directory jumping with lf.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	// Retrieve environment variable 'id' (lf client ID)
	id := os.Getenv("id")
	if id == "" {
		fmt.Fprintln(os.Stderr, "Error: environment variable 'id' is not set")
		os.Exit(1)
	}

	// Retrieve command-line query argument
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Error: no query argument provided")
		os.Exit(1)
	}
	query := os.Args[1]

	// Execute zoxide query
	cmd := exec.Command("zoxide", "query", query)
	output, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error executing zoxide query: %v\n", err)
		os.Exit(1)
	}

	// Extract directory path from output and trim trailing newline
	dirPath := strings.TrimSpace(string(output))

	// Send remote cd command to lf
	lfCmd := fmt.Sprintf("send %s cd %q", id, dirPath)
	cmd = exec.Command("lf", "-remote", lfCmd)

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error executing lf -remote: %v\n", err)
		os.Exit(1)
	}
}
