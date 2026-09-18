// Package main provides interactive zoxide directory selection using fzf for lf.
package main

import (
	"bytes"
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

	// Retrieve optional query argument
	args := os.Args[1:]
	query := ""
	if len(args) > 0 {
		query = args[0]
	}

	// Execute zoxide query -l to list directories
	zoxideCmd := exec.Command("zoxide", "query", "-l")
	if query != "" {
		zoxideCmd = exec.Command("zoxide", "query", "-l", query)
	}
	zoxideOut, err := zoxideCmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error running zoxide: %v\n", err)
		os.Exit(1)
	}

	// Pipe zoxide results into fzf for interactive selection
	fzfCmd := exec.Command("fzf")
	fzfCmd.Stdin = bytes.NewReader(zoxideOut)
	fzfOut, err := fzfCmd.Output()
	if err != nil {
		// Exit cleanly if fzf was cancelled by the user (exit code 130)
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
			os.Exit(0)
		}
		fmt.Fprintf(os.Stderr, "Error running fzf: %v\n", err)
		os.Exit(1)
	}

	// Process selected directory
	selectedDir := strings.TrimSpace(string(fzfOut))
	if selectedDir != "" {
		// Send remote cd command to lf
		lfCmd := exec.Command("lf", "-remote", fmt.Sprintf("send %s cd %q", id, selectedDir))
		if err := lfCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Error running lf: %v\n", err)
			os.Exit(1)
		}
	}
}
