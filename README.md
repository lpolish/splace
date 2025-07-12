# splace

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
