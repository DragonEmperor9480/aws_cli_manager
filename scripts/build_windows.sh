#!/bin/bash
# Build Windows desktop app with Go backend (cross-compile from Linux)

set -e

echo "=========================================="
echo "Building AWS Manager for Windows"
echo "=========================================="

echo ""
echo "Step 1: Building Go backend executable for Windows..."
cd ../backend
GOOS=windows GOARCH=amd64 go build -o awsmgr_backend.exe main.go
cd ../scripts

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Go backend"
    exit 1
fi

echo "✓ Go backend compiled: backend/awsmgr_backend.exe"

echo ""
echo "Step 2: Building Flutter Windows app..."
cd ../awsmgr_ui

# Note: Building Windows from Linux requires special setup
# You may need to build on Windows or use a Windows VM
echo "⚠ Note: Building Flutter Windows apps from Linux is experimental"
echo "For best results, build on Windows using build_windows.bat"

flutter clean
flutter pub get
flutter build windows --release

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Flutter app"
    echo "Try building on Windows instead"
    exit 1
fi

echo ""
echo "Step 3: Copying backend to Flutter build..."
cp ../backend/awsmgr_backend.exe build/windows/x64/runner/Release/
echo "✓ Backend copied to bundle"

cd ..

echo ""
echo "=========================================="
echo "✓ Build Complete!"
echo "=========================================="
echo "App location: awsmgr_ui/build/windows/x64/runner/Release/"
echo ""
echo "To run on Windows:"
echo "  Copy the Release folder to Windows"
echo "  Run awsmgr.exe"
