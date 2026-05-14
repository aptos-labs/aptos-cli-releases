# Aptos CLI Releases

Cross-platform release builds and package manager distribution for the [Aptos CLI](https://github.com/aptos-labs/aptos-core).

This repo watches for new `aptos-cli-v*` tags in `aptos-labs/aptos-core`, builds binaries for all supported platforms, publishes a GitHub Release, and distributes to package managers automatically.

## Install

### Homebrew (macOS / Linux)

```bash
brew tap aptos-labs/aptos
brew install aptos-labs/aptos/aptos
```

### APT (Debian / Ubuntu)

```bash
curl -fsSL https://aptos-labs.github.io/aptos-cli-releases/apt/aptos.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aptos.gpg
echo "deb [signed-by=/usr/share/keyrings/aptos.gpg] https://aptos-labs.github.io/aptos-cli-releases/apt stable main" | sudo tee /etc/apt/sources.list.d/aptos.list
sudo apt update && sudo apt install aptos-cli
```

### AUR (Arch Linux)

```bash
yay -S aptos-bin
```

### Chocolatey (Windows)

```powershell
choco install aptos-cli
```

### winget (Windows)

```powershell
winget install AptosLabs.AptosCLI
```

### asdf

```bash
asdf plugin add aptos https://github.com/gregnazario/asdf-aptos.git
asdf install aptos latest
asdf set -u aptos latest
```

### mise

```bash
mise install aptos@latest
mise use -g aptos@latest
```

### Scoop (Windows)

```powershell
scoop bucket add aptos https://github.com/aptos-labs/scoop-aptos
scoop install aptos-cli
```

### Nix

```bash
nix-env -iA nixpkgs.aptos-cli-bin
```

### Docker

```bash
docker run --rm ghcr.io/aptos-labs/aptos-cli:latest --version
```

Or in a Dockerfile:
```dockerfile
FROM ghcr.io/aptos-labs/aptos-cli:latest
```

### GitHub Actions

```yaml
- uses: aptos-labs/aptos-cli-releases/actions/setup-aptos@main
  with:
    version: latest  # or a specific version like "9.0.0"
- run: aptos --version
```

### Direct Download

Download pre-built binaries from the [Releases page](https://github.com/aptos-labs/aptos-cli-releases/releases).

## Supported Platforms

| Platform | Architecture | Archive |
|----------|-------------|---------|
| macOS | x86_64 (Intel) | `aptos-cli-{VERSION}-x86_64-apple-darwin.zip` |
| macOS | ARM64 (Apple Silicon) | `aptos-cli-{VERSION}-aarch64-apple-darwin.zip` |
| Linux | x86_64 | `aptos-cli-{VERSION}-x86_64-unknown-linux-gnu.zip` |
| Linux | ARM64 | `aptos-cli-{VERSION}-aarch64-unknown-linux-gnu.zip` |
| Linux | x86_64 (compat, GLIBC 2.31+) | `aptos-cli-{VERSION}-x86_64-unknown-linux-gnu-compat.zip` |
| Linux | ARM64 (compat, GLIBC 2.31+) | `aptos-cli-{VERSION}-aarch64-unknown-linux-gnu-compat.zip` |
| Windows | x86_64 | `aptos-cli-{VERSION}-x86_64-pc-windows-msvc.zip` |

## How It Works

1. **Check** (every 6 hours or manual trigger) — polls `aptos-labs/aptos-core` for new `aptos-cli-v*` releases
2. **Build** — compiles `aptos` for all platform targets in parallel
3. **Release** — creates a GitHub Release with all binaries and SHA256 checksums
4. **Distribute** — separate workflows publish to each package manager on release

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `release.yml` | Schedule / manual | Build binaries and create GitHub Release |
| `publish-homebrew.yml` | `release: published` | Update Homebrew tap formula |
| `publish-apt.yml` | `release: published` | Build `.deb` packages, update APT repo on GitHub Pages |
| `publish-aur.yml` | `release: published` | Update AUR `aptos-bin` PKGBUILD |
| `publish-chocolatey.yml` | `release: published` | Push to chocolatey.org |
| `publish-winget.yml` | `release: published` | Submit PR to `microsoft/winget-pkgs` |
| `publish-scoop.yml` | `release: published` | Update Scoop bucket manifest |
| `publish-docker.yml` | `release: published` | Build and push multi-arch Docker image to GHCR |
| `publish-nix.yml` | `release: published` | Submit PR to nixpkgs |

## Setup Guide

### Prerequisites

The main `release.yml` requires these secrets (already configured):

| Secret | Purpose |
|--------|---------|
| `APTOS_PRIVATE_KEY` | Shelby sccache authentication |
| `SHELBY_API_KEY` | Shelby sccache authentication |

### Homebrew Tap

1. Create the repo `aptos-labs/homebrew-aptos` on GitHub (can be empty)
2. Generate a GitHub PAT with `repo` scope
3. Add secret `HOMEBREW_TAP_TOKEN` to this repo

### APT Repository (Debian/Ubuntu)

1. Generate a dedicated GPG key pair:
   ```bash
   gpg --full-generate-key  # RSA 4096, no expiry recommended for repo signing
   ```
2. Export the private key:
   ```bash
   gpg --export-secret-keys --armor <KEY_ID>
   ```
3. Add secrets to this repo:
   - `APT_GPG_PRIVATE_KEY` — the full armored private key
   - `APT_GPG_PASSPHRASE` — the key passphrase
4. Create and push an empty `gh-pages` branch:
   ```bash
   git checkout --orphan gh-pages
   git reset --hard
   git commit --allow-empty -m "Initialize gh-pages"
   git push origin gh-pages
   ```
5. Enable GitHub Pages in repo settings, source: `gh-pages` branch

### AUR (Arch Linux)

1. Create an account on https://aur.archlinux.org
2. Register the package `aptos-bin`:
   ```bash
   git clone ssh://aur@aur.archlinux.org/aptos-bin.git
   # Add initial PKGBUILD and .SRCINFO, then push
   ```
3. Generate an SSH key and add the public key to your AUR account
4. Add secret `AUR_SSH_PRIVATE_KEY` to this repo

### Chocolatey

1. Create an account on https://community.chocolatey.org
2. Register the package ID `aptos-cli`
3. Get your API key from https://community.chocolatey.org/account
4. Add secret `CHOCOLATEY_API_KEY` to this repo

### winget

1. Submit an initial manifest to `microsoft/winget-pkgs` for `AptosLabs.AptosCLI`:
   ```bash
   wingetcreate new https://github.com/aptos-labs/aptos-cli-releases/releases/download/aptos-cli-vX.Y.Z/aptos-cli-X.Y.Z-x86_64-pc-windows-msvc.zip
   ```
2. Generate a GitHub PAT with `public_repo` scope
3. Add secret `WINGET_GITHUB_PAT` to this repo

### Scoop

1. Create the repo `aptos-labs/scoop-aptos` on GitHub (can be empty)
2. Generate a GitHub PAT with `repo` scope
3. Add secret `SCOOP_BUCKET_TOKEN` to this repo

### Docker (GHCR)

No secrets needed — uses the built-in `GITHUB_TOKEN` with `packages: write` permission. Images are published to `ghcr.io/aptos-labs/aptos-cli`.

### Nix (nixpkgs)

1. Generate a GitHub PAT with `public_repo` scope (for forking and creating PRs to NixOS/nixpkgs)
2. Add secret `NIXPKGS_GITHUB_PAT` to this repo
3. The first PR to nixpkgs requires manual review; subsequent updates will be automated

### GitHub Actions (`setup-aptos`)

No secrets needed — the action is a composite action that lives in this repo at `actions/setup-aptos/`. Users reference it as:
```yaml
- uses: aptos-labs/aptos-cli-releases/actions/setup-aptos@main
```

### asdf Plugin

The plugin at [gregnazario/asdf-aptos](https://github.com/gregnazario/asdf-aptos) downloads binaries from this repo's releases. No secrets needed — the plugin is updated independently.

### mise

mise uses the asdf plugin automatically. Optionally register in the [mise registry](https://github.com/jdx/mise/tree/main/registry) by adding:
```
aptos = "asdf:gregnazario/asdf-aptos"
```

## Adding a New Package Manager

1. Create a new workflow file `.github/workflows/publish-<name>.yml`
2. Trigger on `release: types: [published]`
3. Skip pre-releases with `if: "!github.event.release.prerelease"`
4. Download `SHA256SUMS` from the release for checksum verification
5. Use `$` anchoring when grepping checksums to avoid matching `-compat` variants
6. Add any required secrets to the repo settings
7. Update this README

## Future Package Managers

| Manager | Platform | Status | Notes |
|---------|----------|--------|-------|
| Snap | Linux | Planned | |
| RPM/DNF (Fedora/RHEL) | Linux | Planned | COPR or custom repo |
| Alpine APK | Alpine Linux | Blocked | Requires musl compilation support in aptos-core |

## Verification

All releases include a `SHA256SUMS` file. Verify after downloading:

```bash
sha256sum -c SHA256SUMS
```
