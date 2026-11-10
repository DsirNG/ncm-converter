#requires -Version 5.1
<#
.SYNOPSIS
Read-only diagnostics for the v0.2.0-rc.1 Windows installer.
.DESCRIPTION
Checks file presence, SHA-256, Authenticode status, browser download remnants,
and recent Microsoft Defender detections. Does not change security settings.
#>
[CmdletBinding()]
param(
    [string]$InstallerPath = (Join-Path $env:USERPROFILE 'Downloads\NCM-Converter-0.2.0-rc.1-Windows-x64-Setup.exe'),
    [string]$ExpectedSha256 = '2f5ee91f682bc621c368e04f53dc9965809fa9d756d46940670b39d5b43b1cd5'
)

Write-Host '=== NCM Converter Windows installer diagnostics ==='
Write-Host "Installer path: $InstallerPath"
Write-Host ''

if (Test-Path -LiteralPath $InstallerPath -PathType Leaf) {
    $installer = Get-Item -LiteralPath $InstallerPath
    Write-Host "File exists: $($installer.Length) bytes"
    try {
        $actual = (Get-FileHash -LiteralPath $InstallerPath -Algorithm SHA256 -ErrorAction Stop).Hash
        Write-Host "SHA-256: $actual"
        if ($ExpectedSha256) {
            if ($actual -ieq $ExpectedSha256) {
                Write-Host 'SHA-256 matches the expected release checksum.'
            } else {
                Write-Warning 'SHA-256 mismatch. Do not run this file; check its origin.'
            }
        }
    } catch {
        Write-Warning "Could not hash the file: $($_.Exception.Message)"
    }
    try {
        $signature = Get-AuthenticodeSignature -FilePath $installer.FullName -ErrorAction Stop
        Write-Host "Authenticode status: $($signature.Status)"
        if ($signature.SignerCertificate) {
            Write-Host "Signer: $($signature.SignerCertificate.Subject)"
        }
    } catch {
        Write-Warning "Could not check the signature: $($_.Exception.Message)"
    }
    try {
        $zone = Get-Content -LiteralPath $installer.FullName -Stream Zone.Identifier -ErrorAction Stop
        Write-Host 'Download security zone information:'
        $zone | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host 'No readable Zone.Identifier stream (this is not a security verdict).'
    }
} else {
    Write-Warning 'The installer is not present at this path. A Chrome "Deleted" entry alone does not reveal what deleted it.'
}

$downloadDir = Join-Path $env:USERPROFILE 'Downloads'
if (Test-Path -LiteralPath $downloadDir) {
    $partials = @(Get-ChildItem -LiteralPath $downloadDir -Filter '*.crdownload' -File -ErrorAction SilentlyContinue)
    if ($partials.Count -gt 0) {
        Write-Host ''
        Write-Host 'Incomplete Chrome downloads:'
        $partials | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize
    }
}

Write-Host ''
Write-Host '=== Microsoft Defender detections during the past 7 days ==='
if (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue) {
    try {
        $cutoff = (Get-Date).AddDays(-7)
        $detections = @(Get-MpThreatDetection -ErrorAction Stop | Where-Object {
            $_.InitialDetectionTime -and $_.InitialDetectionTime -ge $cutoff
        })
        if ($detections.Count -eq 0) {
            Write-Host 'No recent detections returned. This does not rule out Chrome, SmartScreen, or third-party AV.'
        } else {
            $detections | Select-Object InitialDetectionTime,ThreatID,Resources,ActionSuccess | Format-List
        }
    } catch {
        Write-Warning "Could not read Defender detections: $($_.Exception.Message)"
    }
} else {
    Write-Host 'Defender cmdlet unavailable (possibly managed or using another antivirus product).'
}

Write-Host ''
Write-Host 'Next: Windows Security > Virus & threat protection > Protection history.'
Write-Host 'Chrome: Ctrl+J for download status; chrome://policy for managed download restrictions.'
Write-Host 'Do not disable antivirus or restore blocked files before determining the detection reason.'
