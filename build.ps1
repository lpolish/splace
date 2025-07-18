#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Local build script to mimic GitHub Actions release workflow using Docker
New-Item -ItemType Directory -Force -Path artifacts | Out-Null

$oses = @('linux', 'windows', 'darwin')
foreach ($os in $oses) {
    $ext = ''
    if ($os -eq 'windows') { $ext = '.exe' }
    Write-Host "Building for $os using Docker..."
    docker run --rm -v "${PWD}:/app" -w /app golang:1.22 `
        pwsh -c "env:GOOS='$os'; env:GOARCH='amd64'; go build -buildvcs=false -ldflags='-s -w' -o artifacts/splace-$os$ext"
    Write-Host "Packaging splace-$os$ext into ZIP..."
    Push-Location artifacts
    Compress-Archive -Path "splace-$os$ext" -DestinationPath "splace-$os.zip"
    Pop-Location
    Write-Host "Generating installer script for $os..."
    $installer = @"
#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Installer for splace on $os
$BIN = "splace-$os$ext"
if (-not (Test-Path $BIN)) {
    Write-Host "Binary $BIN not found"
    exit 1
}

# Parse install mode
$GLOBAL = $false
if ($args.Count -gt 0 -and ($args[0] -eq '--global' -or $args[0] -eq '-g')) {
    $GLOBAL = $true
}

if ($GLOBAL) {
    # System-wide install
    Write-Host "Installing splace globally (requires elevation)..."
    Start-Process pwsh -Verb RunAs -ArgumentList "-Command", "Copy-Item -Path $BIN -Destination C:/ProgramData/splace/splace.exe -Force"
    Write-Host "splace installed to C:/ProgramData/splace/splace.exe"
} else {
    # Per-user install
    $userBin = "$HOME/.local/bin"
    New-Item -ItemType Directory -Force -Path $userBin | Out-Null
    Copy-Item -Path $BIN -Destination "$userBin/splace$ext" -Force
    Write-Host "splace installed to $userBin/splace$ext"
    Write-Host "Ensure $userBin is in your PATH"
}
"@
    Set-Content -Path "artifacts/install-$os.ps1" -Value $installer
    Write-Host "Packaging installer into ZIP..."
    Push-Location artifacts
    Compress-Archive -Path "install-$os.ps1" -DestinationPath "splace-$os-installer.zip"
    Pop-Location
}

Write-Host "Artifacts stored in artifacts/ folder:"
Get-ChildItem -Name artifacts
