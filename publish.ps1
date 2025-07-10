# Extract version from caps.ahk
$versionLine = Get-Content caps.ahk | Where-Object { $_ -match '^;@Ahk2Exe-SetFileVersion\s+([\d\.]+)' }
if ($versionLine -match '^;@Ahk2Exe-SetFileVersion\s+([\d\.]+)') {
    $version = $Matches[1]
} else {
    Write-Error "Version not found in caps.ahk"
    exit 1
}

$zipName = "caps-$version.zip"
$archiveDir = "archive"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

# Move earlier zip files to archive dir if exist
Get-ChildItem -Path . -Filter *.zip | ForEach-Object {
    Move-Item $_.FullName "$archiveDir\$($_.Name)" -Force
}

& $env:LocalAppData\Programs\AutoHotKey\Compiler\Ahk2Exe.exe /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico

Compress-Archive -LiteralPath caps.exe, CREDITS.md, LICENSE, README.md, Install.md, config.ini, Resource/Keyboard-map-TKS.svg -DestinationPath $zipName
