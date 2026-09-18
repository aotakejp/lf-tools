// Package main provides a helper utility to run PowerShell scripts from lf on Windows.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func main() {
	// Retrieve environment variable 'f' (current file path)
	f := os.Getenv("f")
	if f == "" {
		fmt.Fprintln(os.Stderr, "Error: environment variable 'f' is not set")
		os.Exit(1)
	}

	// Retrieve command-line argument (script name)
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Error: no script argument provided")
		os.Exit(1)
	}

	command := os.Args[1]

	// Get user home directory to construct script path
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
		os.Exit(1)
	}

	// Construct full script path (~/AppData/Roaming/lf/command)
	scriptPath := filepath.Join(home, "AppData", "Roaming", "lf", command)

	// Execute PowerShell with lightweight options:
	// -NoProfile: Skip loading profile for faster execution
	// -ExecutionPolicy Bypass: Temporarily bypass execution policy
	// -File: Run the specified script file
	cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, f)

	// Connect standard streams directly to the current process (terminal)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Run command
	if err := cmd.Run(); err != nil {
		os.Exit(1)
	}
}
