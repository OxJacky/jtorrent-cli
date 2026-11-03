# JTorrent v0.2.4

Fixes a crash when a torrent display name contains only dots or bracket characters, such as `...`. These names now skip the optional title lookup instead of terminating the CLI. Normal title parsing is preserved and regression tests cover the fix.

Downloads are available for Windows, macOS and Linux on AMD64 and ARM64. SHA-256 checksums are included.

## Update

Homebrew:

```sh
brew update
brew upgrade OxJacky/tap/jtorrent
```

Direct installations:

```sh
jtorrent update
```
