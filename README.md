# JTorrent CLI

### Your downloads, one command away.

JTorrent brings the [JTorrent](https://jtorrent.in) download experience to your terminal. Give it a magnet link or a `.torrent` file, watch the progress, and get the finished file in your current directory. No local torrent-client setup required.

**Available for macOS and Linux · ARM64 and AMD64**

## Get started

Install with Homebrew:

```sh
brew install OxJacky/tap/jtorrent
```

Then start a download:

```sh
jtorrent download 'magnet:?xt=urn:btih:...'
# or
jtorrent download ./example.torrent
```

JTorrent creates a new `jtorrent-download-*` folder in the directory where you run the command and saves the completed file there. You can use the CLI without logging in, or connect your JTorrent account:

```sh
jtorrent login
jtorrent whoami
```

`login` opens a browser for approval. If it doesn't open automatically, the CLI shows a link and code to complete sign-in yourself.

## How it works

1. Submit a magnet link or local `.torrent` file from your terminal.
2. JTorrent handles the torrent download in its cloud service while the CLI shows its status and progress.
3. When it's ready, the CLI transfers the finished file to your machine and shows where it was saved.

Keep the terminal open until the transfer finishes. Pressing Ctrl+C stops the current CLI run and removes its unfinished local file; it does not remove a previously completed download.

## Commands

| Command | What it does |
| --- | --- |
| `jtorrent download <magnet-link-or-.torrent-file>` | Submit a torrent and download the finished file here. |
| `jtorrent login` | Connect your JTorrent account through your browser. |
| `jtorrent logout` | Sign out on this machine. |
| `jtorrent whoami` | Show the signed-in account and tier. |
| `jtorrent --version` | Show the installed version. |
| `jtorrent help` | Explore commands and options. |
| `jtorrent completion <shell>` | Generate shell-completion instructions. |

Run `jtorrent <command> --help` for command-specific help.

## Why use JTorrent CLI?

- **Terminal-native workflow.** Start a download wherever you're already working, without switching apps.
- **No local torrent setup.** JTorrent handles the torrent stage; the CLI fetches the result to your machine.
- **One clear progress view.** Follow the job and the final file transfer in the same terminal.
- **Your account, if you want it.** Use the CLI as a guest or sign in to your JTorrent account.
- **Ready for your machine.** Homebrew installation for macOS and Linux on ARM64 and AMD64.

Torrent availability and transfer speeds depend on the source and your connection.

## Updates

The CLI checks for a newer release and can show an update notice. To install updates when you choose:

```sh
brew update && brew upgrade jtorrent
```

You can also download a binary from [GitHub Releases](https://github.com/OxJacky/jtorrent-cli/releases).
