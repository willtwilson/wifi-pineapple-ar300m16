<#
.SYNOPSIS
    Installs the WiFi Pineapple clone firmware onto a GL.iNet GL-AR300M16
    running stock firmware. Run this AFTER joining the router's Wi-Fi
    (SSID: GL-AR300M-feb, password: goodlife) or after plugging into its
    LAN port via Ethernet.

.DESCRIPTION
    1. Tests SSH connectivity to 192.168.8.1
    2. SCPs gl-ar300m-universal-sysupgrade.bin to /tmp/ on the router
    3. Runs sysupgrade -n -F to flash the Pineapple clone image
    4. Waits for reboot and probes for the Pineapple panel

.NOTES
    You will lose internet while connected to the router (it's factory
    default with no upstream). This script only needs local LAN access.
#>

[CmdletBinding()]
param(
    [string]$RouterIP = '192.168.8.1',
    [string]$RouterUser = 'root',
    [string]$RouterPass = 'REDACTED-ROTATED-2026-10-07',
    [string]$FirmwarePath = (Join-Path $PSScriptRoot 'firmware\gl-ar300m-universal-sysupgrade.bin')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host ''
Write-Host '=== WiFi Pineapple Clone Installer for GL-AR300M16 ===' -ForegroundColor Cyan
Write-Host ''

# ---- Step 0: Sanity checks ---------------------------------------------------

if (-not (Test-Path -LiteralPath $FirmwarePath)) {
    throw "Firmware not found: $FirmwarePath`nRun Get-Firmware.ps1 first, or download from https://github.com/0x29aNull/WiFi-Pineapple/raw/main/gl-ar300m-universal-sysupgrade.bin"
}

$fwSize = [math]::Round((Get-Item $FirmwarePath).Length / 1MB, 2)
Write-Host "[0/5] Firmware: $FirmwarePath ($fwSize MB)" -ForegroundColor Gray

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) { throw 'ssh not found — install OpenSSH client' }
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) { throw 'scp not found — install OpenSSH client' }

# ---- Step 1: Test connectivity -----------------------------------------------

Write-Host "[1/5] Testing connectivity to $RouterIP ..." -ForegroundColor Yellow -NoNewline
$ping = New-Object System.Net.NetworkInformation.Ping
try {
    $r = $ping.Send($RouterIP, 3000)
    if ($r.Status -ne 'Success') { throw "Ping failed: $($r.Status)" }
    Write-Host " OK ($($r.RoundtripTime)ms)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "Make sure you are connected to the router (Wi-Fi SSID 'GL-AR300M-feb' or Ethernet LAN)." -ForegroundColor Red
    throw
}

# ---- Step 2: Test SSH --------------------------------------------------------

Write-Host "[2/5] Testing SSH to ${RouterUser}@$RouterIP ..." -ForegroundColor Yellow -NoNewline
$sshOpts = @('-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL', '-o', 'ConnectTimeout=10', '-o', 'BatchMode=yes')
# First try passwordless (GL.iNet stock sometimes allows it)
$sshTest = & ssh @sshOpts "${RouterUser}@$RouterIP" 'echo SSH_OK' 2>&1
if ($sshTest -notmatch 'SSH_OK') {
    # Try with sshpass equivalent — Windows doesn't have sshpass, so we use a different approach
    Write-Host " needs password" -ForegroundColor Yellow
    Write-Host "       (Windows OpenSSH doesn't support inline passwords. Using SSH key trick.)" -ForegroundColor Gray

    # Generate a temporary key and push it via the GL.iNet web API
    # Actually, GL.iNet stock firmware SSH requires the admin password.
    # On Windows, the cleanest way is to use plink (PuTTY) if available,
    # or fall back to manual instructions.

    $plink = Get-Command plink -ErrorAction SilentlyContinue
    if ($plink) {
        Write-Host "       Found plink at $($plink.Source) — using it for password auth." -ForegroundColor Gray
        $usePlink = $true
    } else {
        Write-Host "       plink not found. Trying sshpass..." -ForegroundColor Gray
        $sshpass = Get-Command sshpass -ErrorAction SilentlyContinue
        if ($sshpass) {
            $useSshpass = $true
        } else {
            # No plink or sshpass — we need to use a different approach.
            # GL.iNet stock firmware actually has a web API we can use to
            # upload firmware via HTTP. Let's try that.
            Write-Host "       No plink/sshpass. Falling back to GL.iNet web API upload." -ForegroundColor Yellow
            $useWebApi = $true
        }
    }
} else {
    Write-Host " OK (passwordless)" -ForegroundColor Green
    $usePasswordless = $true
}

