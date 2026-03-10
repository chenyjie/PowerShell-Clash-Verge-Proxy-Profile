# ===== Clash Verge "Enterprise" Auto Proxy (Matched to your config) =====
# - System Proxy (Mixed): 127.0.0.1:7897
# - External Controller: 127.0.0.1:9097
# - API Secret: 123456
# - No external calls, fast startup.

# ---- Config ----
$global:CLASH_PROXY_HOST = "127.0.0.1"
$global:CLASH_PROXY_PORT = 7897
$global:CLASH_PROXY_URL  = "http://$($global:CLASH_PROXY_HOST):$($global:CLASH_PROXY_PORT)"

$global:CLASH_API_HOST   = "127.0.0.1"
$global:CLASH_API_PORT   = 9097
$global:CLASH_API_SECRET = "123456"
$global:CLASH_API_BASE   = "http://$($global:CLASH_API_HOST):$($global:CLASH_API_PORT)"

function Get-ClashApiHeaders {
    return @{ Authorization = "Bearer $($global:CLASH_API_SECRET)" }
}

# ---- Terminal proxy env management (current session) ----
function Enable-TerminalProxy {
    $env:HTTP_PROXY  = $global:CLASH_PROXY_URL
    $env:HTTPS_PROXY = $global:CLASH_PROXY_URL
    $env:ALL_PROXY   = $global:CLASH_PROXY_URL
    $env:NO_PROXY    = "localhost,127.0.0.1,::1,*.local"
}

function Disable-TerminalProxy {
    Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
    Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:ALL_PROXY   -ErrorAction SilentlyContinue
    Remove-Item Env:NO_PROXY    -ErrorAction SilentlyContinue
}

# ---- Windows system proxy detection ----
function Get-WindowsSystemProxyStatus {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    try {
        $v = Get-ItemProperty -Path $regPath -ErrorAction Stop
        $enabled = [bool]($v.ProxyEnable -eq 1)
        $server  = [string]$v.ProxyServer
        return [pscustomobject]@{
            Enabled = $enabled
            Server  = $server
        }
    } catch {
        return [pscustomobject]@{
            Enabled = $false
            Server  = ""
        }
    }
}

function Test-ProxyServerMatchesClash([string]$server) {
    if ([string]::IsNullOrWhiteSpace($server)) { return $false }

    $target = "$($global:CLASH_PROXY_HOST):$($global:CLASH_PROXY_PORT)"

    # possible formats:
    # 1) "127.0.0.1:7897"
    # 2) "http=127.0.0.1:7897;https=127.0.0.1:7897"
    if ($server -match "(^|;|\s)http=$([regex]::Escape($target))($|;)" ) { return $true }
    if ($server -match "(^|;|\s)https=$([regex]::Escape($target))($|;)" ) { return $true }
    if ($server.Trim() -eq $target) { return $true }

    return $false
}

# ---- Clash API ----
function Get-ClashVersion {
    try {
        $headers = Get-ClashApiHeaders
        $r = Invoke-RestMethod -Uri "$($global:CLASH_API_BASE)/version" -Headers $headers -TimeoutSec 1 -ErrorAction Stop
        return $r
    } catch {
        return $null
    }
}

function Get-ClashMode {
    try {
        $headers = Get-ClashApiHeaders
        $cfg = Invoke-RestMethod -Uri "$($global:CLASH_API_BASE)/configs" -Headers $headers -TimeoutSec 1 -ErrorAction Stop
        if ($cfg -and $cfg.mode) { return [string]$cfg.mode }
        return $null
    } catch {
        return $null
    }
}

# ---- Startup ----
function Show-ProxyStartupStatus {
    $win  = Get-WindowsSystemProxyStatus
    $api  = Get-ClashVersion
    $mode = $null
    if ($api) { $mode = Get-ClashMode }

    $sysOn  = $win.Enabled
    $sysHit = $sysOn -and (Test-ProxyServerMatchesClash $win.Server)

    # Only enable terminal proxy when system proxy is ON and pointing to Clash
    if ($sysHit) {
        Enable-TerminalProxy
        Write-Host ""
        Write-Host "[PROXY ON ] Terminal -> $($global:CLASH_PROXY_URL)" -ForegroundColor Green
    } else {
        Disable-TerminalProxy
        Write-Host ""
        Write-Host "[PROXY OFF] Terminal" -ForegroundColor Red
    }

    # Enterprise diagnostics
    if ($api) {
        Write-Host "Clash Core : OK ($($api.version))" -ForegroundColor DarkGreen
        if ($mode) { Write-Host "Clash Mode : $mode" }
        else { Write-Host "Clash Mode : (unknown)" -ForegroundColor Yellow }
    } else {
        Write-Host "Clash Core : (API not reachable on $($global:CLASH_API_BASE))" -ForegroundColor Yellow
    }

    if ($sysOn) {
        if ($sysHit) {
            Write-Host "Sys Proxy  : ON  ($($win.Server))" -ForegroundColor DarkGreen
        } else {
            Write-Host "Sys Proxy  : ON  (but not pointing to $($global:CLASH_PROXY_HOST):$($global:CLASH_PROXY_PORT))" -ForegroundColor Yellow
            Write-Host "            Current: $($win.Server)" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "Sys Proxy  : OFF" -ForegroundColor DarkYellow
    }
}

# ---- Convenience commands ----
function proxy     { Enable-TerminalProxy;  Write-Host "[PROXY ON ] Terminal -> $($global:CLASH_PROXY_URL)" -ForegroundColor Green }
function unproxy   { Disable-TerminalProxy; Write-Host "[PROXY OFF] Terminal" -ForegroundColor Red }
function proxy-status {
    Write-Host "HTTP_PROXY  = $env:HTTP_PROXY"
    Write-Host "HTTPS_PROXY = $env:HTTPS_PROXY"
    Write-Host "ALL_PROXY   = $env:ALL_PROXY"
    Write-Host "NO_PROXY    = $env:NO_PROXY"
}

Show-ProxyStartupStatus
# ===== End =====