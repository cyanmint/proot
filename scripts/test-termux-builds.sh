#!/bin/bash
# Script to test Termux container builds locally
# NOTE: This requires a native ARM64/aarch64 system to work properly
# On x86_64 systems with QEMU emulation, DNS resolution may fail in the Termux container

set -e

echo "Testing Termux container builds locally..."
echo "=========================================="

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo "WARNING: You are running on $ARCH architecture."
    echo "Termux container builds work best on native ARM64/aarch64 systems."
    echo "On x86_64 with QEMU emulation, you may encounter DNS resolution issues."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Pull the Termux container
echo "Pulling Termux container..."
docker pull docker.io/termux/termux-docker:aarch64

# Test dynamic build
echo ""
echo "Testing dynamic build..."
echo "========================"
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  docker.io/termux/termux-docker:aarch64 \
  bash -c "cd /workspace && bash ./scripts/build-termux-android-dynamic-aarch64.sh"

if [ -f "src/proot" ]; then
    echo "✓ Dynamic build successful!"
    echo "Binary info:"
    file src/proot
    ls -lh src/proot
    mv src/proot src/proot-dynamic-test
else
    echo "✗ Dynamic build failed - binary not found"
    exit 1
fi

# Clean up
make -C src clean || true

# Test static build
echo ""
echo "Testing static build..."
echo "======================="
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  docker.io/termux/termux-docker:aarch64 \
  bash -c "cd /workspace && bash ./scripts/build-termux-android-static-aarch64.sh"

if [ -f "src/proot" ]; then
    echo "✓ Static build successful!"
    echo "Binary info:"
    file src/proot
    ls -lh src/proot
    mv src/proot src/proot-static-test
else
    echo "✗ Static build failed - binary not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "All tests passed!"
echo "Test binaries:"
echo "  - src/proot-dynamic-test"
echo "  - src/proot-static-test"
echo "=========================================="
