# lf-create-new-directory.ps1
# Script to create a new directory (used from lf prompt)

# Prompt for the directory name
Write-Host -NoNewline "Enter directory name: "
$directoryName = Read-Host

# Check if the directory name is not empty
if (-not [string]::IsNullOrEmpty($directoryName)) {
    # Check if the directory already exists
    if (Test-Path .\$directoryName -PathType Container) {
        Write-Host "[Error] Directory already exists!"
        Start-Sleep -Seconds 2
    } else {
        # Create the new directory
        New-Item -Name $directoryName -ItemType Directory
    }
}