# ---- Step 3: Upload firmware -------------------------------------------------

Write-Host "[3/5] Uploading firmware to router:/tmp/ ..." -ForegroundColor Yellow

$remotePath = '/tmp/gl-ar300m-universal-sysupgrade.bin'

if ($useWebApi) {
    # GL.iNet v4.x has an API endpoint for firmware upload
    # POST to http://192.168.8.1/api/firmware/upload with the file
    # But this is complex and version-dependent. Let's try a different approach:
    # Use the LuCI sysupgrade API instead.

    Write-Host "       Attempting LuCI sysupgrade API..." -ForegroundColor Gray

    # First, get a session token
    try {
        $loginBody = @{ username = 'root'; password = $RouterPass }
        $resp = Invoke-RestMethod -Uri "http://$RouterIP/cgi-bin/luci/rpc/auth" -Method Post -Body ($loginBody | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec 10
        $token = $resp.result
        Write-Host "       LuCI auth token acquired." -ForegroundColor Gray
    } catch {
        Write-Host "       LuCI RPC failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "MANUAL FALLBACK — run these commands yourself:" -ForegroundColor Cyan
        Write-Host "  1. Open a terminal and run:" -ForegroundColor White
        Write-Host "     scp -O `"$FirmwarePath`" root@${RouterIP}:/tmp/" -ForegroundColor White
        Write-Host "     (password: $RouterPass)" -ForegroundColor Gray
        Write-Host "  2. Then run:" -ForegroundColor White
        Write-Host "     ssh root@${RouterIP}" -ForegroundColor White
        Write-Host "     (password: $RouterPass)" -ForegroundColor Gray
        Write-Host "  3. At the router shell, run:" -ForegroundColor White
        Write-Host "     sysupgrade -n -F /tmp/gl-ar300m-universal-sysupgrade.bin" -ForegroundColor White
        Write-Host ""
        Write-Host "Then wait ~3 min for the 'Pineapple' SSID to appear." -ForegroundColor Yellow
        Write-Host "Browse to http://172.16.42.1:1471/ once connected." -ForegroundColor Yellow
        return
    }

    # Upload via LuCI sysupgrade
    # This is getting complex — fall back to manual instructions
    Write-Host "       LuCI API path not fully implemented." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "MANUAL FALLBACK — run these commands yourself:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Step A — upload firmware (in a NEW PowerShell window):" -ForegroundColor White
    Write-Host "    scp -O `"$FirmwarePath`" root@${RouterIP}:/tmp/" -ForegroundColor Green
    Write-Host "    (when prompted, password: $RouterPass)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Step B — SSH in and flash:" -ForegroundColor White
    Write-Host "    ssh root@${RouterIP}" -ForegroundColor Green
    Write-Host "    (when prompted, password: $RouterPass)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Step C — at the router shell:" -ForegroundColor White
    Write-Host "    sysupgrade -n -F /tmp/gl-ar300m-universal-sysupgrade.bin" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Step D — wait ~3 min for 'Pineapple' SSID, then browse to:" -ForegroundColor White
    Write-Host "    http://172.16.42.1:1471/" -ForegroundColor Green
    Write-Host ""
    return
}

if ($usePlink) {
    # Use plink for SCP
    $scpTool = Get-Command pscp -ErrorAction SilentlyContinue
    if (-not $scpTool) { $scpTool = Get-Command scp -ErrorAction SilentlyContinue }
    & pscp -batch -pw $RouterPass $FirmwarePath "${RouterUser}@${RouterIP}:$remotePath"
    if ($LASTEXITCODE -ne 0) { throw "pscp failed with exit code $LASTEXITCODE" }
    Write-Host "       Uploaded via pscp." -ForegroundColor Green
} elseif ($useSshpass) {
    & sshpass -p $RouterPass scp -o StrictHostKeyChecking=no $FirmwarePath "${RouterUser}@${RouterIP}:$remotePath"
    if ($LASTEXITCODE -ne 0) { throw "scp failed with exit code $LASTEXITCODE" }
    Write-Host "       Uploaded via sshpass+scp." -ForegroundColor Green
} elseif ($usePasswordless) {
    & scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL $FirmwarePath "${RouterUser}@${RouterIP}:$remotePath"
    if ($LASTEXITCODE -ne 0) { throw "scp failed with exit code $LASTEXITCODE" }
    Write-Host "       Uploaded via scp." -ForegroundColor Green
}

# ---- Step 4: Flash via sysupgrade --------------------------------------------

Write-Host "[4/5] Flashing Pineapple firmware (sysupgrade -n -F) ..." -ForegroundColor Yellow
Write-Host "       This will reboot the router. Do NOT unplug power." -ForegroundColor Red

if ($usePlink) {
    & plink -batch -pw $RouterPass "${RouterUser}@${RouterIP}" "sysupgrade -n -F $remotePath"
} elseif ($useSshpass) {
    & sshpass -p $RouterPass ssh -o StrictHostKeyChecking=no "${RouterUser}@${RouterIP}" "sysupgrade -n -F $remotePath"
} elseif ($usePasswordless) {
    & ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "${RouterUser}@${RouterIP}" "sysupgrade -n -F $remotePath"
}

Write-Host "       Flash command sent. Router is rebooting..." -ForegroundColor Green

# ---- Step 5: Wait and probe for Pineapple panel ------------------------------

Write-Host "[5/5] Waiting for Pineapple to boot (~3 min) ..." -ForegroundColor Yellow
Write-Host "       Watching for SSID 'Pineapple' and panel at 172.16.42.1:1471" -ForegroundColor Gray

$deadline = (Get-Date).AddMinutes(5)
$found = $false

while ((Get-Date) -lt $deadline -and -not $found) {
    Start-Sleep -Seconds 15
    $elapsed = [math]::Round(((Get-Date) - (Get-Date).AddMinutes(-5)).TotalSeconds - ((Get-Date) - $deadline).TotalSeconds)
    Write-Host "       [$([math]::Round((5 - ($deadline.Subtract((Get-Date)).TotalMinutes)),1)) min left] Checking..." -ForegroundColor Gray

    # Check Wi-Fi scan
    $nets = netsh wlan show networks 2>&1
    if ($nets -match 'Pineapple') {
        Write-Host "       Pineapple SSID detected!" -ForegroundColor Green
        $found = $true
    }

    # Also try ping
    try {
        $r2 = $ping.Send('172.16.42.1', 2000)
        if ($r2.Status -eq 'Success') {
            Write-Host "       172.16.42.1 is responding!" -ForegroundColor Green
            $found = $true
        }
    } catch {}
}

if ($found) {
    Write-Host ""
    Write-Host "SUCCESS! The Pineapple is booting." -ForegroundColor Green
    Write-Host "  1. Join the 'Pineapple' Wi-Fi network (open, no password)" -ForegroundColor White
    Write-Host "  2. Browse to http://172.16.42.1:1471/" -ForegroundColor White
    Write-Host "  3. Default SSH: root / root  (set a real password with 'passwd')" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  - Plug in USB Wi-Fi adapter (RT5370 or RT5572 recommended)" -ForegroundColor White
    Write-Host "  - Plug in USB flash drive for /sd module storage" -ForegroundColor White
    Write-Host "  - Run 'wpc-tools missing_packages' over SSH once online" -ForegroundColor White
    Write-Host "  - Format USB drive: Advanced > USB & Storage > Format SD Card" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Pineapple SSID not detected within 5 minutes." -ForegroundColor Yellow
    Write-Host "The router may still be booting. Check manually:" -ForegroundColor White
    Write-Host "  netsh wlan show networks" -ForegroundColor Gray
    Write-Host "  (look for 'Pineapple' SSID)" -ForegroundColor Gray
    Write-Host "  ping 172.16.42.1" -ForegroundColor Gray
    Write-Host "  http://172.16.42.1:1471/" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan