# Removes only the per-user installation. Account settings and downloads remain.
& {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'This uninstaller requires Windows.' }
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is not set.' }
    $dir = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\JTorrent'))
    if (Test-Path -LiteralPath $dir) {
        if (((Get-Item -LiteralPath $dir).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Refusing to uninstall a linked directory.' }
        $marker = Join-Path $dir '.jtorrent-install.json'
        if (-not (Test-Path -LiteralPath $marker)) { throw 'Installation marker missing; refusing to remove files.' }
        $data = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
        if ($data.application -ne 'JTorrent' -or $data.directory -ine $dir) { throw 'Invalid installation marker.' }
        $target = Join-Path $dir 'jtorrent.exe'
        $lock = [IO.File]::Open($target + '.update.lock', [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::ReadWrite)
        try {
            $lock.Lock(0, 1)
            $pending = $target + '.update'
            if (Test-Path -LiteralPath $pending) {
                if (((Get-Item -LiteralPath $pending).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Refusing to remove a linked update directory.' }
                $transaction = Join-Path $pending 'transaction.json'
                $receipt = $target + '.update-result.json'
                if (-not (Test-Path -LiteralPath $transaction) -or -not (Test-Path -LiteralPath $receipt)) { throw 'An update is pending. Run jtorrent update to recover it before uninstalling.' }
                $plan = Get-Content -LiteralPath $transaction -Raw | ConvertFrom-Json
                $result = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
                $failed = $result.PSObject.Properties['error']
                if (($failed -and $failed.Value) -or $result.version -ne $plan.version -or $plan.new_sha256 -notmatch '^[a-fA-F0-9]{64}$' -or (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ine $plan.new_sha256) { throw 'An update needs recovery. Run jtorrent update before uninstalling.' }
                $helper = Join-Path $pending 'helper.exe'
                $deadline = [DateTime]::UtcNow.AddSeconds(3)
                while (Test-Path -LiteralPath $helper) {
                    try { Remove-Item -LiteralPath $helper -Force }
                    catch { if ([DateTime]::UtcNow -gt $deadline) { throw 'Update helper is still exiting; retry uninstall shortly.' }; Start-Sleep -Milliseconds 100 }
                }
                Remove-Item -LiteralPath $pending -Recurse -Force
            }
            foreach ($file in @('jtorrent.exe', 'THIRD-PARTY-NOTICES.txt', 'uninstall.ps1', '.jtorrent-install.json', 'jtorrent.exe.update-result.json')) {
                $path = Join-Path $dir $file
                if (Test-Path -LiteralPath $path) {
                    if (((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to remove linked file: $path" }
                    Remove-Item -LiteralPath $path -Force
                }
            }
        } finally { $lock.Dispose() }
        Remove-Item -LiteralPath ($target + '.update.lock') -Force -ErrorAction SilentlyContinue
        if (@(Get-ChildItem -LiteralPath $dir -Force).Count -eq 0) { Remove-Item -LiteralPath $dir }
    }
    foreach ($scope in @('User', 'Process')) {
        $path = [Environment]::GetEnvironmentVariable('Path', $scope)
        $parts = @($path -split ';' | Where-Object { $_ -and [Environment]::ExpandEnvironmentVariables($_.Trim()).TrimEnd('\') -ine $dir.TrimEnd('\') })
        [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), $scope)
    }
    Write-Host 'JTorrent uninstalled. Your account settings and downloaded files were preserved.'
}
