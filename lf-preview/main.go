// Package main provides file preview functionality for lf on Windows.
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	// Version can be overridden at build time using: -ldflags "-X main.Version=1.0.0"
	Version = "dev"
	// Cached result of nkf lookup, computed once at startup
	hasNkf = false
)

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Usage: %s <file>\n", filepath.Base(os.Args[0]))
		fmt.Println("Version:", Version)
		os.Exit(1)
	}

	file := os.Args[1]
	ext := strings.ToLower(filepath.Ext(file))
	baseName := strings.ToLower(filepath.Base(file))

	// Check once whether nkf is available on PATH
	if _, err := exec.LookPath("nkf"); err == nil {
		hasNkf = true
	}

	// Resolve tar command path (prioritize Scoop shim, then fallback to system PATH)
	tarPath := filepath.Join(os.Getenv("USERPROFILE"), "scoop", "shims", "tar.exe")
	if _, err := os.Stat(tarPath); os.IsNotExist(err) && os.Getenv("PV_TAR_PATH") == "" {
		tarPath = "tar.exe"
	} else if customTarPath := os.Getenv("PV_TAR_PATH"); customTarPath != "" {
		tarPath = customTarPath
	}

	// Dispatch preview logic based on file extension
	switch {
	case strings.HasSuffix(baseName, ".tar") || strings.HasSuffix(baseName, ".tar.gz") ||
		strings.HasSuffix(baseName, ".tar.bz2") || strings.HasSuffix(baseName, ".tar.xz") ||
		ext == ".tgz" || ext == ".tbz2" || ext == ".txz":
		runCommandWithLimit(tarPath, "--force-local", "-tf", file)

	case ext == ".zip" || ext == ".rar" || ext == ".7z":
		runCommand("7z", "l", file)

	case ext == ".pdf":
		runCommand("pdftotext", file, "-")

	default:
		// Process as text; handle character encoding conversion if necessary
		if err := runNkfToBat(file); err != nil {
			fmt.Fprintf(os.Stderr, "Preview error: %v\n", err)
		}
	}
}

// runNkfToBat detects encoding and converts Legacy Japanese encodings (SJIS/EUC) to UTF-8.
// If nkf is not installed, it skips detection/conversion and shows the file as-is via bat.
func runNkfToBat(file string) error {
	if !hasNkf {
		return runCommand("bat", "--color=always", "--style=plain", "--pager=never", file)
	}

	out, err := exec.Command("nkf", "-g", file).Output()
	if err != nil {
		return fmt.Errorf("encoding detection failed: %v", err)
	}
	encoding := strings.TrimSpace(string(out))

	// Convert to UTF-8 via temporary file if legacy encoding is detected
	if encoding == "Shift_JIS" || encoding == "CP932" || encoding == "EUC-JP" {
		tmpFile, err := os.CreateTemp("", "pv_tmp_*"+filepath.Ext(file))
		if err != nil {
			return err
		}
		tmpPath := tmpFile.Name()
		defer os.Remove(tmpPath)

		convertCmd := exec.Command("nkf", "-w", "-S", file)
		convertCmd.Stdout = tmpFile
		if err := convertCmd.Run(); err != nil {
			tmpFile.Close()
			return fmt.Errorf("conversion failed: %v", err)
		}
		tmpFile.Close()

		return runCommand("bat", "--color=always", "--style=plain", "--pager=never", tmpPath)
	}

	return runCommand("bat", "--color=always", "--style=plain", "--pager=never", file)
}

// runCommand executes a command and pipes its output directly to stdout
func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// runCommandWithLimit executes a command, converts output to UTF-8 via nkf when available,
// and limits output to 80 lines to prevent UI freezing. If nkf is not installed, it reads
// the command's raw output directly instead of piping through nkf.
func runCommandWithLimit(name string, args ...string) {
	cmd := exec.Command(name, args...)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Printf("Error creating pipe: %v\n", err)
		return
	}
	cmd.Stderr = os.Stdout

	if err := cmd.Start(); err != nil {
		fmt.Printf("Execution Error: %v\n", err)
		return
	}

	var lineSource io.Reader = stdout
	var nkf *exec.Cmd

	if hasNkf {
		nkf = exec.Command("nkf", "-w")
		nkf.Stdin = stdout
		nkfOut, err := nkf.StdoutPipe()
		if err != nil {
			fmt.Printf("Error creating nkf pipe: %v\n", err)
			_ = cmd.Process.Kill()
			return
		}
		if err := nkf.Start(); err != nil {
			nkf = nil
			lineSource = stdout
		} else {
			lineSource = nkfOut
		}
	}

	scanner := bufio.NewScanner(lineSource)
	count := 0
	for scanner.Scan() {
		if count < 80 {
			fmt.Println(scanner.Text())
			count++
		} else {
			break
		}
	}

	// Check for scanning errors
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Scanner error: %v\n", err)
	}

	// Cleanup: kill the main process (tar/7z) to stop streaming data
	_ = cmd.Process.Kill()
	if nkf != nil {
		_ = nkf.Process.Kill()
		_ = nkf.Wait()
	}
	_ = cmd.Wait()
}
