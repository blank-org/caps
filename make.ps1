$versionEnvPath = Join-Path $PSScriptRoot "build\version.env"
$versionInfoPath = Join-Path $PSScriptRoot "build\version-info.ahk"
$outputExePath = Join-Path $PSScriptRoot "caps.exe"
$ahk2ExePath = Join-Path $env:LocalAppData "Programs\AutoHotKey\Compiler\Ahk2Exe.exe"

New-Item -ItemType Directory -Path (Split-Path $versionInfoPath) -Force | Out-Null

$version = @{}
Get-Content $versionEnvPath | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
        $version[$Matches[1]] = $Matches[2]
    }
}

$productVersion = $version["PRODUCT_VERSION"]
$fileVersion = $version["FILE_VERSION"]
$publisher = $version["PUBLISHER"]

if (-not $productVersion -or -not $fileVersion) {
    Write-Error "Missing PRODUCT_VERSION or FILE_VERSION in $versionEnvPath."
    exit 1
}

function Set-VersionInfoStringValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $keyBytes = [System.Text.Encoding]::Unicode.GetBytes($Key)

    for ($i = 0; $i -le $bytes.Length - $keyBytes.Length; $i++) {
        $matched = $true
        for ($j = 0; $j -lt $keyBytes.Length; $j++) {
            if ($bytes[$i + $j] -ne $keyBytes[$j]) {
                $matched = $false
                break
            }
        }

        if (-not $matched -or $i -lt 6) {
            continue
        }

        $entryOffset = $i - 6
        $entryLength = [BitConverter]::ToUInt16($bytes, $entryOffset)
        $valueLength = [BitConverter]::ToUInt16($bytes, $entryOffset + 2)
        $entryType = [BitConverter]::ToUInt16($bytes, $entryOffset + 4)

        if ($entryType -ne 1 -or $entryLength -le 0 -or $valueLength -le 0) {
            continue
        }

        $keyLengthBytes = ($Key.Length + 1) * 2
        $valueOffset = $entryOffset + (4 * [Math]::Ceiling((6 + $keyLengthBytes) / 4))
        $valueSizeBytes = $valueLength * 2

        if ($valueOffset + $valueSizeBytes -gt $entryOffset + $entryLength) {
            continue
        }

        if ($Value.Length + 1 -gt $valueLength) {
            throw "$Key '$Value' is longer than the compiled version resource slot."
        }

        [Array]::Clear($bytes, $valueOffset, $valueSizeBytes)
        $valueBytes = [System.Text.Encoding]::Unicode.GetBytes($Value + [char]0)
        [Array]::Copy($valueBytes, 0, $bytes, $valueOffset, $valueBytes.Length)
        try {
            [System.IO.File]::WriteAllBytes($Path, $bytes)
        }
        catch {
            throw "Unable to write $Path. Stop any running copy of caps.exe and try again. $($_.Exception.Message)"
        }
        return
    }

    throw "Unable to find $Key in $Path."
}

$runningCaps = Get-Process -Name "caps" -ErrorAction SilentlyContinue | Where-Object {
    try {
        $_.Path -eq $outputExePath
    }
    catch {
        $false
    }
}

if ($runningCaps) {
    $runningCaps | Stop-Process -Force
    $runningCaps | Wait-Process -Timeout 5
}

$year = (Get-Date).Year
$copyrightSymbol = [char]0x00A9
$copyright = "$year $copyrightSymbol $publisher"
@(
    ";@Ahk2Exe-SetDescription Caps - shortcuts executioner"
    ";@Ahk2Exe-SetProductVersion $productVersion"
    ";@Ahk2Exe-SetProductName Caps - keyboard shortcuts"
    ";@Ahk2Exe-SetFileVersion $fileVersion"
    ";@Ahk2Exe-SetCopyright $copyright"
) | Set-Content -Path $versionInfoPath -Encoding utf8BOM

if (-not (Test-Path -LiteralPath $ahk2ExePath)) {
    Write-Error "Unable to find Ahk2Exe at $ahk2ExePath."
    exit 1
}

& $ahk2ExePath /in caps.ahk /out $outputExePath /icon Resource/Icon/Keyboard.ico
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $outputExePath)) {
    Write-Error "Ahk2Exe completed but did not create $outputExePath."
    exit 1
}

Set-VersionInfoStringValue -Path $outputExePath -Key "ProductVersion" -Value $productVersion
Set-VersionInfoStringValue -Path $outputExePath -Key "LegalCopyright" -Value $copyright
