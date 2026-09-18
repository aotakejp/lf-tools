# lf-create-new-file.ps1
# Script to create a new file (used from lf prompt)

# Prompt for the file name
Write-Host -NoNewline "Enter file name: "
$fileName = Read-Host

# Check if the file name is not empty
if (-not [string]::IsNullOrEmpty($fileName)) {
    # Check if the file already exists
    if (Test-Path .\$fileName) {
        Write-Host "[Error] File already exists!"
        Start-Sleep -Seconds 2
    } else {
        # Create the new file
        New-Item -Name $fileName -ItemType File
    }
}

