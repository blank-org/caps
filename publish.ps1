Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$githubToken = $env:GITHUB_TOKEN_BLANK
if (-not $githubToken) {
    Write-Error "GITHUB_TOKEN environment variable not set."
    exit 1
}

$versionEnvPath = Join-Path $PSScriptRoot "build\version.env"
$version = @{}
Get-Content $versionEnvPath | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
        $version[$Matches[1]] = $Matches[2]
    }
}

$fileVersion = $version["FILE_VERSION"]
if ($fileVersion) {
    if ($fileVersion -match '^\d+(?:\.\d+){2,3}(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$') {
        $version = $fileVersion
    }
    else {
        Write-Error "Failed to parse version (major.minor.patch[.build][-prerelease][+metadata]) from $fileVersion"
        exit 1
    }
}
else {
    Write-Error "FILE_VERSION not found in $versionEnvPath"
    exit 1
}

$zipName = "caps-$version.zip"
$zipPath = Join-Path $PSScriptRoot $zipName
$tagName = "v$version"

git rev-parse --verify --quiet "refs/tags/$tagName" | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Error "Tag $tagName already exists locally. Bump FILE_VERSION in $versionEnvPath before publishing."
    exit 1
}

$remoteTag = git ls-remote --exit-code --tags origin "refs/tags/$tagName" 2>$null
if ($LASTEXITCODE -eq 0 -or $remoteTag) {
    Write-Error "Tag $tagName already exists on origin. Bump FILE_VERSION in $versionEnvPath before publishing."
    exit 1
}
elseif ($LASTEXITCODE -ne 2) {
    Write-Error "Unable to check whether tag $tagName exists on origin."
    exit 1
}

$archiveDir = Join-Path $PSScriptRoot "archive"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

# Move earlier zip files to archive dir if exist
Get-ChildItem -Path $PSScriptRoot -Filter *.zip | ForEach-Object {
    Move-Item $_.FullName "$archiveDir\$($_.Name)" -Force
}

$exePath = Join-Path $PSScriptRoot "caps.exe"
if (Test-Path -LiteralPath $exePath -PathType Leaf) {
    Add-Type -AssemblyName Microsoft.VisualBasic

    do {
        try {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $exePath,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )

            while (Test-Path -LiteralPath $exePath -PathType Leaf) {
                Start-Sleep -Milliseconds 250
            }
        }
        catch {
            Write-Error "Failed to move $exePath to the Recycle Bin: $($_.Exception.Message)" -ErrorAction Continue
            $retryDelete = Read-Host "Close anything using caps.exe, then retry deleting it? [y/N]"
            if ($retryDelete -notmatch '(?i)^(?:y|yes)$') {
                exit 1
            }
        }
    }
    while (Test-Path -LiteralPath $exePath -PathType Leaf)
}

& "$PSScriptRoot\make.ps1"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$releaseFiles = @(
    $exePath
    (Join-Path $PSScriptRoot "CREDITS.md")
    (Join-Path $PSScriptRoot "LICENSE")
    (Join-Path $PSScriptRoot "README.md")
    (Join-Path $PSScriptRoot "Install.md")
    (Join-Path $PSScriptRoot "config.ini")
    (Join-Path $PSScriptRoot "Resource\Keyboard-map-TKS.svg")
)

$missingFiles = $releaseFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }
if ($missingFiles) {
    Write-Error "Cannot create $zipName because required release file(s) are missing: $($missingFiles -join ', ')"
    exit 1
}

Compress-Archive -LiteralPath $releaseFiles -DestinationPath $zipPath

# tag with version, then create a release and upload the zip
git tag -a $tagName -m "Release version $version"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

git push origin $tagName
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# Create a GitHub release

$releaseUrl = "https://api.github.com/repos/blank-org/caps/releases"
$releaseBody = @{
    tag_name    = $tagName
    name        = "Release $tagName"
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
} -InFile $zipPath
