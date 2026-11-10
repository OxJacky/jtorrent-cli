# JTorrent v0.2.6

## Choose where downloads are saved

`jtorrent download -o <folder> <magnet>` saves into the folder you name instead of the current directory. The folder is created if it does not exist, and the disk-space check measures that folder's drive.

## Time remaining

Every progress view now shows an estimated time remaining. In multi-connection mode it is one combined figure for the whole download. The single-connection view also shows its speed, which it did not before.

## A signal when the download ends

When a download that ran for more than ten seconds finishes or fails, the terminal bell rings. Linux and macOS also show a desktop notification; nothing extra needs to be installed. Windows gets the bell only. Use `--no-notify` to turn this off. Nothing is signalled after Ctrl+C or when output is piped.

## Third-party notices

The bundled `THIRD-PARTY-NOTICES.txt` now lists the license of every component built into the binaries.

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
