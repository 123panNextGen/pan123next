#!/bin/bash
# Build Go downloader backend AAR for Android.
# This is called by the Gradle task in build.gradle.kts.
# Can also be run manually:
#   cd android && bash build_go_backend.sh
set -e

GO_SERVER_DIR="$(cd "$(dirname "$0")/../server" && pwd)"
AAR_OUTPUT="$(cd "$(dirname "$0")/app/libs" && pwd)/downloader.aar"

if ! command -v gomobile &> /dev/null; then
  echo "Error: gomobile not found. Install: go install golang.org/x/mobile/cmd/gomobile@latest"
  exit 1
fi

mkdir -p "$(dirname "$AAR_OUTPUT")"

echo "Building Go downloader backend AAR..."
cd "$GO_SERVER_DIR"
gomobile bind \
  -target=android \
  -o "$AAR_OUTPUT" \
  -androidapi 21 \
  ./mobile

echo "AAR built: $AAR_OUTPUT"
