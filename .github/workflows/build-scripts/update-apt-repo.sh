#!/usr/bin/env bash
#
# update-apt-repo.sh - Regenerate APT repository metadata.
#
# Usage: update-apt-repo.sh <repo-dir>
#   repo-dir : root of the gh-pages checkout containing the apt/ directory
#
# Prerequisites:
#   - dpkg-dev (for dpkg-scanpackages)
#   - gpg with the signing key already imported
#   - APT_GPG_PASSPHRASE environment variable set
#
# Expected layout:
#   repo-dir/apt/pool/main/*.deb
#
# Produces:
#   repo-dir/apt/dists/stable/main/binary-{amd64,arm64}/Packages{,.gz}
#   repo-dir/apt/dists/stable/Release
#   repo-dir/apt/dists/stable/Release.gpg
#   repo-dir/apt/dists/stable/InRelease
#

set -euo pipefail

# ── Validate arguments ─────────────────────────────────────────────────
if [ $# -ne 1 ]; then
  echo "Usage: $0 <repo-dir>" >&2
  exit 1
fi

REPO_DIR="$1"
APT_DIR="${REPO_DIR}/apt"
DISTS_DIR="${APT_DIR}/dists/stable"
POOL_DIR="${APT_DIR}/pool/main"

if [ ! -d "$POOL_DIR" ]; then
  echo "Error: pool directory not found at '$POOL_DIR'" >&2
  exit 1
fi

if [ -z "${APT_GPG_PASSPHRASE:-}" ]; then
  echo "Error: APT_GPG_PASSPHRASE environment variable is not set" >&2
  exit 1
fi

# ── Determine GPG key ID ──────────────────────────────────────────────
GPG_KEY_ID=$(gpg --list-keys --with-colons | awk -F: '/^pub/{found=1} found && /^fpr/{print $10; exit}')
if [ -z "$GPG_KEY_ID" ]; then
  echo "Error: no GPG key found in keyring" >&2
  exit 1
fi
echo "Using GPG key: ${GPG_KEY_ID}"

# ── Create directory structure ─────────────────────────────────────────
for arch in amd64 arm64; do
  mkdir -p "${DISTS_DIR}/main/binary-${arch}"
done

# ── Generate Packages files for each architecture ──────────────────────
echo "Generating Packages indices..."
cd "$APT_DIR"

for arch in amd64 arm64; do
  BINARY_DIR="dists/stable/main/binary-${arch}"

  # dpkg-scanpackages scans pool/ and produces a Packages file
  # Filter to only the matching architecture
  dpkg-scanpackages --arch "$arch" pool/main /dev/null > "${BINARY_DIR}/Packages"

  gzip -9c "${BINARY_DIR}/Packages" > "${BINARY_DIR}/Packages.gz"

  PKG_COUNT=$(grep -c "^Package:" "${BINARY_DIR}/Packages" 2>/dev/null || echo 0)
  echo "  ${arch}: ${PKG_COUNT} package(s)"
done

# ── Generate Release file ─────────────────────────────────────────────
echo "Generating Release file..."

# Compute checksums for all Packages files
{
  cat << EOF
Origin: Aptos Labs
Label: Aptos CLI
Suite: stable
Codename: stable
Architectures: amd64 arm64
Components: main
Description: Aptos CLI APT repository
Date: $(date -Ru)
EOF

  # MD5Sum section
  echo "MD5Sum:"
  for arch in amd64 arm64; do
    for file in "main/binary-${arch}/Packages" "main/binary-${arch}/Packages.gz"; do
      FILEPATH="dists/stable/${file}"
      if [ -f "$FILEPATH" ]; then
        SIZE=$(wc -c < "$FILEPATH")
        MD5=$(md5sum "$FILEPATH" | cut -d' ' -f1)
        printf " %s %16d %s\n" "$MD5" "$SIZE" "$file"
      fi
    done
  done

  # SHA256 section
  echo "SHA256:"
  for arch in amd64 arm64; do
    for file in "main/binary-${arch}/Packages" "main/binary-${arch}/Packages.gz"; do
      FILEPATH="dists/stable/${file}"
      if [ -f "$FILEPATH" ]; then
        SIZE=$(wc -c < "$FILEPATH")
        SHA256=$(sha256sum "$FILEPATH" | cut -d' ' -f1)
        printf " %s %16d %s\n" "$SHA256" "$SIZE" "$file"
      fi
    done
  done
} > "${DISTS_DIR}/Release"

# ── Sign the Release file ─────────────────────────────────────────────
echo "Signing Release file..."

# Detached signature (Release.gpg)
gpg --batch --yes --pinentry-mode loopback \
  --passphrase "$APT_GPG_PASSPHRASE" \
  --default-key "$GPG_KEY_ID" \
  --armor --detach-sign \
  --output "${DISTS_DIR}/Release.gpg" \
  "${DISTS_DIR}/Release"

# Clearsigned (InRelease)
gpg --batch --yes --pinentry-mode loopback \
  --passphrase "$APT_GPG_PASSPHRASE" \
  --default-key "$GPG_KEY_ID" \
  --armor --clearsign \
  --output "${DISTS_DIR}/InRelease" \
  "${DISTS_DIR}/Release"

cd - > /dev/null

echo "APT repository updated successfully."
echo "  Pool: $(ls "${POOL_DIR}"/*.deb 2>/dev/null | wc -l) .deb file(s)"
echo "  Dists: ${DISTS_DIR}"
