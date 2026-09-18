# lf-uncompress.ps1
# Script to uncompress archive (used from lf prompt)

# Executables
$SevenZipCmd = "7z.exe"
$TarCmdDefault = "tar.exe"
$TarCmdScoop = Join-Path -Path $env:USERPROFILE -ChildPath "scoop\shims\tar.exe"

# Use scoop tar if available
$TarCmd = if (Test-Path $TarCmdScoop) { $TarCmdScoop } else { $TarCmdDefault }

# Supported tar extensions (regex style)
$TarExtensions = @(".tar", ".tar.gz", ".tar.bz2", ".tar.xz", ".tgz", ".tbz2", ".txz")

# Exit with an error message
function Exit-WithError {
    param ([string]$Message)
    # Output the error message to lf
    Write-Host -NoNewline $Message
    Start-Sleep 2
    exit 1
}

# Exit with success message
function Exit-WithSuccess {
    Write-Host -NoNewline "Successfully uncompressed"
    Start-Sleep 2
    exit 0
}

# Check if the file is a valid 7z-recognized archive
function Test-IsSevenZipArchive {
    param ($Path)
    try {
        $proc = Start-Process -FilePath $SevenZipCmd -ArgumentList "t", $Path, "-bso0", "-bse0" -PassThru -Wait
        return ($proc.ExitCode -eq 0)
    } catch {
        return $false
    }
}

# Get archive path from lf
$inputQuoted = $env:f
if (-not $inputQuoted) {
    Exit-WithError "No file path provided by lf."
}

$archivePath = $inputQuoted.Replace("`"","")

if (-not (Test-Path $archivePath -PathType Leaf)) {
    Exit-WithError "Target file does not exist."
}

$archiveDir = Split-Path $archivePath -Parent
$archiveName = Split-Path $archivePath -Leaf
$extension = [System.IO.Path]::GetExtension($archiveName).ToLower()

# Match compound extensions for tar.* types
foreach ($tarExt in $TarExtensions) {
    if ($archiveName.ToLower().EndsWith($tarExt)) {
        $extension = $tarExt
        break
    }
}

Set-Location -Path $archiveDir

# Function to check if target files already exist
function Check-IfFilesExist {
    param ($ArchivePath, $Extension)

    # Extract file list based on the type of archive
    $fileList = @()

    if ($Extension -in $TarExtensions) {
        # Extract file list from tar
        $fileList = & $TarCmd --force-local -tf $ArchivePath 2>$null
    } elseif (Test-IsSevenZipArchive $ArchivePath) {
        # Extract file list from 7z
        $fileList = & $SevenZipCmd l -ba $ArchivePath | ForEach-Object {
            # Correct the parsing to extract the file paths properly
            $parts = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Length -ge 6) {
                # Join the file name parts correctly
                $parts[5..($parts.Length - 1)] -join " "
            }
        }
    }

    # Check if any files already exist in the target directory
    foreach ($item in $fileList) {
        $targetPath = Join-Path -Path $archiveDir -ChildPath $item
        if (Test-Path $targetPath) {
            Exit-WithError "File '$item' already exists, cannot overwrite."
        }
    }
}

# Start the extraction process
try {
    # Check if files in the archive already exist
    Check-IfFilesExist -ArchivePath $archivePath -Extension $extension

    if ($extension -in $TarExtensions) {
        $proc = Start-Process -FilePath $TarCmd -ArgumentList "--force-local", "-xkf", $archivePath -PassThru -Wait
    } elseif (Test-IsSevenZipArchive $archivePath) {
        $proc = Start-Process -FilePath $SevenZipCmd -ArgumentList "x", $archivePath, "-aos" -PassThru -Wait
    } else {
        Exit-WithError "Unsupported or invalid archive format."
    }
} catch {
    Exit-WithError "Failed to run uncompression process: $_"
}

if ($proc.ExitCode -eq 0) {
    Exit-WithSuccess
}

Exit-WithError "Uncompression failed!"

