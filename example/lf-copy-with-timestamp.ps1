# lf-copy-with-timestamp.ps1
# Script to copy a file or directory with a timestamp appended to its name (used from lf prompt)

# Get the full path from the environment variable 'f'
$RawPath = $Env:f.Trim().Trim('"')

# Check if the target exists
if (-not (Test-Path -LiteralPath $RawPath)) {
    Write-Host "Invalid path: $RawPath" -NoNewline
    exit 1
}

# Get item info
$Item = Get-Item -LiteralPath $RawPath
$DateTime = Get-Date -Format "yyyyMMddHHmm"

# Construct the new name
if ($Item.PSIsContainer) {
    # For directories: dirname_timestamp
    $NewName = "$($Item.Name)_$DateTime"
} else {
    # For files: basename_timestamp.ext or basename_timestamp
    if ($Item.Extension) {
        $NewName = "$($Item.BaseName)_$DateTime$($Item.Extension)"
    } else {
        $NewName = "$($Item.BaseName)_$DateTime"
    }
}

# Construct full destination path using Split-Path for reliability
$ParentPath = Split-Path -Path $Item.FullName -Parent
$NewPath = Join-Path -Path $ParentPath -ChildPath $NewName

# Prevent overwriting
if (Test-Path -LiteralPath $NewPath) {
    Write-Host "Already exists: $NewName" -NoNewline
    exit 1
}

# Execute copy operation
try {
    Copy-Item -LiteralPath $Item.FullName -Destination $NewPath -Recurse -ErrorAction Stop
    Write-Host "Copied to: $NewName" -NoNewline
} catch {
    $msg = $_.Exception.Message
    Write-Host "Error: $msg" -NoNewline
    exit 1
}

