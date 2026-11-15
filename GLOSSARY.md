# ghostty-80s

A visual treatment for the Ghostty terminal that makes a color terminal surface read as a 1980s color CRT monitor. It exists so long terminal sessions can feel period-correct without becoming unreadable.

## Language

**Color CRT**:
A 1980s color cathode-ray monitor of the composite-video era, whose look is defined by visible scanlines, phosphor bloom, and glass falloff. Distinct from a monochrome phosphor terminal.
_Avoid_: CRT TV, retro monitor, 80s vibe, retro filter

**Custom shader**:
Ghostty's full-screen fragment pass, applied to a surface that has already been rendered. The project's only artifact is one custom shader.
_Avoid_: filter, post-process, effect, overlay

## Tube anatomy

**Scanline**:
One horizontal trace of the electron beam, visible as a periodic darker band between rows of lit phosphor.
_Avoid_: raster line, stripe, grid line

**Aperture grille**:
The vertical phosphor-stripe mask of a Trinitron-style tube, visible as fine vertical stripes.
_Avoid_: shadow mask, dot triad, RGB mask, pixel grid

**Misconvergence**:
The slight misalignment of the red, green, and blue beams, which shows as colour fringing that grows away from the centre of the tube.
_Avoid_: chromatic aberration, colour blur, colour shift

**Bloom**:
The halo of scattered light around bright phosphor, which makes bright text appear to glow into its surroundings.
_Avoid_: glow, halation, flare, light bleed

**Vignette**:
The dimming of the tube toward its edges and corners.
_Avoid_: edge falloff, corner darkening, gradient

**Sheen**:
A reflection of ambient light on the glass, drawn as a faint diagonal band.
_Avoid_: glare, gloss, reflection

## The dial

**Dial**:
The named intensity constants at the top of the shader that set how strong each CRT effect is. The default values are the daily-driver look; raising them trades legibility for fidelity.
_Avoid_: settings, params, config, knobs

**Daily-driver default**:
The default intensity at which the look stays comfortable across an eight-hour session. An effect that cannot meet this bar is off by default.
_Avoid_: sane defaults, subtle mode, lite mode
