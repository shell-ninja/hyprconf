// wallfx.frag — the wallpaper transitions (WallpaperFx.qml).
//
// Nothing here knows WHEN a pixel changes: the maps made by ~/.local/bin/wallfx
// say so, and this only reads them. `t` runs from 0 to 1 in time.
//
// Two transitions, one language: crisp 4 px cells eating through the old
// wallpaper along ragged, organic fronts.
//
//   CONTAGION (mode 0), any wallpaper: a handful of colonies land at random
//   places and moments. Each cell that has just flipped burns for an instant
//   in the new palette's most vivid colour, a thin glow rides the front, and
//   now and then a spark jumps ahead of it.
//
//   OUTLINE (mode 1), a wallpaper with a character, nonchalant: the stage steps
//   back a little, a thin quiet line in the palette's light tone draws the
//   character's outline (two pens from the top), the character fills in from
//   that outline, and then the rest of the world spreads out of it. No glow,
//   no flash: it should look effortless. (An earlier version lit it up like a
//   Pokémon evolution; Diego asked for it "more nonchalant, less neon".)
//
// Every extra effect is scaled by sin(πt), so it is exactly zero at both ends,
// and both cameras end where awww draws: the hand-over cannot show.
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// qt_Matrix + qt_Opacity first (Qt's vertex shader demands it), then floats
// only, then the vec4s: a vec2 among the floats breaks the std140 layout.
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;          // 0..1, linear in time
    float mode;       // 0 contagion, 1 outline
    float sw;         // screen, px
    float sh;
    float fw;         // fieldTex, texels
    float fh;
    float lw;         // lineTex, texels
    float lh;
    float glow;       // 0..1, strength of the contagion's light
    float lineW;      // outline width, px
    float sdRange;    // fieldTex B spans +-sdRange map px
    float seed;       // a different one every change: the sparks never repeat
    vec4 cropOld;     // image uv = xy + screen uv * zw  (awww's "crop": cover, centred)
    vec4 cropNew;
    vec4 ember;       // the new palette's most vivid colour: the contagion's burning edge
    vec4 ink;         // its lightest tone: the outline's line
};
layout(binding = 1) uniform sampler2D oldTex;
layout(binding = 2) uniform sampler2D newTex;
layout(binding = 3) uniform sampler2D fieldTex;
layout(binding = 4) uniform sampler2D lineTex;

const float PI = 3.14159265;
const float CELL = 4.0;   // px, the size of the pixels that eat through

// ESCENA's curve (motion-language.md): the phases reveal AREA, and an area at a
// steady rate already brakes by itself, so the curve only softens the ends.
float escena(float x) { x = clamp(x, 0.0, 1.0); return x * x * (3.0 - 2.0 * x); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 13.17) * 43758.5453); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 oldAt(vec2 uv) { return texture(oldTex, cropOld.xy + uv * cropOld.zw).rgb; }
vec2 newUv(vec2 uv) { return cropNew.xy + uv * cropNew.zw; }

// 16-bit surface in lineTex's G (high) and B (low), interpolated by hand: the
// sampler's bilinear filter would blend the two bytes separately.
float s16(vec2 texel) {
    texel = clamp(texel, vec2(0.0), vec2(lw, lh) - 1.0);
    vec4 f = texture(lineTex, (texel + 0.5) / vec2(lw, lh));
    return (floor(f.g * 255.0 + 0.5) * 256.0 + floor(f.b * 255.0 + 0.5)) / 65535.0;
}
float surface(vec2 tuv) {
    vec2 p = tuv * vec2(lw, lh) - 0.5;
    vec2 i = floor(p), f = p - i;
    return mix(mix(s16(i), s16(i + vec2(1.0, 0.0)), f.x),
               mix(s16(i + vec2(0.0, 1.0)), s16(i + vec2(1.0, 1.0)), f.x), f.y);
}

// ───────────────────────────── contagion ─────────────────────────────
//
// fieldTex: each cell's moment (R high, G low), 480x270; lineTex: the same
// moment, blurred, for the glow. No water, no stages: the edge IS the effect,
// and it is the new image's own colours that eat the old one.

float arrivalAt(vec2 c) {
    c = clamp(c, vec2(0.0), vec2(fw, fh) - 1.0);
    vec4 f = texture(fieldTex, (c + 0.5) / vec2(fw, fh));
    return (floor(f.r * 255.0 + 0.5) * 256.0 + floor(f.g * 255.0 + 0.5)) / 65535.0;
}

