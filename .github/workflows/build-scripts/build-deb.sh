#!/usr/bin/env bash
#
# build-deb.sh - Build a .deb package for the Aptos CLI binary.
#
# Usage: build-deb.sh <binary-path> <version> <arch> <output-dir>
#   binary-path : path to the aptos binary
#   version     : semantic version, e.g. 9.0.0
#   arch        : Debian architecture (amd64 or arm64)
#   output-dir  : directory where the .deb file will be placed
#

set -euo pipefail

# ── Validate arguments ─────────────────────────────────────────────────
if [ $# -ne 4 ]; then
  echo "Usage: $0 <binary-path> <version> <arch> <output-dir>" >&2
  exit 1
fi

BINARY_PATH="$1"
VERSION="$2"
ARCH="$3"
OUTPUT_DIR="$4"

if [ ! -f "$BINARY_PATH" ]; then
  echo "Error: binary not found at '$BINARY_PATH'" >&2
  exit 1
fi

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
  echo "Error: arch must be 'amd64' or 'arm64', got '$ARCH'" >&2
  exit 1
fi

PACKAGE_NAME="aptos-cli"
DEB_FILENAME="${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo "Building ${DEB_FILENAME}..."

# ── Create package directory structure ─────────────────────────────────
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PKG_DIR="${WORK_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/local/bin"

# ── Write the control file ─────────────────────────────────────────────
INSTALLED_SIZE=$(du -k "$BINARY_PATH" | cut -f1)

cat > "${PKG_DIR}/DEBIAN/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Architecture: ${ARCH}
Maintainer: Aptos Labs <opensource@aptoslabs.com>
Description: CLI for the Aptos blockchain
 The Aptos CLI is a tool for interacting with the Aptos blockchain,
 including compiling and deploying Move modules, managing accounts,
 and running a local development network.
Section: utils
Priority: optional
Installed-Size: ${INSTALLED_SIZE}
EOF

# ── Install the binary ─────────────────────────────────────────────────
cp "$BINARY_PATH" "${PKG_DIR}/usr/local/bin/aptos"
chmod 755 "${PKG_DIR}/usr/local/bin/aptos"

# ── Build the .deb package ─────────────────────────────────────────────
dpkg-deb --build --root-owner-group "$PKG_DIR" "${WORK_DIR}/${DEB_FILENAME}"

# ── Move to output directory ───────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"
mv "${WORK_DIR}/${DEB_FILENAME}" "${OUTPUT_DIR}/"

echo "Successfully built: ${OUTPUT_DIR}/${DEB_FILENAME}"
