// crt80s.glsl — 80s colour-CRT look for Ghostty 1.3.1 custom shader.
// Ghostty prepends the version directive, uniforms, io and main(); this supplies mainImage only.
// fragCoord.y is DOWN (macOS/Metal). Edit the dial block below; nothing else needs tuning.
// Uses only the documented uniforms; output goes to fragColor.

// ---------------------------------------------------------------------------
// THE DIAL — unit / range / effect. Every tunable lives here.
// ---------------------------------------------------------------------------
const float SCANLINE_PERIOD_PX  = 6.0;    // device px between scanlines; 2 = one line every other pixel row (2..48)
const float SCANLINE_PHASE_PX   = 0.5;    // centre of the first device row; keep it half-integer on short periods
const float SCANLINE_DEPTH      = 0.35;   // fraction removed inside the line, ink only (0..0.7)
const float SCANLINE_THICK_PX   = 2.0;    // full width of the dark line, device px (0.5..16)
const float SCANLINE_EDGE_PX    = 4.0;    // edge softness; 0.5 = crisp pixel-on/pixel-off, 3 = soft (0.5..4)
const float SCANLINE_BG_DEPTH   = 0.0;    // same, on empty background; 0 keeps it clean (0..0.2)
const float INK_LO              = 0.03;   // gamma-space distance from background where ink starts (0..1)
const float INK_HI              = 0.16;   // distance where ink counts fully (0..1)
const float GRILLE_PERIOD_PX    = 4.0;    // device px between vertical grille stripes (2..8)
const float GRILLE_AMPLITUDE    = 0.06;   // vertical stripe depth (0..0.15)
const float MISCONVERGENCE_PX   = 0.8;    // max R/B x-offset at corners, device px (0..4)
const float BLOOM_THRESHOLD_REL = 1.0;    // fraction of foreground luma counted as bright (0.3..1.0)
const float BLOOM_RADIUS_PX     = 4.0;    // device px radius of the glow ring (2..12)
const float BLOOM_STRENGTH      = 0.30;   // weight of accumulated glow (0..1)
const float BLOOM_DESAT         = 0.12;   // saturation lost by bright areas (0..1)
const float VIGNETTE            = 0.12;   // corner dimming (0..0.3)
const float VIGNETTE_POWER      = 2.0;    // radial falloff exponent (1..4)
const float CURVATURE           = 0.0;    // barrel warp, 0 = flat glass (0..0.15)
const float SHEEN               = 0.0;    // diagonal glass reflection (0..0.10)
const float SHEEN_WIDTH         = 0.22;   // diagonal band width in uv (0.10..0.60)
const float CURSOR_GLOW         = 0.25;   // extra halo around cursor block (0..1)
const float CURSOR_HALO_PX      = 8.0;   // device px gaussian falloff of cursor halo (4..32)
const vec3  WARM_TINT           = vec3(1.0, 0.94, 0.86); // warm cast, bloom only

#define TAU 6.283185307179586

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 linearize(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }

vec3 unpremul(vec4 s) { return s.a > 0.0 ? s.rgb / s.a : vec3(0.0); }

vec3 linearTex(vec2 uv) { return linearize(unpremul(texture(iChannel0, uv))); }

vec2 barrelWarp(vec2 uv, float k) {
    vec2 p = uv * 2.0 - 1.0;
    p *= 1.0 + k * dot(p, p);
    return p * 0.5 + 0.5;
}

float scanlineMask(float y, float depth) {
    // Distance in device px from the nearest band centre, then a hard-edged pulse.
    float f = (y - SCANLINE_PHASE_PX) / SCANLINE_PERIOD_PX;
    float d = abs(fract(f + 0.5) - 0.5) * SCANLINE_PERIOD_PX;
    float halfT = 0.5 * SCANLINE_THICK_PX;
    float edge = 0.5 * SCANLINE_EDGE_PX;
    float line = 1.0 - smoothstep(halfT - edge, halfT + edge, d);
    return 1.0 - depth * line;
}

