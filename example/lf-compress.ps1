#Set-StrictMode -Version Latest↴ lf-compress.ps1
# Script to compress a file or directory (used from lf prompt)

# Set default executables
$SevenZipCmd = "7z.exe"
$TarCmdDefault = "tar.exe"
$TarCmdScoop = Join-Path -Path $env:USERPROFILE -ChildPath "scoop\shims\tar.exe"

# Use scoop's tar if it exists
$TarCmd = if (Test-Path $TarCmdScoop) { $TarCmdScoop } else { $TarCmdDefault }

# File extension constants
$ExtZip = ".zip"
$Ext7z  = ".7z"
$ExtGz  = ".tar.gz"
$ExtBz2 = ".tar.bz2"
$ExtXz  = ".tar.xz"

function Test-FileExists {
    param ($Path)
    return Test-Path $Path -PathType Leaf
}

function Exit-WithFileExistsError {
    param ($Name)
    Write-Host -NoNewline "$Name already exists!"
    Start-Sleep 2
    exit 1
}

function Exit-WithSuccess {
    Write-Host -NoNewline "Successfully compressed"
    Start-Sleep 2
    exit 0
}

function Exit-WithFailure {
    param (
        [string]$Message = "Compression failed!"
    )
    Write-Host -NoNewline $Message
    Start-Sleep 2
    exit 1
}

# Get and validate source path
$sourceQuoted = $env:f
if (-not $sourceQuoted) {
    Exit-WithFailure "No input path provided by lf."
}

$sourcePath = $sourceQuoted.Replace("`"","")

if (-not (Test-Path $sourcePath)) {
    Exit-WithFailure "Source path does not exist."
}

$sourceDir = [System.IO.Path]::GetDirectoryName($sourcePath)
$sourceName = Split-Path $sourcePath -Leaf

# Prompt for format
Write-Host -NoNewline "Compress  (z)ip  (7)z  tar.(g)z  tar.(b)z2  tar.(x)z ? "
$format = Read-Host

# Validate input
if ($format -notin @('z','7','g','b','x')) {
    Exit-WithFailure "Invalid format selected."
}

Set-Location -Path $sourceDir

try {
    switch ($format) {
        z {
            $archiveName = "$sourceName$ExtZip"
            if (Test-FileExists $archiveName) { Exit-WithFileExistsError $archiveName }
            $proc = Start-Process -FilePath $SevenZipCmd -ArgumentList "a", $archiveName, $sourcePath -PassThru -Wait
        }
        7 {
            $archiveName = "$sourceName$Ext7z"
            if (Test-FileExists $archiveName) { Exit-WithFileExistsError $archiveName }
            $proc = Start-Process -FilePath $SevenZipCmd -ArgumentList "a", $archiveName, $sourcePath -PassThru -Wait
        }
        g {
            $archiveName = "$sourceName$ExtGz"
            if (Test-FileExists $archiveName) { Exit-WithFileExistsError $archiveName }
            $proc = Start-Process -FilePath $TarCmd -ArgumentList "--force-local", "-czf", $archiveName, $sourceName -PassThru -Wait
        }
        b {
            $archiveName = "$sourceName$ExtBz2"
            if (Test-FileExists $archiveName) { Exit-WithFileExistsError $archiveName }
            $proc = Start-Process -FilePath $TarCmd -ArgumentList "--force-local", "-cjf", $archiveName, $sourceName -PassThru -Wait
        }
        x {
            $archiveName = "$sourceName$ExtXz"
            if (Test-FileExists $archiveName) { Exit-WithFileExistsError $archiveName }
            $proc = Start-Process -FilePath $TarCmd -ArgumentList "--force-local", "-cJf", $archiveName, $sourceName -PassThru -Wait
        }
    }
}
catch {
    Exit-WithFailure "Failed to execute compression process: $_"
}

if ($proc.ExitCode -eq 0) {
    Exit-WithSuccess
}

Exit-WithFailure

