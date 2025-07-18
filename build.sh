#!/usr/bin/env bash
set -eo pipefail

# Local build script to mimic GitHub Actions release workflow
mkdir -p artifacts

# Build using Docker (no Go required on host)
for os in linux windows darwin; do
  ext=""
  if [ "$os" = "windows" ]; then ext=".exe"; fi
  echo "Building for $os using Docker..."
  docker run --rm -v "$(pwd)":/app -w /app golang:1.22 \
    /bin/bash -c "GOOS=$os GOARCH=amd64 go build -buildvcs=false -ldflags='-s -w' -o artifacts/splace-$os$ext"
  echo "Packaging splace-$os$ext into ZIP..."
  (cd artifacts && zip -j splace-$os.zip splace-$os$ext)
  echo "Generating installer script for $os..."
  cat > artifacts/install-$os.sh << EOF
#!/usr/bin/env bash
set -e

# Installer for splace on $os
BIN="splace-$os$ext"
if [ ! -f "\$BIN" ]; then
  echo "Binary \$BIN not found"
  exit 1
fi

# Parse install mode
GLOBAL=false
if [ "$1" = "--global" ] || [ "$1" = "-g" ]; then
  GLOBAL=true
fi

if [ "$GLOBAL" = true ]; then
  # System-wide install
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required for global installation"
    exit 1
  fi
  echo "Installing splace globally (requires sudo)..."
  sudo install -m 0755 "\$BIN" /usr/local/bin/splace
  echo "splace installed to /usr/local/bin/splace"
else
  # Per-user install
  echo "Installing splace for current user..."
  mkdir -p "\$HOME/.local/bin"
  install -m 0755 "\$BIN" "\$HOME/.local/bin/splace"
  echo "splace installed to $HOME/.local/bin/splace"
  echo "Ensure $HOME/.local/bin is in your PATH"
fi
EOF
  chmod +x artifacts/install-$os.sh
  echo "Packaging installer into ZIP..."
  (cd artifacts && zip -j splace-$os-installer.zip install-$os.sh)
done

echo "Artifacts stored in artifacts/ folder:"
ls -1 artifacts/
