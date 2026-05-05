<#
.SYNOPSIS
    Assembles a complete SVG file from a base SVG and CSV map files.

.DESCRIPTION
    This script reads a 'base_svg.svg' file, text map CSV files, and an icon map CSV file.
    It parses the CSV data to get the properties for each text label and icon.
    Then, it programmatically creates new SVG elements and injects them into the
    base SVG's XML structure. The final, reconstructed SVG is saved as 'keyboard-map-tks.svg'.

.NOTES
    - This script requires 'base_svg.svg', 'map_keys.csv', 'map_caps.csv', and 'map_icons.csv'
      to be in the same directory.
    - Running this script will create/overwrite 'keyboard-map-tks.svg'.
#>

# --- Configuration ---
$baseSvgPath = Join-Path $PSScriptRoot "base_svg.svg"
$textMapPaths = @(
    (Join-Path $PSScriptRoot "map_keys.csv"),
    (Join-Path $PSScriptRoot "map_caps.csv")
)
$iconMapPath = Join-Path $PSScriptRoot "map_icons.csv"
$iconDirectoryPath = Join-Path $PSScriptRoot "kbd-icons"
$outputSvgPath = Join-Path $PSScriptRoot "../keyboard-map-tks.svg"

# --- Main Logic ---
try {
    # Resolve paths once so PowerShell cmdlets and .NET Save() use the same files.
    $baseSvgPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($baseSvgPath)
    $textMapPaths = @($textMapPaths | ForEach-Object {
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_)
    })
    $iconMapPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconMapPath)
    $iconDirectoryPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconDirectoryPath)
    $outputSvgPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputSvgPath)

    # Check if the required input files exist
    if (-not (Test-Path $baseSvgPath)) { throw "Base SVG file not found at: $baseSvgPath" }
    foreach ($textMapPath in $textMapPaths) {
        if (-not (Test-Path $textMapPath)) { throw "Text map data file not found at: $textMapPath" }
    }
    if (-not (Test-Path $iconMapPath)) { throw "Icon map data file not found at: $iconMapPath" }

    # Load the base SVG as an XML document
    $svgXml = [xml](Get-Content -Path $baseSvgPath -Raw)
    
    # The namespace is important for creating new elements correctly.
    $namespace = $svgXml.DocumentElement.NamespaceURI

    # Find the first <g> element in the document to serve as the parent for our new text nodes.
    # This is a reasonable assumption for many SVGs.
    $parentElement = $svgXml.SelectSingleNode("//*[local-name()='g']")
    if (-not $parentElement) {
        # If no <g> is found, fall back to the root <svg> element.
        $parentElement = $svgXml.DocumentElement
        Write-Warning "Could not find a <g> element. Appending text to the root <svg> element."
    }

    function Assert-CsvColumns {
        param(
            [Parameter(Mandatory = $true)] [string] $Path,
            [Parameter(Mandatory = $true)] [object[]] $Entries,
            [Parameter(Mandatory = $true)] [string[]] $RequiredColumns
        )

        $actualColumns = @($Entries | Select-Object -First 1 | ForEach-Object { $_.PSObject.Properties.Name })
        $missingColumns = $RequiredColumns | Where-Object { $_ -notin $actualColumns }
        if ($missingColumns.Count -gt 0) {
            throw "CSV file '$Path' is missing required column(s): $($missingColumns -join ', ')"
        }
    }

    function Set-AttributeIfPresent {
        param(
            [Parameter(Mandatory = $true)] [System.Xml.XmlElement] $Element,
            [Parameter(Mandatory = $true)] [string] $Name,
            [AllowNull()] [string] $Value
        )

        if (-not [string]::IsNullOrWhiteSpace($Value)) {
            $Element.SetAttribute($Name, $Value)
        }
    }

    function Get-IconName {
        param(
            [Parameter(Mandatory = $true)] [string] $Value
        )

        $iconName = $Value.Trim() -replace '\\', '/'
        if ($iconName.StartsWith("kbd-icons/")) {
            $iconName = $iconName.Substring("kbd-icons/".Length)
        }
        elseif ($iconName.StartsWith("icons/")) {
            $iconName = $iconName.Substring("icons/".Length)
        }
        if ($iconName.EndsWith(".svg")) {
            $iconName = $iconName.Substring(0, $iconName.Length - ".svg".Length)
        }

        return $iconName
    }

    function Get-IconPath {
        param(
            [Parameter(Mandatory = $true)] [string] $IconName
        )

        $iconPath = Join-Path $iconDirectoryPath "$IconName.svg"
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconPath)
    }

    $textEntries = @()
    $requiredTextColumns = @("Text", "X", "Y", "Fill", "Stroke", "FontSize", "FontFamily", "TextAnchor")
    foreach ($textMapPath in $textMapPaths) {
        $entries = @(Import-Csv -Path $textMapPath)
        Assert-CsvColumns -Path $textMapPath -Entries $entries -RequiredColumns $requiredTextColumns
        Write-Host "Reading $($entries.Count) text entries from $textMapPath."
        $textEntries += $entries
    }

    $iconEntries = @(Import-Csv -Path $iconMapPath)
    $requiredIconColumns = @("Name", "Icon", "X", "Y", "Width", "Height")
    Assert-CsvColumns -Path $iconMapPath -Entries $iconEntries -RequiredColumns $requiredIconColumns
    Write-Host "Reading $($iconEntries.Count) icon entries from $iconMapPath."

    $writtenTextCount = 0

    # Loop through each row of data in the map file
    foreach ($entry in $textEntries) {
        # Assign properties to a more readable custom object
        $textData = [PSCustomObject]@{
            Text       = $entry.Text
            X          = $entry.X
            Y          = $entry.Y
            Fill       = $entry.Fill
            Stroke     = $entry.Stroke
            FontSize   = $entry.FontSize
            FontFamily = $entry.FontFamily
            TextAnchor = $entry.TextAnchor
        }

        # Create a new 'text' element in the SVG's namespace
        $textElement = $svgXml.CreateElement("text", $namespace)

        # Set attributes for the new element, only if the value is not empty
        Set-AttributeIfPresent -Element $textElement -Name "x" -Value $textData.X
        Set-AttributeIfPresent -Element $textElement -Name "y" -Value $textData.Y
        Set-AttributeIfPresent -Element $textElement -Name "fill" -Value $textData.Fill
        Set-AttributeIfPresent -Element $textElement -Name "stroke" -Value $textData.Stroke
        Set-AttributeIfPresent -Element $textElement -Name "font-size" -Value $textData.FontSize
        Set-AttributeIfPresent -Element $textElement -Name "font-family" -Value $textData.FontFamily
        Set-AttributeIfPresent -Element $textElement -Name "text-anchor" -Value $textData.TextAnchor
        
        # Set the actual text content of the element
        $textElement.InnerText = $textData.Text

        # Append the newly created and configured text element to the parent <g> element
        [void]$parentElement.AppendChild($textElement)
        $writtenTextCount++
    }

    $writtenIconCount = 0
    foreach ($entry in $iconEntries) {
        $iconName = Get-IconName -Value $entry.Name
        $iconFileName = Get-IconName -Value $entry.Icon
        $iconId = "icon-$iconName"

        $iconPath = Get-IconPath -IconName $iconFileName
        if (-not (Test-Path $iconPath)) { throw "Icon SVG file not found at: $iconPath" }

        $iconXml = [xml](Get-Content -Path $iconPath -Raw)
        $iconElement = $svgXml.CreateElement("svg", $namespace)
        Set-AttributeIfPresent -Element $iconElement -Name "id" -Value $iconId
        Set-AttributeIfPresent -Element $iconElement -Name "x" -Value $entry.X
        Set-AttributeIfPresent -Element $iconElement -Name "y" -Value $entry.Y
        Set-AttributeIfPresent -Element $iconElement -Name "width" -Value $entry.Width
        Set-AttributeIfPresent -Element $iconElement -Name "height" -Value $entry.Height
        Set-AttributeIfPresent -Element $iconElement -Name "viewBox" -Value $iconXml.DocumentElement.GetAttribute("viewBox")

        foreach ($childNode in $iconXml.DocumentElement.ChildNodes) {
            $importedNode = $svgXml.ImportNode($childNode, $true)
            [void]$iconElement.AppendChild($importedNode)
        }

        [void]$parentElement.AppendChild($iconElement)
        $writtenIconCount++
    }

    # Save the fully reconstructed XML object to the final SVG file
    $xmlWriterSettings = [System.Xml.XmlWriterSettings]::new()
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.OmitXmlDeclaration = $true
    $xmlWriter = [System.Xml.XmlWriter]::Create($outputSvgPath, $xmlWriterSettings)
    try {
        $svgXml.Save($xmlWriter)
    }
    finally {
        $xmlWriter.Dispose()
    }

    Write-Host "Successfully assembled the full SVG with $writtenTextCount text entries and $writtenIconCount icon entries: $outputSvgPath"

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}
