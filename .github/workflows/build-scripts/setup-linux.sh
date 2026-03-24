#!/bin/bash
set -euo pipefail

# Install build dependencies for the Aptos CLI on Linux.
# Works on both native runners (via sudo) and containers (where sudo is pre-installed).
# Note: DEBIAN_FRONTEND must be passed through sudo explicitly (sudo drops env vars).

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl ca-certificates build-essential pkg-config \
  libssl-dev git libudev-dev lld libdw-dev clang llvm cmake unzip zip
