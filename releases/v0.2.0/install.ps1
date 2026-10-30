# JTorrent per-user installer. Windows PowerShell 5.1 and PowerShell 7+.
# Usage: irm https://jtorrent.in/install.ps1 | iex
& {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'This installer requires Windows.' }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    function Get-NativeArchitecture {
        # Unlike process architecture, GetNativeSystemInfo stays correct when
        # x86/x64 PowerShell runs under emulation on an ARM64 Windows host.
        if (-not ('JTorrent.InstallerSystemInfo' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace JTorrent {
    public static class InstallerSystemInfo {
        [StructLayout(LayoutKind.Sequential)]
        public struct Info {
            public ushort Architecture, Reserved;
            public uint PageSize;
            public IntPtr MinimumAddress, MaximumAddress;
            public UIntPtr ActiveMask;
            public uint ProcessorCount, ProcessorType, AllocationGranularity;
            public ushort ProcessorLevel, ProcessorRevision;
        }
        [DllImport("kernel32.dll")]
        static extern void GetNativeSystemInfo(out Info info);
        public static ushort Architecture() { Info info; GetNativeSystemInfo(out info); return info.Architecture; }
    }
}
'@
        }
        switch ([JTorrent.InstallerSystemInfo]::Architecture()) {
            9 { return 'amd64' }
            12 { return 'arm64' }
            default { throw 'Unsupported Windows architecture. JTorrent supports AMD64 and ARM64.' }
        }
    }
    function Path-Equals([string]$a, [string]$b) {
        return [string]::Equals([Environment]::ExpandEnvironmentVariables($a.Trim()).TrimEnd('\'), $b.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)
    }
    function Download-File([string]$uri, [string]$destination, [long]$limit) {
        if (-not $uri.StartsWith('https://github.com/OxJacky/jtorrent-cli/releases/download/', [StringComparison]::Ordinal)) { throw 'Unexpected release URL.' }
        Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $destination -TimeoutSec 300
        if ((Get-Item -LiteralPath $destination).Length -gt $limit) { throw 'Downloaded file exceeds the size limit.' }
    }
    function Assert-Version([string]$exe, [string]$version) {
        $output = & $exe version 2>&1
        if ($LASTEXITCODE -ne 0 -or (($output -join "`n").Trim() -ne "jtorrent version $version")) { throw 'The downloaded executable failed its version check.' }
    }

    $arch = Get-NativeArchitecture
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is not set.' }
    $installDir = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\JTorrent'))
    $target = Join-Path $installDir 'jtorrent.exe'
    $marker = Join-Path $installDir '.jtorrent-install.json'
    $stage = $null
    $lock = $null
    $success = $false
    $rollbackFailed = $false
    $pathChanged = $false
    $created = -not (Test-Path -LiteralPath $installDir)
    $oldUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $oldProcessPath = $env:Path
    $changed = [Collections.Generic.List[string]]::new()
    $backedUp = [Collections.Generic.List[string]]::new()
    try {
        if (-not $created) {
            if (((Get-Item -LiteralPath $installDir).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Refusing to install into a linked directory.' }
            if (-not (Test-Path -LiteralPath $marker)) { throw "Existing folder is not managed by this installer: $installDir" }
            $previous = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
            if ($previous.application -ne 'JTorrent' -or -not (Path-Equals $previous.directory $installDir)) { throw 'Invalid installation marker.' }
        } else { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
        $lock = [IO.File]::Open($target + '.update.lock', [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::ReadWrite)
        $lock.Lock(0, 1)
        if (Test-Path -LiteralPath ($target + '.update')) { throw 'An update is pending. Run jtorrent update to recover it before reinstalling.' }
        $stage = Join-Path $installDir ('.install-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $stage | Out-Null
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/OxJacky/jtorrent-cli/releases/latest' -Headers @{ 'User-Agent' = 'jtorrent-installer'; Accept = 'application/vnd.github+json' } -TimeoutSec 30
        if ($release.draft -or $release.prerelease -or $release.tag_name -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'No valid stable release is available.' }
        $version = $release.tag_name.Substring(1)
        $name = "jtorrent_${version}_windows_${arch}.zip"
        $base = 'https://github.com/OxJacky/jtorrent-cli/releases/download/' + $release.tag_name + '/'
        foreach ($asset in @($name, "SHA256SUMS_$version")) {
            $matches = @($release.assets | Where-Object { $_.name -ceq $asset -and $_.browser_download_url -ceq ($base + $asset) })
            if ($matches.Count -ne 1) { throw "Release is missing the expected $asset asset." }
        }
        Write-Host "Downloading JTorrent $version for Windows/$arch..."
        $checksums = Join-Path $stage 'checksums.txt'
        Download-File ($base + "SHA256SUMS_$version") $checksums 65536
        $hashes = @(Get-Content -LiteralPath $checksums | ForEach-Object {
            $fields = $_.Trim() -split '\s+'
            if ($fields.Count -eq 2 -and $fields[1].TrimStart('*') -ceq $name) { $fields[0] }
        })
        if ($hashes.Count -ne 1 -or $hashes[0] -notmatch '^[a-fA-F0-9]{64}$') { throw 'Invalid or missing SHA-256 checksum.' }
        $archive = Join-Path $stage 'download.zip'
        Download-File ($base + $name) $archive 134217728
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ine $hashes[0]) { throw 'SHA-256 verification failed. Installation was not changed.' }
        $zip = [IO.Compression.ZipFile]::OpenRead($archive)
        try {
            foreach ($file in @('jtorrent.exe', 'THIRD-PARTY-NOTICES.txt', 'uninstall.ps1')) {
                $entries = @($zip.Entries | Where-Object { $_.FullName -ceq $file })
                if ($entries.Count -ne 1 -or $entries[0].Length -le 0 -or $entries[0].Length -gt 134217728) { throw "Invalid archive entry: $file" }
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], (Join-Path $stage $file))
            }
        } finally { $zip.Dispose() }
        Assert-Version (Join-Path $stage 'jtorrent.exe') $version
        @{ application = 'JTorrent'; directory = $installDir; version = $version } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage '.jtorrent-install.json') -Encoding UTF8
        foreach ($file in @('jtorrent.exe', 'THIRD-PARTY-NOTICES.txt', 'uninstall.ps1', '.jtorrent-install.json')) {
            $dest = Join-Path $installDir $file
            if (Test-Path -LiteralPath $dest) {
                if (((Get-Item -LiteralPath $dest).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to replace linked file: $dest" }
                [IO.File]::Replace((Join-Path $stage $file), $dest, (Join-Path $stage ($file + '.backup')))
                $backedUp.Add($file)
            } else { [IO.File]::Move((Join-Path $stage $file), $dest) }
            $changed.Add($file)
        }
        Assert-Version $target $version
        $oldUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $parts = @($oldUserPath -split ';' | Where-Object { $_ -and -not (Path-Equals $_ $installDir) })
        [Environment]::SetEnvironmentVariable('Path', (($parts + $installDir) -join ';'), 'User')
        $pathChanged = $true
        $processParts = @($oldProcessPath -split ';' | Where-Object { $_ -and -not (Path-Equals $_ $installDir) })
        $env:Path = (@($installDir) + $processParts) -join ';'
        $success = $true
        Write-Host "Installed JTorrent $version in $installDir"
        Write-Host 'Ready in this PowerShell session. Open a new terminal to use the updated user PATH elsewhere.'
        Write-Host 'Update: jtorrent update'
        Write-Host ('Uninstall: & "' + (Join-Path $installDir 'uninstall.ps1') + '"')
    } catch {
        foreach ($file in $changed) {
            $dest = Join-Path $installDir $file
            try {
                if ($backedUp.Contains($file)) { [IO.File]::Replace((Join-Path $stage ($file + '.backup')), $dest, $null) }
                elseif (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
            } catch { $rollbackFailed = $true; Write-Warning "Rollback incomplete; recovery files retained at $stage" }
        }
        if ($pathChanged) { [Environment]::SetEnvironmentVariable('Path', $oldUserPath, 'User') }
        $env:Path = $oldProcessPath
        throw
    } finally {
        if ($lock) { $lock.Dispose() }
        if (-not $rollbackFailed -and $stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
        if (-not $success -and $created -and (Test-Path -LiteralPath $installDir)) {
            Remove-Item -LiteralPath ($target + '.update.lock') -Force -ErrorAction SilentlyContinue
            if (@(Get-ChildItem -LiteralPath $installDir -Force).Count -eq 0) { Remove-Item -LiteralPath $installDir }
        }
    }
}
