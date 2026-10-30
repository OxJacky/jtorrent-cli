Premium downloads can now use available Ethernet, Wi-Fi and USB tethering connections together on Linux and macOS. Reachable connections are discovered automatically, with failover and recovery when a connection drops or returns.

- Adaptive parallel downloads for completed files delivered from JTorrent servers.
- A terminal-size-aware progress display with per-connection speeds and downloaded bytes, plus final transfer time and average speed.
- Use `--single-network` to keep downloads on the system’s default connection. Automatic mode may use mobile data and physical connections outside a VPN.

Available for macOS and Linux on Intel/AMD64 and ARM64. Live direct-stream downloads retain their existing behavior. Actual speed depends on the source and available independent internet connections.

Update with `brew update && brew upgrade jtorrent`.

## Third-party license

The multi-connection download implementation includes code adapted from [Plexo](https://github.com/anmolkapil/plexo) by Anmol Kapil. The following MIT license applies to those portions.

```text
MIT License

Copyright (c) 2026 Anmol Kapil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
