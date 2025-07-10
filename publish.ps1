# Extract version from caps.ahk
$versionLine = Get-Content caps.ahk | Where-Object { $_ -match '^;@Ahk2Exe-SetFileVersion\s+([\d\.]+)' }
if ($versionLine -match '^;@Ahk2Exe-SetFileVersion\s+([\d\.]+)') {
    # Extract only the first three numbers (e.g., 1.2.3 from 1.2.3.4)
    $fullVersion = $Matches[1]
    if ($fullVersion -match '^(\d+\.\d+\.\d+)') {
        $version = $Matches[1]
    } else {
        Write-Error "Failed to parse version (major.minor.patch) from $fullVersion"
        exit 1
    }
}
else {
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

# tag with version, then create a release and upload the zip
git tag -a "v$version" -m "Release version $version"
git push origin "v$version"

# Create a GitHub release
$githubToken = $env:GITHUB_TOKEN_BLANK
if (-not $githubToken) {
    Write-Error "GITHUB_TOKEN environment variable not set."
    exit 1
}
$releaseUrl = "https://api.github.com/repos/blank-org/caps/releases"
$releaseBody = @{
    tag_name    = "v$version"
    name        = "Release v$version"
    body        = "Release of Caps version $version"
    draft       = $false
    prerelease  = $false
} | ConvertTo-Json

$headers = @{
    Authorization = "token $githubToken"
    "User-Agent"  = "PowerShell"
    Accept        = "application/vnd.github+json"
}

$releaseResponse = Invoke-RestMethod -Uri $releaseUrl -Method Post -Headers $headers -Body $releaseBody -ContentType "application/json"

# Upload the zip file as a release asset
$uploadUrl = $releaseResponse.upload_url -replace "\{.*\}", "?name=$zipName"
Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers @{
    Authorization = "token $githubToken"
    "User-Agent"  = "PowerShell"
    "Content-Type" = "application/zip"
} -InFile $zipName
