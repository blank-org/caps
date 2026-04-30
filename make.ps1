$versionEnvPath = Join-Path $PSScriptRoot "build\version.env"
$versionInfoPath = Join-Path $PSScriptRoot "build\version-info.ahk"

New-Item -ItemType Directory -Path (Split-Path $versionInfoPath) -Force | Out-Null

$version = @{}
Get-Content $versionEnvPath | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
        $version[$Matches[1]] = $Matches[2]
    }
}

$productVersion = $version["PRODUCT_VERSION"]
$fileVersion = $version["FILE_VERSION"]

if (-not $productVersion -or -not $fileVersion) {
    Write-Error "Missing PRODUCT_VERSION or FILE_VERSION in $versionEnvPath."
    exit 1
}

$year = (Get-Date).Year
@(
    ";@Ahk2Exe-SetDescription Caps - shortcuts executioner"
    ";@Ahk2Exe-SetProductVersion $productVersion"
    ";@Ahk2Exe-SetProductName Caps - keyboard shortcuts"
    ";@Ahk2Exe-SetFileVersion $fileVersion"
    ";@Ahk2Exe-SetCopyright $year - Ujjwal Singh @ ujnotes.com"
) | Set-Content -Path $versionInfoPath -Encoding ASCII

& $env:LocalAppData\Programs\AutoHotKey\Compiler\Ahk2Exe.exe /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico
