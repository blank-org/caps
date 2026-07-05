Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$logPath = Join-Path $PSScriptRoot "publish.log"
$script:transcriptStarted = $false

trap {
    $failure = $_ | Out-String
    if ($script:transcriptStarted) {
        Stop-Transcript | Out-Null
        $script:transcriptStarted = $false
    }

    Add-Content -Path $logPath -Value @(
        ""
        "Publish failed at $(Get-Date -Format o)"
        $failure.TrimEnd()
    )

    [Console]::Error.WriteLine("Publish failed. See $logPath for details.")
    [Console]::Error.WriteLine($failure.TrimEnd())

    exit 1
}

Start-Transcript -Path $logPath -Append | Out-Null
$script:transcriptStarted = $true

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [int[]]$AllowedExitCodes = @(0),
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE
    if ($AllowedExitCodes -notcontains $exitCode) {
        throw "$FailureMessage Exit code: $exitCode."
    }
}

$githubToken = $env:GITHUB_TOKEN
if (-not $githubToken) {
    $githubToken = $env:GITHUB_TOKEN_BLANK
}
if (-not $githubToken) {
    throw "GITHUB_TOKEN environment variable not set."
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
        throw "Failed to parse version (major.minor.patch[.build][-prerelease][+metadata]) from $fileVersion"
    }
}
else {
    throw "FILE_VERSION not found in $versionEnvPath"
}

$zipName = "caps-$version.zip"
$zipPath = Join-Path $PSScriptRoot $zipName
$tagName = "v$version"

& git rev-parse --verify --quiet "refs/tags/$tagName" | Out-Null
$localTagExitCode = $LASTEXITCODE
if ($localTagExitCode -eq 0) {
    throw "Tag $tagName already exists locally. Bump FILE_VERSION in $versionEnvPath before publishing."
}
elseif ($localTagExitCode -ne 1) {
    throw "Unable to check whether tag $tagName exists locally. Exit code: $localTagExitCode."
}

$remoteTagOutput = & git ls-remote --exit-code --tags origin "refs/tags/$tagName" 2>&1
$remoteTagExitCode = $LASTEXITCODE
if ($remoteTagExitCode -eq 0) {
    throw "Tag $tagName already exists on origin. Bump FILE_VERSION in $versionEnvPath before publishing."
}
elseif ($remoteTagExitCode -ne 2) {
    throw "Unable to check whether tag $tagName exists on origin. Exit code: $remoteTagExitCode. Output: $remoteTagOutput"
}

$archiveDir = Join-Path $PSScriptRoot "archive"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

# Move earlier zip files to archive dir if exist
Get-ChildItem -Path $PSScriptRoot -Filter *.zip | ForEach-Object {
    Move-Item $_.FullName "$archiveDir\$($_.Name)" -Force
}

& "$PSScriptRoot\make.ps1"
$buildSucceeded = $?
$buildExitCode = $LASTEXITCODE
if (-not $buildSucceeded) {
    throw "Build failed. Exit code: $buildExitCode."
}

$exePath = Join-Path $PSScriptRoot "caps.exe"
$releaseFiles = @(
    $exePath
    (Join-Path $PSScriptRoot "CREDITS.md")
    (Join-Path $PSScriptRoot "LICENSE")
    (Join-Path $PSScriptRoot "README.md")
    (Join-Path $PSScriptRoot "Install.md")
    (Join-Path $PSScriptRoot "config.ini")
    (Join-Path $PSScriptRoot "keyboard-map-tks.svg")
)

$missingFiles = $releaseFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }
if ($missingFiles) {
    throw "Cannot create $zipName because required release file(s) are missing: $($missingFiles -join ', ')"
}

Compress-Archive -LiteralPath $releaseFiles -DestinationPath $zipPath

# tag with version, then create a release and upload the zip
Invoke-NativeCommand -FilePath "git" -ArgumentList @("tag", "-a", $tagName, "-m", "Release version $version") -FailureMessage "Failed to create git tag $tagName."

Invoke-NativeCommand -FilePath "git" -ArgumentList @("push", "origin", $tagName) -FailureMessage "Failed to push git tag $tagName."

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

Write-Host "Published $tagName and uploaded $zipName."
Stop-Transcript | Out-Null
$script:transcriptStarted = $false
