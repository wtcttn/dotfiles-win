// Yume-kawaii: a pastel watercolor sky with chubby stars, bokeh, and glitter.
// Typing throws a random burst of stars from the cursor.
// Background effects paint only on dark cells so text stays readable.

const vec3 PINK = vec3(0.98, 0.56, 0.86);
const vec3 SKY = vec3(0.50, 0.80, 1.00);
const vec3 YELLOW = vec3(1.00, 0.92, 0.60);
const vec3 LAVENDER = vec3(0.76, 0.62, 1.00);
const vec3 CREAM = vec3(1.00, 0.96, 0.88);

// Size in pixels of the background image anchored at the bottom-right.
const float IMAGE_SIZE = 420.0;

// Overall strength of the background color and decorations (0 = off, 1 = full).
const float EFFECT = 0.5;

// Brightness of the pastel gradient behind the text. Lower is darker and easier to read.
// Shader colors are linear, so small values already look fairly bright on screen.
const float BRIGHTNESS = 0.15;

// Strength of the cursor glow and the star burst while typing.
const float CURSOR_LIGHT = 0.5;

// Brightness of the stars thrown out while typing, on top of CURSOR_LIGHT.
const float BURST_STAR = 0.2;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float dot2(vec2 v) {
    return dot(v, v);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x),
        mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = p * 2.03 + vec2(1.7, 9.2);
        amplitude *= 0.5;
    }
    return value;
}

