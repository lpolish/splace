
# splace

<!-- Badges -->
![Build](https://github.com/lpolish/splace/actions/workflows/build.yml/badge.svg)
![Release](https://img.shields.io/github/v/release/lpolish/splace?include_prereleases&label=release)
[![Go Report Card](https://goreportcard.com/badge/github.com/lpolish/splace)](https://goreportcard.com/report/github.com/lpolish/splace)
[![Go Reference](https://pkg.go.dev/badge/github.com/lpolish/splace.svg)](https://pkg.go.dev/github.com/lpolish/splace)
![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)

Encrypted directory bookmarks manager, cross-platform CLI tool.

## Features

- Save and recall directory bookmarks securely
- AES-GCM encrypted storage with auto-generated key
- Cross-platform installers (user or global)

## Installation

### From GitHub Releases

1. Download the ZIP for your OS: `splace-<os>.zip` and/or the installer `splace-<os>-installer.zip`.
2. Unzip and run the installer:
   ```bash
   # per-user install (default)
   ./install-<os>.sh
   # or global install (requires sudo)
   ./install-<os>.sh --global
   ```

### From Source



#### Prerequisite: Install Docker (Windows)

To build with Docker on Windows, install Docker Desktop:

1. Download the official installer from your browser or with PowerShell:
   ```powershell
   Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile "$env:TEMP\DockerDesktopInstaller.exe"
   ```
2. Run the installer (requires user interaction):
   - Double-click the downloaded file, **or**
   - From PowerShell as Administrator:
     ```powershell
     Start-Process "$env:TEMP\DockerDesktopInstaller.exe" -Verb RunAs
     ```
3. Follow the installation prompts and restart your computer if required.
4. After installation, verify Docker is available:
   ```powershell
   docker --version
   ```

#### Using Docker (no Go required on host)
```bash
./build.sh
```

#### Using PowerShell (Windows, no Go required on host)
```powershell
./build.ps1
```
If you see an error about script execution policy, run the following in an elevated PowerShell window:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
This allows running local scripts like `build.ps1`.

#### Manual Go build (if you have Go installed)
```bash
go build -buildvcs=false -ldflags="-s -w" -o splace
export SPLACE_KEY=$(openssl rand -base64 32)
./splace s  # initialise and save current dir
```

## Usage

```bash
splace s        # save current directory
splace l        # show last saved directory
splace p        # show and pop last saved directory
splace n <idx>  # show bookmark at 1-based index
splace all      # list all saved directories
```

## Environment

- `SPLACE_KEY` (optional): base64-encoded 32-byte AES key. Auto-generated on first run at `~/.splace/key`.

## CI/CD

GitHub Actions builds binaries and installers for Linux, Windows, and macOS, publishing artifacts on release.

## License

MIT © 2025 Luis Pulido Diaz

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
