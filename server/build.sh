#!/bin/bash
set -e

mkdir -p ../build/go

echo "=== Windows (amd64) ==="
GOOS=windows GOARCH=amd64 go build -o ../build/go/downloader_server.exe ./cmd/server
echo "OK: build/go/downloader_server.exe"

echo "=== macOS (amd64) ==="
GOOS=darwin GOARCH=amd64 go build -o ../build/go/downloader_server_darwin_amd64 ./cmd/server
echo "OK: build/go/downloader_server_darwin_amd64"

echo "=== macOS (arm64) ==="
GOOS=darwin GOARCH=arm64 go build -o ../build/go/downloader_server_darwin_arm64 ./cmd/server
echo "OK: build/go/downloader_server_darwin_arm64"

echo "=== Linux (amd64) ==="
GOOS=linux GOARCH=amd64 go build -o ../build/go/downloader_server_linux_amd64 ./cmd/server
echo "OK: build/go/downloader_server_linux_amd64"

echo "=== Gomobile Android ==="
if command -v gomobile &> /dev/null; then
  gomobile bind -target=android -o ../build/go/downloader.aar ./mobile
  echo "OK: build/go/downloader.aar"
else
  echo "SKIP: gomobile not installed"
fi

echo "=== Gomobile iOS ==="
if command -v gomobile &> /dev/null; then
  gomobile bind -target=ios -o ../build/go/downloader.framework ./mobile
  echo "OK: build/go/downloader.framework"
else
  echo "SKIP: gomobile not installed"
fi

echo ""
echo "Done. Binaries are in build/go/"
