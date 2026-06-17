#!/bin/bash
# Build Go downloader backend framework for iOS
# Add this as a "Run Script" build phase in Xcode:
#   Project > Runner Target > Build Phases > + > New Run Script Phase
#   Shell: /bin/sh
#   Script: "$SRCROOT/build_go_backend.sh"
set -e

GO_SERVER_DIR="$SRCROOT/../server"
FRAMEWORK_OUTPUT="$SRCROOT/Runner/downloader.framework"

if ! command -v gomobile &> /dev/null; then
  echo "warning: gomobile not found. Install: go install golang.org/x/mobile/cmd/gomobile@latest"
  exit 0
fi

if [ ! -d "$GO_SERVER_DIR" ]; then
  echo "warning: Go server directory not found at $GO_SERVER_DIR"
  exit 0
fi

echo "Building Go downloader backend framework..."
cd "$GO_SERVER_DIR"
gomobile bind \
  -target=ios \
  -o "$FRAMEWORK_OUTPUT" \
  ./mobile

echo "Go framework built: $FRAMEWORK_OUTPUT"
