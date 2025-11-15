#!/bin/bash
# Run AWS Manager on Linux (development mode)

set -e

echo "=========================================="
echo "Running AWS Manager on Linux"
echo "=========================================="

# Change to project root
cd "$(dirname "$0")/.."

echo ""
echo "Step 1: Building Go backend..."
cd backend
go build -o awsmgr_backend main.go
chmod +x awsmgr_backend
cd ..
echo "✓ Backend compiled"

echo ""
echo "Step 2: Starting Flutter app..."
cd awsmgr_ui

# Run flutter in background and get its PID
flutter run -d linux &
FLUTTER_PID=$!

# Wait for build directory to be created
echo "Waiting for Flutter to create build directory..."
sleep 5

# Copy backend to debug bundle
echo "Copying backend to Flutter bundle..."
mkdir -p build/linux/x64/debug/bundle/
cp ../backend/awsmgr_backend build/linux/x64/debug/bundle/
chmod +x build/linux/x64/debug/bundle/awsmgr_backend
echo "✓ Backend copied"

# Wait for flutter process
wait $FLUTTER_PID
