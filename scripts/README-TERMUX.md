# Termux Container Builds

This directory contains scripts for building PRoot in Termux aarch64 containers.

## Overview

The build process uses the official Termux Docker container (`docker.io/termux/termux-docker:aarch64`) to create Android-compatible binaries of PRoot. This ensures the binaries are built with Android's Bionic libc and work correctly on Android/Termux systems.

## Build Scripts

- `build-termux-android-dynamic-aarch64.sh` - Builds a dynamically linked aarch64 binary
- `build-termux-android-static-aarch64.sh` - Builds a statically linked aarch64 binary
- `test-termux-builds.sh` - Local testing script for both builds

## Requirements

### For Local Testing
- **Native ARM64/aarch64 system** (preferred)
- Docker installed
- Internet connectivity

**Note:** While it's possible to run these builds on x86_64 systems using QEMU emulation, DNS resolution issues in the emulated Termux environment may cause package installation to fail. For best results, use a native ARM64 system or the GitHub Actions workflow.

### For GitHub Actions
The workflow uses `ubuntu-24.04-arm64` runners which provide native ARM64 execution environment, avoiding emulation issues.

## Usage

### GitHub Actions (Recommended)
The builds are automatically triggered by the workflow in `.github/workflows/build.yml` on push or pull request to main/master branches.

Artifacts are uploaded as:
- `proot-android-bionic-aarch64` (dynamic build)
- `proot-android-static-aarch64` (static build)

### Local Testing (ARM64 systems only)
```bash
# Test both builds
./scripts/test-termux-builds.sh

# Or run individual builds
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  docker.io/termux/termux-docker:aarch64 \
  bash -c "cd /workspace && bash ./scripts/build-termux-android-dynamic-aarch64.sh"
```

## Build Process

Each build script:
1. Detects the Termux environment
2. Installs required packages (clang, make, wget, python, git)
3. Downloads and compiles talloc library
4. Builds PRoot with the compiled talloc
5. Verifies the binary is aarch64

## Troubleshooting

### DNS Resolution Failures on x86_64
If you see errors like "Could not resolve host" or "None of the mirrors are accessible" on x86_64 systems, this is due to DNS resolution issues in QEMU-emulated ARM64 containers. Solutions:
- Use a native ARM64 system
- Use the GitHub Actions workflow with ARM64 runners
- Pre-build a custom Docker image with packages already installed

### Package Installation Failures
The build scripts include retry logic and fallback mechanisms. If package installation fails but the required tools (clang, make, wget) are already available in the container, the build will continue.

## Container Details

- **Base Image:** `docker.io/termux/termux-docker:aarch64`
- **Architecture:** ARM64/aarch64
- **Libc:** Android Bionic
- **Package Manager:** pkg (Termux package manager)

## Custom Docker Image

The repository includes `Dockerfile.termux-builder` which can be used to pre-build a container with all build tools installed. This is useful if you need to build on systems where the base Termux container has network issues.

To build the custom image (on ARM64 system):
```bash
docker build -f Dockerfile.termux-builder -t termux-proot-builder:latest .
```

Then use this image instead of the base Termux image in your builds.
