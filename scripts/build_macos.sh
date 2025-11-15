#!/bin/bash
# Build macOS desktop app with Go backend

set -e

echo "=========================================="
echo "Building AWS Manager for macOS"
echo "=========================================="

echo ""
echo "Step 1: Building Go backend executable for macOS..."
cd ../backend
GOOS=darwin GOARCH=amd64 go build -o awsmgr_backend_macos main.go
cd ../scripts

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Go backend"
    exit 1
fi

chmod +x backend/awsmgr_backend_macos
echo "✓ Go backend compiled: backend/awsmgr_backend_macos"

echo ""
echo "Step 2: Building Flutter macOS app..."
cd ../awsmgr_ui

flutter clean
flutter pub get
flutter build macos --release

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Flutter app"
    exit 1
fi

echo ""
echo "Step 3: Copying backend to Flutter build..."
cp ../backend/awsmgr_backend_macos build/macos/Build/Products/Release/awsmgr.app/Contents/MacOS/
chmod +x build/macos/Build/Products/Release/awsmgr.app/Contents/MacOS/awsmgr_backend_macos
echo "✓ Backend copied to app bundle"

cd ..

echo ""
echo "=========================================="
echo "✓ Build Complete!"
echo "=========================================="
echo "App location: awsmgr_ui/build/macos/Build/Products/Release/awsmgr.app"
echo ""
echo "To run:"
echo "  open awsmgr_ui/build/macos/Build/Products/Release/awsmgr.app"
