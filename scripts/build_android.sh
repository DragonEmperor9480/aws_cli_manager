#!/bin/bash
# Build Android APK with embedded Go backend

set -e

echo "=========================================="
echo "Building AWS Manager for Android"
echo "=========================================="

# Change to project root
cd "$(dirname "$0")/.."

# Check for Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "⚠ ANDROID_NDK_HOME not set, attempting to auto-detect..."
    
    # Try common NDK locations
    POSSIBLE_PATHS=(
        "$HOME/Android/Sdk/ndk"
        "$ANDROID_HOME/ndk"
        "$ANDROID_SDK_ROOT/ndk"
    )
    
    for base_path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$base_path" ]; then
            # Find the latest NDK version
            NDK_VERSION=$(ls -1 "$base_path" | sort -V | tail -n 1)
            if [ -n "$NDK_VERSION" ]; then
                export ANDROID_NDK_HOME="$base_path/$NDK_VERSION"
                echo "✓ Found NDK: $ANDROID_NDK_HOME"
                break
            fi
        fi
    done
    
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "❌ Error: Could not find Android NDK"
        echo ""
        echo "Please install Android NDK or set ANDROID_NDK_HOME manually:"
        echo "  export ANDROID_NDK_HOME=~/Android/Sdk/ndk/29.0.13846066"
        echo ""
        echo "To install NDK:"
        echo "  Android Studio → SDK Manager → SDK Tools → NDK (Side by side)"
        exit 1
    fi
else
    echo "✓ Using NDK: $ANDROID_NDK_HOME"
fi

echo ""
echo "Step 1: Building Go backend library for Android ARM64..."
cd backend_ffi

CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm64 \
CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang \
go build -buildmode=c-shared -o libbackend.so main.go

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Go backend"
    exit 1
fi

echo "✓ Go backend compiled"

echo ""
echo "Step 2: Copying library to Flutter Android project..."
mkdir -p ../awsmgr_ui/android/app/src/main/jniLibs/arm64-v8a/
cp libbackend.so ../awsmgr_ui/android/app/src/main/jniLibs/arm64-v8a/
echo "✓ Library copied to jniLibs"

cd ..

echo ""
echo "Step 3: Building Flutter Android APK..."
cd awsmgr_ui

flutter clean
flutter pub get
flutter build apk --release

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Flutter APK"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Build Complete!"
echo "=========================================="
echo "APK location: awsmgr_ui/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To install on device:"
echo "  flutter install"
echo "or"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
