# JTorrent v0.2.5

## Disk-space check before downloading

The CLI now checks free space before it writes anything. A file that cannot fit is refused up front instead of failing partway through, with the space needed, the space free and the shortfall shown. In a terminal you can free up space and press Enter to check again without resubmitting. Files over 4 GiB are refused on FAT drives, which cannot store them.

## Downloads are saved under the file's name

Downloads now go into a folder named after the file, for example `Movie.2026.1080p/Movie.2026.1080p.mkv`, instead of `jtorrent-download-*`. An existing folder is never reused: a taken name gets ` (2)`, ` (3)` and so on.

## Progress line no longer repeats in narrow terminals

The progress line now fits the terminal width. Previously, a terminal narrower than the line printed a new copy on every update.

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
