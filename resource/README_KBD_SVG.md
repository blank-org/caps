# Keyboard SVG Assembly Notes

This note documents `assemble.ps1`, the files it expects, and the path behavior that can make `$svgXml.Save(...)` write outside the expected directory.

## Files

- `assemble.ps1`: rebuilds the keyboard map SVG by loading a base SVG and injecting text labels from `map_keys.csv` and `map_caps.csv`, plus inline icon SVG from `map_icons.csv`.
- `base_svg.svg`: SVG structure used as the base document.
- `map_keys.csv`: key label data used to create base `<text>` elements.
- `map_caps.csv`: caps-layer label data used to create overlay `<text>` elements.
- `map_icons.csv`: icon data used to embed SVG elements from `kbd-icons/`.

## Current Assembly Flow

1. Load `base_svg.svg` as XML:

   ```powershell
   $svgXml = [xml](Get-Content -Path $baseSvgPath -Raw)
   ```

2. Read `map_keys.csv`, `map_caps.csv`, and `map_icons.csv` with `Import-Csv`.
3. For each row, create a new SVG `<text>` element.
4. Set attributes such as `x`, `y`, `fill`, `stroke`, `font-size`, `font-family`, and `text-anchor`.
5. For each icon row, load the source icon SVG and create a nested inline `<svg>` element with `x`, `y`, `width`, `height`, `viewBox`, and copied child shapes.
6. Append the generated nodes to the first `<g>` element in the SVG, or to the root `<svg>` element if no group exists.
7. Save the reconstructed SVG.

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
$textMapPaths = @(
    (Join-Path $PSScriptRoot "map_keys.csv"),
    (Join-Path $PSScriptRoot "map_caps.csv")
)
$iconMapPath = Join-Path $PSScriptRoot "map_icons.csv"
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

- The CSV maps are read with `Import-Csv`, so normal CSV quoting, empty columns, and line endings are handled by PowerShell.
- `map_keys.csv` and `map_caps.csv` require these columns: `Text`, `X`, `Y`, `Fill`, `Stroke`, `FontSize`, `FontFamily`, and `TextAnchor`.
- `map_icons.csv` requires these columns: `Name`, `Icon`, `X`, `Y`, `Width`, and `Height`.
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
