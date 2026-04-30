# Keyboard SVG Assembly Notes

This note documents `assemble.ps1`, the files it expects, and the path behavior that can make `$svgXml.Save(...)` write outside the expected directory.

## Files

- `assemble.ps1`: rebuilds the keyboard map SVG by loading a base SVG and injecting text labels from `map.csv`.
- `base_svg.svg`: SVG structure used as the base document.
- `map.csv`: label data used to create new `<text>` elements.

## Current Assembly Flow

1. Load `base_svg.svg` as XML:

   ```powershell
   $svgXml = [xml](Get-Content -Path $baseSvgPath -Raw)
   ```

2. Read `map.csv` with `Import-Csv`.
3. For each row, create a new SVG `<text>` element.
4. Set attributes such as `x`, `y`, `fill`, `stroke`, `font-size`, `font-family`, and `text-anchor`.
5. Append the text node to the first `<g>` element in the SVG, or to the root `<svg>` element if no group exists.
6. Save the reconstructed SVG.

## Important Path Issue

`$svgXml.Save($outputSvgPath)` is a .NET XML API call. It does not resolve paths the same way PowerShell cmdlets such as `Get-Content` and `Test-Path` do.

PowerShell cmdlets resolve relative paths against PowerShell's current location. The .NET `Save(string)` call resolves relative paths against the process current directory. In VS Code, tasks, nested scripts, or other launch contexts, the process current directory can be different from the directory shown by the PowerShell prompt.

That is why this can write to the parent/project directory even when the command appears to be run from `resource`:

```powershell
$outputSvgPath = "resource/keyboard-map-tks.svg"
$svgXml.Save($outputSvgPath)
```


## Recommended Path Pattern

Use `$PSScriptRoot` for files that should be located relative to `assemble.ps1`, then convert the final output path to a filesystem path before calling the .NET `Save()` method.

```powershell
$baseSvgPath = Join-Path $PSScriptRoot "base_svg.svg"
$mapDataPath = Join-Path $PSScriptRoot "map.csv"
$outputSvgPath = Join-Path $PSScriptRoot "keyboard-map-tks.svg"

$outputSvgPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputSvgPath)
$svgXml.Save($outputSvgPath)
```

This makes the script independent of the shell's current directory and avoids accidental output in the repo root or parent directory.

## Running The Script

From the repo root:

```powershell
.\resource\assemble.ps1
```

From the `resource` directory:

```powershell
.\assemble.ps1
```

With the `$PSScriptRoot` pattern, both commands should read the same input files and write the same output file.

## Things To Watch

- `map.csv` is read with `Import-Csv`, so normal CSV quoting, empty columns, and line endings are handled by PowerShell.
- The script requires these columns: `Text`, `X`, `Y`, `Fill`, `Stroke`, `FontSize`, `FontFamily`, and `TextAnchor`.
- The script appends labels to the first `<g>` element it finds. If the base SVG gains multiple groups, the output location may need to be made more specific.
- SVG namespace handling is required. New elements should continue to be created with:

  ```powershell
  $textElement = $svgXml.CreateElement("text", $namespace)
  ```

## Quick Verification

After generation, verify the output path and XML validity:

```powershell
Test-Path .\resource\keyboard-map-tks.svg
[xml](Get-Content -Raw .\resource\keyboard-map-tks.svg) | Out-Null
```
