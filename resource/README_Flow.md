# Keyboard SVG Workflow

This directory contains the source files and scripts used to maintain the keyboard map SVG.

The normal workflow is:

1. Edit key positions and visual styling in Inkscape.
2. Disassemble the edited SVG into CSV map files.
3. Assemble the final generated SVG from the base SVG and CSV maps.
4. Keep the generated SVG XML pretty formatted for readable diffs.

## Files

- `base_svg.svg`: base keyboard SVG structure.
- `keyboard-map-tks_guide.svg`: Inkscape SVG with guides to correct key positions and styles.
- `keyboard-map-tks_corrected.svg`: optimized/straightened SVG input used for disassembly.
- `keyboard-map-tks.svg`: final assembled output SVG.
- `kbd-icons/`: source SVG icons embedded by `assemble.ps1`.
- `map_keys.csv`: base key label positions and styles.
- `map_caps.csv`: caps-layer label positions and styles.
- `map_icons.csv`: icon positions and sizes.
- `assemble.ps1`: builds `keyboard-map-tks.svg` from `base_svg.svg` and the CSV maps.
- `disassemble.ps1`: extracts text/icon positions and styles from an SVG back into the CSV maps.

## Edit In Inkscape

Open `keyboard-map-tks_guide.svg` in Inkscape, import current `keyboard-map-tks.svg` : 'include' > position x:0:y and adjust the key labels, icon positions, colors, font sizes, anchors, or other visual details.

When exporting/saving the SVG for script input, use the optimized SVG form:

```text
keyboard-map-tks_corrected.svg
```

The disassembler supports styles that are applied directly to `<text>` nodes and styles inherited from parent `<g>` elements, which is common after SVG cleanup/optimization.

## Disassemble SVG To CSV

```powershell
.\resource\disassemble.ps1 -FileName keyboard-map-tks_corrected.svg -NoBackup
```

This updates:

- `map_keys.csv`
- `map_caps.csv`
- `map_icons.csv`

Use `-NoBackup` when you intentionally want to overwrite the CSV maps directly. Without `-NoBackup`, existing CSV files are renamed to `.bkp.csv`, `.bkp1.csv`, and so on before new files are written.

## Assemble CSV To Final SVG

```powershell
.\resource\assemble.ps1
```

This reads `base_svg.svg`, `map_keys.csv`, `map_caps.csv`, and `map_icons.csv`, then writes:

```text
keyboard-map-tks.svg
```

The assembled SVG is pretty formatted as XML so the generated file remains easier to review in diffs.
