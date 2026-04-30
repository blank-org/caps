$githubToken = $env:GITHUB_TOKEN_BLANK
if (-not $githubToken) {
    Write-Error "GITHUB_TOKEN environment variable not set."
    exit 1
}

$versionEnvPath = Join-Path $PSScriptRoot "build\version.env"
$versionLine = Get-Content $versionEnvPath | Where-Object { $_ -match '^\s*FILE_VERSION\s*=\s*([\d\.]+)\s*$' } | Select-Object -First 1
if ($versionLine -match '^\s*FILE_VERSION\s*=\s*([\d\.]+)\s*$') {
    $fullVersion = $Matches[1]
    if ($fullVersion -match '^\d+(?:\.\d+){2,3}$') {
        $version = $fullVersion
    }
    else {
        Write-Error "Failed to parse version (major.minor.patch[.build]) from $fullVersion"
        exit 1
    }
}
else {
    Write-Error "FILE_VERSION not found in $versionEnvPath"
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

& "$PSScriptRoot\make.ps1"

Compress-Archive -LiteralPath caps.exe, CREDITS.md, LICENSE, README.md, Install.md, config.ini, Resource/Keyboard-map-TKS.svg -DestinationPath $zipName

# tag with version, then create a release and upload the zip
git tag -a "v$version" -m "Release version $version"
git push origin "v$version"

# Create a GitHub release

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
