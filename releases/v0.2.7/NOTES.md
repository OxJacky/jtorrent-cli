# JTorrent v0.2.7

## Clearer help

`jtorrent --help` now shows the download options by example, including `-o` to choose the folder and `--no-notify`. Previously they appeared only under `jtorrent download --help`. The download help itself is now a short summary with examples instead of one long paragraph.

No change to how downloads work.

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
