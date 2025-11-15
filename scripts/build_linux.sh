#!/bin/bash
# Build Linux desktop app with Go backend

set -e

echo "=========================================="
echo "Building AWS Manager for Linux"
echo "=========================================="

# Change to project root
cd "$(dirname "$0")/.."

echo ""
echo "Step 1: Building Go backend executable..."
cd backend
GOOS=linux GOARCH=amd64 go build -o awsmgr_backend main.go
cd ..

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Go backend"
    exit 1
fi

chmod +x backend/awsmgr_backend
echo "✓ Go backend compiled: backend/awsmgr_backend"

echo ""
echo "Step 2: Building Flutter Linux app..."
cd awsmgr_ui

flutter clean
flutter pub get
flutter build linux --release

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Flutter app"
    exit 1
fi

echo ""
echo "Step 3: Copying backend to Flutter build..."
cp ../backend/awsmgr_backend build/linux/x64/release/bundle/
chmod +x build/linux/x64/release/bundle/awsmgr_backend
echo "✓ Backend copied to bundle"

cd ..

echo ""
echo "=========================================="
echo "✓ Build Complete!"
echo "=========================================="
echo "App location: awsmgr_ui/build/linux/x64/release/bundle/"
echo ""
echo "To run:"
echo "  cd awsmgr_ui/build/linux/x64/release/bundle/"
echo "  ./awsmgr"