float grilleMask(float x, float amp) {
    float band = 0.5 + 0.5 * cos(TAU * x / GRILLE_PERIOD_PX);
    return 1.0 - amp * band;
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord / res;

    // 7. Curvature first: folded completely away at 0.0 (zero resampling).
    if (CURVATURE > 0.0) {
        uv = barrelWarp(uv, CURVATURE);
    }

    // 1. Centre sample: unpremultiply, linearise, keep alpha untouched.
    vec4 centre = texture(iChannel0, uv);
    float a = centre.a;
    vec3 centreLin = linearize(unpremul(centre));

    // Ink mask: gamma-space distance from the theme background. Scanlines ride on
    // this so glyphs keep the bands and empty background stays flat.
    vec3 centreGamma = unpremul(centre);
    float inkDiff = max(max(abs(centreGamma.r - iBackgroundColor.r),
                            abs(centreGamma.g - iBackgroundColor.g)),
                        abs(centreGamma.b - iBackgroundColor.b));
    float ink = smoothstep(INK_LO, INK_HI, inkDiff);

    // Theme / pane adaptation (independent, cheap).
    float bgLuma = luma(linearize(iBackgroundColor.rgb));
    float light = smoothstep(0.30, 0.70, bgLuma);
    float small = smoothstep(420.0, 900.0, min(res.x, res.y));
    float scanDepth = mix(SCANLINE_BG_DEPTH, SCANLINE_DEPTH, ink) * mix(1.0, 0.18, light);
    float grilleAmp = GRILLE_AMPLITUDE * mix(1.0, 0.25, light) * small;

    // 2. Misconvergence: squared aspect-corrected distance, 0 at centre.
    float aspect = res.x / res.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float d2 = dot(p, p);
    float maxD2 = 0.25 * (aspect * aspect + 1.0);
    float offUv = MISCONVERGENCE_PX * (d2 / maxD2) / res.x;
    vec3 tapR = linearize(unpremul(texture(iChannel0, uv + vec2(offUv, 0.0))));
    vec3 tapG = linearize(unpremul(texture(iChannel0, uv)));
    vec3 tapB = linearize(unpremul(texture(iChannel0, uv - vec2(offUv, 0.0))));
    vec3 color = vec3(tapR.r, tapG.g, tapB.b);

    // 3. Bloom: fg-relative threshold, 8-tap ring + centre, soft knee.
    float thr = clamp(BLOOM_THRESHOLD_REL * luma(linearize(iForegroundColor.rgb)), 0.05, 1.0);
    float knee = thr + 0.15;
    vec2 rad = vec2(BLOOM_RADIUS_PX) / res;
    vec3 bloomSum = centreLin * smoothstep(thr, knee, luma(centreLin));
    for (int i = 0; i < 8; ++i) {
        float ang = float(i) * (TAU / 8.0);
        vec3 s = linearTex(uv + vec2(cos(ang), sin(ang)) * rad);
        bloomSum += s * smoothstep(thr, knee, luma(s));
    }
    vec3 bloom = (bloomSum / 9.0) * (BLOOM_STRENGTH * (1.0 - light)) * WARM_TINT;
    color += bloom;
    color = mix(color, vec3(luma(color)), clamp(BLOOM_DESAT * luma(bloom), 0.0, 1.0));

    // 4. Overbright: roll the whole colour down, never hard-clip.
    float peak = max(max(color.r, color.g), color.b);
    color /= max(1.0, peak);

    // 5. Re-encode.
    vec3 rgb = pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));

    // 6. Masks in gamma space: scanlines ride the ink mask (text only), grille is whole-frame.
    rgb *= scanlineMask(fragCoord.y, scanDepth);
    rgb *= grilleMask(fragCoord.x, grilleAmp);

    vec2 q = (uv - 0.5) * vec2(aspect, 1.0) * 2.0;
    float t = clamp(dot(q, q) / (aspect * aspect + 1.0), 0.0, 1.0);
    rgb *= 1.0 - VIGNETTE * small * pow(t, VIGNETTE_POWER);

    if (SHEEN > 0.0) {
        float d = (uv.x + uv.y - 1.0) / SHEEN_WIDTH;
        rgb += vec3(SHEEN * exp(-d * d));
    }

    // 8. Cursor halo: warm, gated on visibility, no-op on degenerate rects.
    // iCurrentCursor.xy is the -X/+Y corner (Y down) and zw the block size, so the
    // two corners are p0 and p0 + (w, -h); sort them so clamp() gets a real box.
    vec2 p0 = iCurrentCursor.xy;
    vec2 p1 = p0 + vec2(iCurrentCursor.z, -iCurrentCursor.w);
    vec2 cLo = min(p0, p1);
    vec2 cHi = max(p0, p1);
    float cd = length(fragCoord - clamp(fragCoord, cLo, cHi));
    float halo = exp(-(cd * cd) / (CURSOR_HALO_PX * CURSOR_HALO_PX));
    float valid = step(1.0, iCurrentCursor.z) * step(1.0, iCurrentCursor.w) * float(iCursorVisible);
    rgb += iCurrentCursorColor.rgb * (halo * CURSOR_GLOW * valid);

    // 9. Re-premultiply; alpha passes through untouched.
    fragColor = vec4(rgb * a, a);
}
