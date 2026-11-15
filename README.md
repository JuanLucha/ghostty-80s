# ghostty-80s

A single Ghostty custom shader that makes a colour terminal surface read as a 1980s composite-era
CRT monitor: scanlines, an aperture grille, phosphor bloom, slight misconvergence toward the edges
and a gentle vignette. It deliberately omits glass curvature, composite chroma smear and animation,
because each of those softens 1-px stems over an eight-hour session. It never touches your palette.

## Install

1. Symlink the shader into Ghostty's shader directory:

   ```
   ln -sf ~/code/ghostty-80s/crt80s.glsl ~/.config/ghostty/shaders/crt80s.glsl
   ```

2. Add to the Ghostty config file. Paths in `custom-shader` resolve relative to the config file
   that declares them:

   ```
   custom-shader = shaders/crt80s.glsl
   custom-shader-animation = false
   ```

   `custom-shader-animation` defaults to `true` and must be set to `false` explicitly, because this
   shader is static.

3. Reload the config (`Cmd+Shift+,`) or restart Ghostty.

## The dial

| Constant | Default | Range | Effect |
| --- | --- | --- | --- |
| SCANLINE_PERIOD_PX | 2.0 | 2–48 | Device pixels between scanlines; 2 is one dark row every other device pixel row. |
| SCANLINE_PHASE_PX | 0.5 | 0–period | Offset of the first line. Keep it half-integer: device rows centre at y = 0.5, 1.5, … |
| SCANLINE_DEPTH | 0.35 | 0–0.7 | Fraction of the encoded value removed inside the dark line, over glyphs only. |
| SCANLINE_THICK_PX | 1.0 | 0.5–16 | Full width of the dark line, in device pixels. |
| SCANLINE_EDGE_PX | 0.5 | 0.5–4 | Edge softness; 0.5 gives crisp pixel-on/pixel-off, 3 gives a soft band. |
| SCANLINE_BG_DEPTH | 0.0 | 0–0.2 | Same, over empty background; 0 keeps the background clean. |
| INK_LO | 0.03 | 0–1 | Gamma-space distance from the theme background where a pixel starts counting as ink. |
| INK_HI | 0.16 | 0–1 | Distance at which a pixel counts as ink fully; the scanlines fade in between the two. |
| GRILLE_PERIOD_PX | 4.0 | 2–8 | Device pixels between vertical aperture-grille stripes. |
| GRILLE_AMPLITUDE | 0.06 | 0–0.15 | Vertical stripe modulation. |
| MISCONVERGENCE_PX | 0.8 | 0–4 | Maximum R/B horizontal offset at corners; 0 at pane centre. |
| BLOOM_THRESHOLD_REL | 1.0 | 0.3–1.0 | Fraction of theme foreground luminance read as bright. |
| BLOOM_RADIUS_PX | 4.0 | 2–12 | Device-pixel radius of the glow ring. |
| BLOOM_STRENGTH | 0.30 | 0–1 | Weight of the accumulated glow. |
| BLOOM_DESAT | 0.12 | 0–1 | How much bright areas lose saturation as they glow. |
| VIGNETTE | 0.12 | 0–0.3 | Corner dimming. |
| VIGNETTE_POWER | 2.0 | 1–4 | Falloff curve exponent. |
| CURVATURE | 0.0 | 0–0.15 | Barrel warp. 0 is flat glass and costs nothing. |
| SHEEN | 0.0 | 0–0.10 | Faint diagonal reflection band. |
| SHEEN_WIDTH | 0.22 | 0.10–0.60 | Width of the sheen band, in uv. |
| CURSOR_GLOW | 0.45 | 0–1 | Extra halo around the cursor block. |
| CURSOR_HALO_PX | 14.0 | 4–32 | Gaussian falloff distance of the cursor halo, in device px. |
| WARM_TINT | 1.00, 0.94, 0.86 | — | Warmth on the bloom only; flat colours keep exact hues. |

Every value is in device pixels, a 0–1 fraction, or a curve exponent. Lowering `SCANLINE_DEPTH`,
`GRILLE_AMPLITUDE` and `MISCONVERGENCE_PX` is the fastest way to make the look quieter; raising
`SCANLINE_BG_DEPTH` is the only way to put scanlines back on the empty background.

## Things that will bite you

- Ghostty prepends `#version 430 core`, every uniform and `main()` to this file. Never add a
  `#version` line or your own `main()`, or the shader fails to compile.
- Editing `crt80s.glsl` in place and reloading the config may **not** recompile it: on reload
  Ghostty compares the configured path list, not file contents. To force a recompile, restart
  Ghostty or point the config at a different filename.
- A shader that fails to compile is not reported as a config error. It is dropped, which can leave
  a black surface; the error goes to the system log only.
- `fragCoord.y` points **down** on macOS/Metal, unlike Shadertoy.
- This shader is written for `alpha-blending = native` (the macOS default), which means values
  arrive gamma-encoded in Display P3. Under `linear` or `linear-corrected` the values arrive
  linearised and the bloom maths double-corrects.
- Output keeps the incoming premultiplied alpha, so `background-opacity` and transparency behave
  normally.
- On a light theme the bloom switches off and the masks thin out by design; it is not a bug.

## Design notes

- Legibility outranks period accuracy: no curvature, no chroma smear, no animation
  ([ADR 0001](docs/adr/0001-legibility-ceiling.md)).
- The shader ships alone and never edits your palette; on light backgrounds it degrades instead of
  glowing ([ADR 0002](docs/adr/0002-palette-agnostic-shader.md)).
- When retuning for legibility, effects are shed in this order: misconvergence, then grille, then
  bloom, then scanlines. Vignette is never shed.

## License

MIT License

Copyright (c) 2026 lucha

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