mat2 rotate(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

// Signed distance to a five-pointed star of outer radius r; rf sets how deep the notches are.
float sdStar5(vec2 p, float r, float rf) {
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x, k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float chubbyStar(vec2 p, float r) {
    return sdStar5(p, r * 0.86, 0.55) - r * 0.14;
}

vec3 starColor(float h) {
    if (h < 0.3) return vec3(1.00, 0.95, 0.55);
    if (h < 0.55) return vec3(0.55, 0.95, 1.00);
    if (h < 0.8) return vec3(1.00, 0.58, 0.90);
    return vec3(0.80, 0.56, 1.00);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = vec2(uv.x * aspect, uv.y);
    float t = iTime;
    float pixel = 1.0 / iResolution.y;

    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Colors here are linear: the plain background is about 0.01, so anything brighter
    // than 0.03 is a glyph or its anti-aliased edge and must be left untouched.
    float background = smoothstep(0.03, 0.015, luma);
    vec2 imageCenter = vec2(iResolution.x - IMAGE_SIZE * 0.5, IMAGE_SIZE * 0.5);
    float inImage = smoothstep(IMAGE_SIZE * 0.8, IMAGE_SIZE * 0.25, length(fragCoord - imageCenter));

    vec2 warp = vec2(fbm(p * 1.4 + t * 0.03), fbm(p * 1.4 - t * 0.025 + 4.0)) * 0.4 - 0.2;
    vec2 w = p + warp;
    float gx = clamp(w.x / aspect, 0.0, 1.0);
    float gy = clamp(w.y, 0.0, 1.0);
    vec3 top = mix(PINK, SKY, smoothstep(0.45, 0.95, gx));
    vec3 bottom = mix(YELLOW, LAVENDER, smoothstep(0.3, 0.9, gx));
    vec3 dream = mix(bottom, top, smoothstep(0.1, 0.8, gy));
    dream = mix(dream, PINK, 0.3 * fbm(p * 2.6 + vec2(t * 0.04, 0.0)));

    float tint = 0.8 * (1.0 - 0.75 * inImage);
    color.rgb = mix(color.rgb, dream * BRIGHTNESS, tint * background);
    color.rgb += dream * 0.05 * EFFECT * inImage * background;

    float decor = EFFECT * background * (1.0 - 0.7 * inImage);
    vec3 glow = vec3(0.0);

    vec2 grid = p * 55.0;
    vec2 cellId = floor(grid);
    float seed = hash2(cellId);
    float density = smoothstep(0.35, 0.75, fbm(p * 1.8 + vec2(3.0, t * 0.02)));
    if (seed > 1.0 - 0.4 * density) {
        vec2 spot = (fract(grid) - (0.25 + 0.5 * vec2(hash2(cellId + 3.1), hash2(cellId + 7.7)))) / 55.0;
        float twinkle = 0.5 + 0.5 * sin(t * (1.5 + seed * 3.0) + seed * 40.0);
        float radius = pixel * (0.8 + seed * 1.6);
        glow += CREAM * exp(-dot2(spot) / (radius * radius)) * twinkle * 0.55;
    }

    for (int i = 0; i < 9; i++) {
        float id = float(i) + 20.0;
        float radius = 0.03 + hash(id * 3.3) * 0.06;
        vec2 center = vec2(
            fract(hash(id * 2.7) + t * 0.004 * (hash(id) - 0.5)) * aspect,
            hash(id * 6.6) * 0.6 + sin(t * 0.2 + id) * 0.02
        );
        float disc = smoothstep(radius, radius * 0.55, length(p - center));
        glow += mix(CREAM, PINK, hash(id * 4.1) * 0.5) * disc * 0.07;
    }

    for (int i = 0; i < 16; i++) {
        float id = float(i) + 40.0;
        float size = 0.012 + hash(id * 7.1) * 0.02;
        vec2 drift = vec2(0.006, 0.01) * (0.5 + hash(id * 3.7)) * t;
        vec2 center = vec2(fract(hash(id * 12.9) + drift.x) * aspect, fract(hash(id * 78.2) + drift.y) * 1.1 - 0.05);
        vec2 q = rotate(t * (hash(id * 2.2) - 0.5) * 0.6 + id) * (p - center);
        float d = chubbyStar(q, size);
        float fill = smoothstep(pixel * 1.5, -pixel * 1.5, d);
        float halo = exp(-max(d, 0.0) / (size * 0.5)) * 0.25;
        float pulse = 0.7 + 0.3 * sin(t * (0.8 + hash(id * 5.5)) + id);
        glow += starColor(hash(id * 9.1)) * (fill * 0.55 + halo) * pulse;
    }

    color.rgb += glow * decor;

    vec2 cursor = vec2(
        iCurrentCursor.x + iCurrentCursor.z * 0.5,
        iCurrentCursor.y - iCurrentCursor.w * 0.5
    );
    float cell = max(iCurrentCursor.w, 8.0);
    vec2 toCursor = fragCoord - cursor;
    vec3 cursorColor = mix(PINK, SKY, 0.5 + 0.5 * sin(t * 2.0));
    vec3 cursorLight = cursorColor * exp(-dot2(toCursor) / (cell * cell * 0.9)) * 0.2;

    float since = t - iTimeCursorChange;
    if (since < 1.1) {
        float burst = fract(iTimeCursorChange * 7.31 + cursor.x * 0.0131 + cursor.y * 0.0071);
        int count = 5 + int(hash(burst * 91.0) * 6.0);
        for (int i = 0; i < 10; i++) {
            if (i >= count) break;
            float id = float(i) * 13.7 + burst * 1000.0;
            float life = 0.6 + hash(id * 4.4) * 0.5;
            float age = since / life;
            if (age >= 1.0) continue;
            float angle = hash(id * 1.3) * 6.2831853;
            float speed = cell * (1.0 + hash(id * 2.9) * 3.5);
            vec2 velocity = vec2(cos(angle), sin(angle) * 0.7 + 0.5) * speed;
            vec2 position = velocity * since - vec2(0.0, cell * 3.0) * since * since;
            float size = cell * (0.16 + hash(id * 5.7) * 0.26) * (1.0 - age * 0.4);
            float spin = hash(id * 6.1) * 6.2831853 + since * (hash(id * 8.3) - 0.5) * 14.0;
            float d = chubbyStar(rotate(spin) * (toCursor - position), size);
            float fill = smoothstep(1.0, -1.0, d);
            float halo = exp(-max(d, 0.0) / (size * 0.6)) * 0.35;
            float fade = 1.0 - smoothstep(0.5, 1.0, age);
            cursorLight += starColor(hash(id * 9.1)) * (fill * 0.85 + halo) * fade * BURST_STAR;
        }
        for (int i = 0; i < 8; i++) {
            float id = float(i) * 5.3 + burst * 777.0;
            float age = since / 0.8;
            if (age >= 1.0) break;
            float angle = hash(id * 1.9) * 6.2831853;
            vec2 position = vec2(cos(angle), sin(angle)) * cell * (0.5 + hash(id * 3.1) * 2.5) * sqrt(age);
            float radius = 1.2 + hash(id * 2.3) * 1.5;
            cursorLight += CREAM * exp(-dot2(toCursor - position) / (radius * radius)) * (1.0 - age) * 0.8;
        }
    }

    color.rgb += cursorLight * CURSOR_LIGHT;
    fragColor = vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
