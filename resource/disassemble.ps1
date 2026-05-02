<#
.SYNOPSIS
    Disassembles the generated keyboard map SVG back into CSV map files.

.DESCRIPTION
    This script reads the generated 'keyboard-map-tks.svg' file and writes the reverse-map CSVs:
    'map_keys_reversed.csv', 'map_caps_reversed.csv', and 'map_icons_reversed.csv'.
    The output schema matches the CSV files consumed by 'assemble.ps1'.

.PARAMETER NoBackup
    Overwrites existing output CSV files without first renaming them to backup files.

.NOTES
    - This script requires 'keyboard-map-tks.svg' to be present in the same directory.
    - Running this script will rename existing output CSV files to '*.bkp.csv' before
      writing new map files, unless -NoBackup is specified. If a backup file already
      exists, a numeric suffix is added and incremented.
    - If 'map_keys.csv' exists, its row count is used to split key labels from caps labels.
#>

param(
    [switch] $NoBackup
)

# --- Configuration ---
$sourceSvgPath = Join-Path $PSScriptRoot "keyboard-map-tks.svg"
$keyMapPath = Join-Path $PSScriptRoot "map_keys.csv"
$keyMapOutputPath = Join-Path $PSScriptRoot "map_keys.csv"
$capsMapOutputPath = Join-Path $PSScriptRoot "map_caps.csv"
$iconMapOutputPath = Join-Path $PSScriptRoot "map_icons.csv"

