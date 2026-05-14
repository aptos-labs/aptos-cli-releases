# Aptos CLI Releases

This repository builds and publishes prebuilt binaries of the [Aptos CLI](https://github.com/aptos-labs/aptos-core/tree/main/crates/aptos) for platforms that aren't covered (or aren't covered as broadly) by the upstream [`aptos-labs/aptos-core`](https://github.com/aptos-labs/aptos-core) release pipeline.

The CLI source code lives in `aptos-core`; this repo only contains the release tooling, a mirrored changelog, and the resulting downloads.

## Downloads

Released binaries are attached to GitHub releases on this repo:

➡️ **[Latest release](https://github.com/aptos-labs/aptos-cli-releases/releases/latest)**

Each release ships a zip per platform plus a `SHA256SUMS` file. To verify a download:

```bash
sha256sum -c SHA256SUMS
```

## Supported platforms

Each release includes the following targets:

| Platform | Target triple | Notes |
|---|---|---|
| macOS x86_64 | `x86_64-apple-darwin` | |
| macOS ARM64 | `aarch64-apple-darwin` | |
| Linux x86_64 | `x86_64-unknown-linux-gnu` | Built on modern Ubuntu |
| Linux ARM64 | `aarch64-unknown-linux-gnu` | Built on modern Ubuntu |
| Linux x86_64 (compat) | `x86_64-unknown-linux-gnu` | Built in `ubuntu:20.04` for older GLIBC (2.31+) |
| Linux ARM64 (compat) | `aarch64-unknown-linux-gnu` | Built in `ubuntu:20.04` for older GLIBC (2.31+) |
| Windows x86_64 | `x86_64-pc-windows-msvc` | |

If you hit `GLIBC_2.XX not found` on Linux, grab the `*-compat` zip.

## How releases are produced

The [`Release`](.github/workflows/release.yml) workflow runs on a schedule (every 6 hours) and on manual dispatch. On each run it:

1. Looks at `aptos-labs/aptos-core` and finds the latest `aptos-cli-v*` tag.
2. Skips if a release for that tag already exists here.
3. Otherwise, checks out `aptos-core` at that tag, builds the CLI for every platform in the matrix, and uploads zips as workflow artifacts.
4. Collects all artifacts, generates `SHA256SUMS`, extracts the matching section of the upstream `CHANGELOG.md`, and publishes a GitHub release.
5. Commits the updated `CHANGELOG.md` snapshot back to this repo.

### Manual dispatch

You can also trigger the workflow by hand from the Actions tab:

- **`tag`** — build a specific tag (e.g. `aptos-cli-v9.2.0`) instead of the latest. Useful for backfilling older versions.
- **`backfill`** — add the Windows artifact (and merge it into `SHA256SUMS`) for an existing release without rebuilding or republishing the other platforms.

## Source of truth

- **CLI source code & issues:** [`aptos-labs/aptos-core`](https://github.com/aptos-labs/aptos-core)
- **Upstream changelog:** [`crates/aptos/CHANGELOG.md`](https://github.com/aptos-labs/aptos-core/blob/main/crates/aptos/CHANGELOG.md) (mirrored here as [`CHANGELOG.md`](CHANGELOG.md))
- **Prebuilt binaries:** this repo's [Releases](https://github.com/aptos-labs/aptos-cli-releases/releases) page
