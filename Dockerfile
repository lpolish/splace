# Multi-stage build for splace CLI and installers
FROM golang:1.21 AS builder
WORKDIR /src
COPY . .
RUN go mod download

# Build binaries for all platforms
RUN mkdir -p /out && \
    GOOS=linux GOARCH=amd64 go build -buildvcs=false -ldflags="-s -w" -o /out/splace-linux && \
    GOOS=windows GOARCH=amd64 go build -buildvcs=false -ldflags="-s -w" -o /out/splace-windows.exe && \
    GOOS=darwin GOARCH=amd64 go build -buildvcs=false -ldflags="-s -w" -o /out/splace-darwin

# Install NSIS for Windows installer
FROM debian:bookworm-slim AS nsis
RUN apt-get update && apt-get install -y nsis zip
COPY --from=builder /out /out
COPY splace-installer.nsi /out/
WORKDIR /out
RUN makensis -V2 splace-installer.nsi

# Build macOS .pkg installer (requires pkgbuild, only works on macOS runners)
# This stage is a placeholder for local macOS builds

# Final stage: collect all artifacts
FROM debian:bookworm-slim AS artifacts
RUN apt-get update && apt-get install -y zip
COPY --from=builder /out /out
COPY --from=nsis /out/splace-installer.exe /out/
WORKDIR /out
RUN zip splace-linux.zip splace-linux && \
    zip splace-windows.zip splace-windows.exe && \
    zip splace-darwin.zip splace-darwin && \
    zip splace-windows-installer.zip splace-installer.exe
CMD ["ls", "-lh", "/out"]
