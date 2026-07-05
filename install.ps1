param(
    [string]$InstallDir = "C:\Programs\Caps",
    [switch]$SkipBuild,
    [switch]$Launch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Copy-ChangedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Missing required install file: $Source"
    }

    $destinationDir = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null

    $sourceHash = Get-FileSha256 -Path $Source
    $destinationHash = Get-FileSha256 -Path $Destination

    if ($sourceHash -eq $destinationHash) {
        Write-Host "Unchanged $([System.IO.Path]::GetFileName($Source))"
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Updated $([System.IO.Path]::GetFileName($Source))"
}

$sourceRoot = $PSScriptRoot
$installRoot = [System.IO.Path]::GetFullPath($InstallDir)
$targetExePath = Join-Path $installRoot "caps.exe"

if (-not $SkipBuild) {
    & (Join-Path $sourceRoot "make.ps1")
    if (-not $?) {
        throw "Build failed."
    }
}

$releaseFiles = @(
    "caps.exe",
    "CREDITS.md",
    "LICENSE",
    "README.md",
    "INSTALL.md",
    "config.ini",
    "keyboard-map-tks.svg"
)

$runningInstalledCaps = Get-Process -Name "caps" -ErrorAction SilentlyContinue | Where-Object {
    try {
        [System.IO.Path]::GetFullPath($_.Path) -eq $targetExePath
    }
    catch {
        $false
    }
}

if ($runningInstalledCaps) {
    Write-Host "Stopping installed caps.exe from $targetExePath"
    $runningInstalledCaps | Stop-Process -Force
    $runningInstalledCaps | Wait-Process -Timeout 5
}

foreach ($file in $releaseFiles) {
    Copy-ChangedFile -Source (Join-Path $sourceRoot $file) -Destination (Join-Path $installRoot $file)
}

if ($Launch) {
    Start-Process -FilePath $targetExePath -WorkingDirectory $installRoot
}

Write-Host "Installed Caps to $installRoot"