# --- Main Logic ---
try {
    $sourceSvgPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($sourceSvgPath)
    $keyMapPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($keyMapPath)
    $keyMapOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($keyMapOutputPath)
    $capsMapOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($capsMapOutputPath)
    $iconMapOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconMapOutputPath)

    if (-not (Test-Path $sourceSvgPath)) {
        throw "Source SVG file not found at: $sourceSvgPath"
    }

    Write-Host "Loading source SVG from: $sourceSvgPath"

    $svgXml = [xml](Get-Content -Path $sourceSvgPath -Raw)

    function ConvertTo-CsvField {
        param(
            [AllowNull()] [string] $Value
        )

        if ($null -eq $Value) {
            return ""
        }

        if ($Value -match '[,"\r\n]') {
            return '"' + ($Value -replace '"', '""') + '"'
        }

        return $Value
    }

    function Write-CsvRows {
        param(
            [Parameter(Mandatory = $true)] [string] $Path,
            [Parameter(Mandatory = $true)] [string[]] $Columns,
            [Parameter(Mandatory = $true)] [object[]] $Rows
        )

        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add(($Columns -join ","))

        foreach ($row in $Rows) {
            $fields = foreach ($column in $Columns) {
                ConvertTo-CsvField -Value $row.$column
            }
            $lines.Add(($fields -join ","))
        }

        $content = $lines -join [Environment]::NewLine
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($Path, $content, $utf8NoBom)
    }

    function Get-BackupCsvPath {
        param(
            [Parameter(Mandatory = $true)] [string] $Path
        )

        $directory = [System.IO.Path]::GetDirectoryName($Path)
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $backupPattern = [regex]::Escape($fileNameWithoutExtension) + '\.bkp(?<Number>\d*)\.csv$'
        $highestBackupNumber = -1
        Get-ChildItem -LiteralPath $directory -File -Filter "$fileNameWithoutExtension.bkp*.csv" |
            ForEach-Object {
                $match = [regex]::Match($_.Name, $backupPattern)
                if ($match.Success) {
                    $backupNumber = 0
                    if (-not [string]::IsNullOrEmpty($match.Groups["Number"].Value)) {
                        $backupNumber = [int] $match.Groups["Number"].Value
                    }
                    if ($backupNumber -gt $highestBackupNumber) {
                        $highestBackupNumber = $backupNumber
                    }
                }
            }

        if ($highestBackupNumber -lt 0) {
            return (Join-Path $directory "$fileNameWithoutExtension.bkp.csv")
        }

        $nextBackupNumber = $highestBackupNumber + 1
        Join-Path $directory "$fileNameWithoutExtension.bkp$nextBackupNumber.csv"
    }

    function Backup-ExistingCsvFiles {
        param(
            [Parameter(Mandatory = $true)] [string[]] $Paths
        )

        $existingPaths = @($Paths | Select-Object -Unique | Where-Object { Test-Path -LiteralPath $_ })

        foreach ($path in $existingPaths) {
            $backupPath = Get-BackupCsvPath -Path $path
            Move-Item -LiteralPath $path -Destination $backupPath -Force -ErrorAction Stop
            Write-Host "Renamed existing CSV to backup: $backupPath"
        }
    }

    function Convert-TextNodeToRow {
        param(
            [Parameter(Mandatory = $true)] [System.Xml.XmlElement] $Node
        )

        [PSCustomObject]@{
            Text       = $Node.InnerText
            X          = $Node.GetAttribute("x")
            Y          = $Node.GetAttribute("y")
            Fill       = $Node.GetAttribute("fill")
            Stroke     = $Node.GetAttribute("stroke")
            FontSize   = $Node.GetAttribute("font-size")
            FontFamily = $Node.GetAttribute("font-family")
            TextAnchor = $Node.GetAttribute("text-anchor")
        }
    }

    function Convert-IconNodeToRow {
        param(
            [Parameter(Mandatory = $true)] [System.Xml.XmlElement] $Node
        )

        $id = $Node.GetAttribute("id")
        $name = $id
        if ($name.StartsWith("icon-")) {
            $name = $name.Substring("icon-".Length)
        }

        [PSCustomObject]@{
            Name   = $name
            Icon   = $name
            X      = $Node.GetAttribute("x")
            Y      = $Node.GetAttribute("y")
            Width  = $Node.GetAttribute("width")
            Height = $Node.GetAttribute("height")
        }
    }

    $textNodes = @($svgXml.SelectNodes("//*[local-name()='text']"))
    $iconNodes = @($svgXml.SelectNodes("//*[local-name()='svg' and starts-with(@id, 'icon-')]"))

    if (Test-Path $keyMapPath) {
        $keyCount = @(Import-Csv -Path $keyMapPath).Count
    }
    else {
        $keyCount = @($textNodes | Where-Object { $_.GetAttribute("fill") -eq "#999999" }).Count
        Write-Warning "map_keys.csv not found. Splitting text rows by the count of #999999 labels."
    }

    if ($keyCount -gt $textNodes.Count) {
        throw "Key map split count ($keyCount) is greater than text node count ($($textNodes.Count))."
    }

    $textRows = @($textNodes | ForEach-Object { Convert-TextNodeToRow -Node $_ })
    $keyRows = @($textRows | Select-Object -First $keyCount)
    $capsRows = @($textRows | Select-Object -Skip $keyCount)
    $iconRows = @($iconNodes | ForEach-Object { Convert-IconNodeToRow -Node $_ })

    $textColumns = @("Text", "X", "Y", "Fill", "Stroke", "FontSize", "FontFamily", "TextAnchor")
    $iconColumns = @("Name", "Icon", "X", "Y", "Width", "Height")

    if ($NoBackup) {
        Write-Host "Skipping backup of existing CSV files because -NoBackup was specified."
    }
    else {
        Backup-ExistingCsvFiles -Paths @($keyMapOutputPath, $capsMapOutputPath, $iconMapOutputPath)
    }

    Write-CsvRows -Path $keyMapOutputPath -Columns $textColumns -Rows $keyRows
    Write-Host "Successfully created key map data file: $keyMapOutputPath"

    Write-CsvRows -Path $capsMapOutputPath -Columns $textColumns -Rows $capsRows
    Write-Host "Successfully created caps map data file: $capsMapOutputPath"

    Write-CsvRows -Path $iconMapOutputPath -Columns $iconColumns -Rows $iconRows
    Write-Host "Successfully created icon map data file: $iconMapOutputPath"

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