vec3 contagion(vec2 uv) {
    const float LIFE = 0.05;                // how long a flipped cell burns, in area
    float tNorm = min(t / 0.85, 1.0);
    float energy = sin(PI * tNorm);
    float T = escena(tNorm) * (1.0 + LIFE);
    float s = surface(uv);
    vec2 cell = floor(uv * vec2(fw, fh));
    float a = arrivalAt(cell);
    float flick = hash(cell);
    vec3 hot = mix(ember.rgb, vec3(1.0), 0.18);
    vec3 c;
    if (a > T) {
        c = oldAt(uv);
        // a spark: a lone cell just ahead of the front lights up for a moment
        float ahead = a - T;
        if (flick > 0.985 && ahead < 0.02)
            c = mix(c, hot, (1.0 - ahead / 0.02) * 0.8 * glow * step(0.0, T));
    } else {
        c = texture(newTex, newUv(uv)).rgb;   // locked 1.0 camera: zero shockwave/displacement
        bool edge = max(max(arrivalAt(cell + vec2(1.0, 0.0)), arrivalAt(cell - vec2(1.0, 0.0))),
                        max(arrivalAt(cell + vec2(0.0, 1.0)), arrivalAt(cell - vec2(0.0, 1.0)))) > T;
        float life = clamp((T - a) / LIFE, 0.0, 1.0);
        float burn = (1.0 - life) * (1.0 - life) * (edge ? 1.0 : 0.55);
        c = mix(c, hot, burn * (0.55 + 0.45 * flick) * 0.85 * glow);
    }
    return c;
}

// ───────────────────────────── outline ─────────────────────────────
//
// The maps live in the NEW image's space: fieldTex G = depth inside the
// character (0 on its outline), B = signed distance near it; lineTex R = where
// along the outline each point is, G/B = the order in which the outside
// arrives (outwards from the character, roughened with noise), smooth.

vec3 outline(vec2 uv) {
    // Locked 1.0 camera to ensure seamless, rock-solid subpixel alignment with awww
    vec2 u = newUv(uv);
    vec4 f = texture(fieldTex, u);
    float sdPx = (f.b * 2.0 - 1.0) * sdRange * sw / (fw * cropNew.z);
    float inside = clamp(0.5 - sdPx / max(fwidth(sdPx), 1e-3), 0.0, 1.0);

    // Stage 1: Smooth pre-dimming (gentle desaturation, runs in parallel with ink trace)
    float back = smoothstep(0.0, 0.18, t);
    vec3 st = oldAt(uv);
    st = mix(st, vec3(luma(st)), 0.55 * back) * (1.0 - 0.08 * back);

    // Stage 3: Inside fill (continuous UV, smoothstep anti-aliased blend, fully done by t=0.50)
    float Ti = escena((t - 0.15) / 0.35) * 1.10;
    float fVal = f.g;
    float fillP = smoothstep(fVal - 0.03, fVal + 0.03, Ti);
    vec3 cIn = mix(st, texture(newTex, u).rgb, fillP);

    // Stage 4: World bloom (continuous UV, smoothstep anti-aliased bloom, fully done everywhere by t=0.78)
    float To = escena((t - 0.30) / 0.45) * 1.10;
    float sVal = surface(u);
    float bloomP = smoothstep(sVal - 0.03, sVal + 0.03, To);
    vec3 cOut = mix(st, texture(newTex, u).rgb, bloomP);

    vec3 c = mix(cOut, cIn, inside);

    // Stage 2: Ink pen line trace starts immediately at t = 0.0 on the first frame
    float drawP = escena(t / 0.30);
    float lp = texture(lineTex, u).r;
    float fade = 1.0 - escena((t - 0.42) / 0.25);
    if (lp > 0.0 && lp <= drawP && fade > 0.0) {
        float d = abs(sdPx) - lineW * 0.5;
        float core = clamp(0.5 - d / max(fwidth(sdPx), 1e-3), 0.0, 1.0);
        c = mix(c, ink.rgb, core * 0.75 * fade);
    }
    return c;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 c = mode < 0.5 ? contagion(uv) : outline(uv);
    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0) * qt_Opacity;
}
