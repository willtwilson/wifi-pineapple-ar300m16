<#
.SYNOPSIS
    Downloads the two firmware images required to convert a GL.iNet GL-AR300M16
    into a WiFi Pineapple clone.

.DESCRIPTION
    Phase 1 - OpenWrt 19.07.7 sysupgrade for glinet_gl-ar300m-lite
    Phase 2 - Wifi Pineapple Cloner v4 "universal" sysupgrade (TETRA emulation)

    Both files are SHA-256 verified after download.

.NOTES
    Run from any directory. Files are placed in ./firmware/ relative to the
    script location. Re-runnable; existing files with valid hashes are skipped.
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $here 'firmware'
if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

# name / url / expected sha256
$artifacts = @(
    [pscustomobject]@{
        Name     = 'openwrt-19.07.7-ath79-generic-glinet_gl-ar300m-lite-squashfs-sysupgrade.bin'
        Url      = 'https://archive.openwrt.org/releases/19.07.7/targets/ath79/generic/openwrt-19.07.7-ath79-generic-glinet_gl-ar300m-lite-squashfs-sysupgrade.bin'
        Expected = 'DB20F1DAC46E4D15E919B97D2C5F0AA18F2BB340BFCC6CFC4B645209440B9745'
    },
    [pscustomobject]@{
        Name     = 'glinet_gl-ar300m-lite-universal-sysupgrade.bin'
        Url      = 'https://gitlab.com/xchwarze/wifi-pineapple-cloner-builds/-/raw/main/releases/glinet_gl-ar300m-lite-universal-sysupgrade.bin'
        Expected = $null  # GitLab raw endpoint doesn't publish a checksum; we just download.
    }
)

function Test-FileHash {
    param([string]$Path, [string]$Expected)
    if (-not $Expected) { return $null }
    $actual = (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    return $actual -eq $Expected.ToUpper()
}

foreach ($a in $artifacts) {
    $target = Join-Path $dest $a.Name

    if ((-not $Force) -and (Test-Path -LiteralPath $target)) {
        if ($a.Expected) {
            $ok = Test-FileHash -Path $target -Expected $a.Expected
            if ($ok) {
                Write-Host "[$($a.Name)] already present and verified - skipping." -ForegroundColor Green
                continue
            } else {
                Write-Warning "[$($a.Name)] exists but hash mismatch - re-downloading."
            }
        } else {
            Write-Host "[$($a.Name)] already present (no checksum to verify) - skipping. Use -Force to re-download." -ForegroundColor Yellow
            continue
        }
    }

    Write-Host "Downloading $($a.Name) ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $a.Url -OutFile $target -UseBasicParsing
    } catch {
        throw "Download failed for $($a.Name): $($_.Exception.Message)"
    }

    if ($a.Expected) {
        $ok = Test-FileHash -Path $target -Expected $a.Expected
        if ($ok) {
            Write-Host "[$($a.Name)] verified." -ForegroundColor Green
        } else {
            $actual = (Get-FileHash -Algorithm SHA256 -Path $target).Hash
            throw "Hash mismatch for $($a.Name)`nExpected: $($a.Expected)`nActual:   $actual"
        }
    } else {
        Write-Host "[$($a.Name)] downloaded (no upstream checksum - verify manually if needed)." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Firmware staged in: $dest" -ForegroundColor Green
Write-Host "Next: flash OpenWrt 19.07.7 first, then the WPC universal image (do NOT keep settings)." -ForegroundColor Cyan