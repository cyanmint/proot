#!/bin/bash
# Build script for proot with Android Bionic libc (dynamic, aarch64)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-/tmp/proot-build-android}"

echo "=========================================="
echo "Building proot with Android Bionic (dynamic, aarch64)"
echo "=========================================="

# Check for Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
  echo "ERROR: ANDROID_NDK_HOME not set"
  exit 1
fi

echo "Using Android NDK: $ANDROID_NDK_HOME"

# Install build dependencies
echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y python3-dev wget

# Build talloc for Android aarch64
echo "Building talloc for Android aarch64..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -d "talloc-2.4.2" ]; then
  wget -q https://www.samba.org/ftp/talloc/talloc-2.4.2.tar.gz
  tar -xzf talloc-2.4.2.tar.gz
fi

cd talloc-2.4.2

# Setup Android NDK environment
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
export TARGET=aarch64-linux-android
export API=21
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AR=$TOOLCHAIN/bin/llvm-ar
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib

# Build talloc for Android
./configure --prefix=/tmp/android-talloc \
  --disable-python --disable-rpath \
  --cross-compile --cross-execute=""
make -j$(nproc)
make install

# Build proot
echo "Building proot..."
cd "$REPO_ROOT/src"
make clean

export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
export TARGET=aarch64-linux-android
export API=21
export CC=$TOOLCHAIN/bin/$TARGET$API-clang

CC=$CC \
  CFLAGS="-I/tmp/android-talloc/include -I$REPO_ROOT/src/compat" \
  LDFLAGS="-L/tmp/android-talloc/lib" \
  make

# Verify
echo "Verifying build..."
file proot
ls -lh proot

# Verify architecture
if file proot | grep -q aarch64; then
  echo "✓ Successfully built aarch64 binary"
else
  echo "✗ ERROR: Not aarch64 binary"
  exit 1
fi

echo "=========================================="
echo "Build completed successfully!"
echo "Binary: $REPO_ROOT/src/proot"
echo "=========================================="
