# lf-inspect.ps1
# Script to inspect file or directory size and display information (used from lf prompt)

$path = $env:f.Trim().Trim('"')

if (-not (Test-Path $path)) {
  Write-Host "Invalid path: $path" -NoNewline
  exit 1
}

if ((Get-Item $path).PSIsContainer) {
  # For directories: calculate total byte size and display with basename
  $size = Get-ChildItem -Recurse -Force -File $path | Measure-Object -Property Length -Sum
  $name = Split-Path -Leaf $path
  Write-Host "$($size.Sum)  $name" -NoNewline  # Two spaces between size and name
}
elseif (Test-Path $path -PathType Leaf) {
  # For regular files: show file info using lsd, remove user/group columns and show basename
  $name = Split-Path -Leaf $path
  & lsd.exe -a -l --icon never --size bytes --no-symlink "$path" |
    ForEach-Object {
      $_ -replace [regex]::Escape($path), $name -replace '\s+\?\s+\?', ''
    } | ForEach-Object {
      Write-Host $_ -NoNewline
    }
}
else {
  # Unsupported type
  Write-Host "Unsupported type" -NoNewline
}

