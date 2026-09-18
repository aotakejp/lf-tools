# lf-trash.ps1
# Script to move files or directories to the Recycle Bin (used from lf prompt)

# Determine paths: prioritize $Env:fs (multiple selection) if non-empty, else use $Env:f
$Paths = @()

if ($Env:fs -ne '') {
    if ($Env:fs -match '\n') {
        # Split by newline and trim whitespace/quotes from each path
        $Paths = ($Env:fs -split '\r?\n' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ -and $_ -ne '' })
    } else {
        $Paths = @($Env:fs.Trim().Trim('"'))
    }
}

# Fallback to single file environment variable if $Paths is empty
if ($Paths.Count -eq 0 -and $Env:f -ne '') {
    $Paths = @($Env:f.Trim().Trim('"'))
}

# Handle no valid paths provided
if ($Paths.Count -eq 0) {
    Write-Host "No valid files." -NoNewline
    exit
}

# Load Microsoft.VisualBasic for shell-integrated Recycle Bin operations
Add-Type -AssemblyName Microsoft.VisualBasic

# Process single file selection
if ($Paths.Count -eq 1) {
    $Path = $Paths[0]
    if (Test-Path $Path) {
        $lastItem = Split-Path -Path $Path -Leaf
        Write-Host "Trash '$lastItem'? (y/n)" -NoNewline
        $response = Read-Host
        if ($response -eq 'y' -or $response -eq 'Y') {
            try {
                if (Test-Path $Path -PathType Leaf) {
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                        $Path,
                        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                } elseif (Test-Path $Path -PathType Container) {
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                        $Path,
                        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                }
                Write-Host "'$Path' trashed." -NoNewline
            } catch {
                Write-Host "Error: Failed to trash '$Path'." -NoNewline; Read-Host
            }
        } else {
            Write-Host "Skipped." -NoNewline
        }
    } else {
        Write-Host "Not found: '$Path'." -NoNewline; Read-Host
    }
}
# Process multiple file selection
else {
    Write-Host "Trash $($Paths.Count) items? (y/n)" -NoNewline
    $response = Read-Host
    if ($response -eq 'y' -or $response -eq 'Y') {
        $trashed = @()
        $notFound = @()
        $errors = @()

        foreach ($Path in $Paths) {
            if (Test-Path $Path) {
                try {
                    $fileName = [System.IO.Path]::GetFileName($Path)
                    if (Test-Path $Path -PathType Leaf) {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
                    } elseif (Test-Path $Path -PathType Container) {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
                    }
                    $trashed += $fileName
                } catch {
                    $errors += [System.IO.Path]::GetFileName($Path)
                }
            } else {
                $notFound += [System.IO.Path]::GetFileName($Path)
            }
        }

        # Display summary results
        if ($trashed.Count -gt 0) {
            Write-Host "$($trashed.Count) items trashed." -NoNewline
        }
        if ($notFound.Count -gt 0) {
            Write-Host " Not found: '$($notFound -join ', ')'. " -NoNewline; Read-Host
        }
        if ($errors.Count -gt 0) {
            Write-Host " Error: '$($errors -join ', ')'. " -NoNewline; Read-Host
        }
    } else {
        Write-Host "Cancelled." -NoNewline
    }
}

