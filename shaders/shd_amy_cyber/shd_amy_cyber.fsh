precision highp float;
precision highp int;

// =====================================================================
//  shd_amy_cyber — AMY «CYBER GHOST» (estilo Frontiers / Cyber Space)
//
//  Es el shd_colour (palette swap) de siempre + el overlay holograma
//  corrupto de la Amy cyberespacial ENCIMA, en un solo shader (GM solo
//  permite un fragment shader a la vez, asi que el palette swap va
//  aqui dentro para no romper las paletas del juego):
//   1. BANDAS DE GLITCH: franjas horizontales que se desplazan a los
//      lados al azar (~30% de las bandas, salta ~7 veces por segundo).
//   2. SPLIT RGB: separacion rojo/cian de los bordes (fringing).
//   3. PALETTE SWAP: identico al shd_colour (u_Pattern/u_Replacements).
//   4. SCANLINES: cada 2 px de pantalla se oscurece una linea.
//   5. BARRIDO: una barra clara que recorre la pantalla cada 2.5 s.
//   6. NIEVE DIGITAL: chispas blancas/cian de 1 px (pantalla).
//   7. PARPADEO: variacion suave del brillo global.
//
//  Todo se ajusta con las macros AMY_CYBER_* de scr_amy_cyber.gml.
//  Es 100% visual: no toca colisiones ni red.
// =====================================================================

// ---- palette swap (identico a shd_colour) ----
uniform highp float u_Pattern[256];
uniform highp float u_Replacements[256];
uniform highp int u_ColourCount;

// ---- cyber ghost ----
uniform vec2  uTexel;    // 1/ancho y 1/alto de la textura (px -> uv)
uniform float uTime;     // segundos
uniform float uScan;     // fuerza de las scanlines (0..1)
uniform float uSplit;    // separacion del split RGB en px
uniform float uGlitch;   // desplazamiento maximo de las bandas en px
uniform float uFlicker;  // chispas + barrido + parpadeo (0..1)
uniform float uAlpha;    // opacidad del holograma (0..1)
uniform float uTint;     // lavado cian en las sombras (0..1)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

float hash(vec2 p)
{
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main()
{
        float row  = floor(gl_FragCoord.y);
        float tick = floor(uTime * 7.0);          // las bandas saltan ~7 veces/s

        // ---- 1) BANDAS DE GLITCH ----
        float band = floor(row / 8.0);
        float seed = hash(vec2(band * 0.317, tick));
        float shift = 0.0;

        if(seed > 0.70)                            // ~30% de las bandas activas
                shift = (hash(vec2(band, tick + 11.0)) - 0.5) * 2.0 * uGlitch;

        // clamp para no salirse del sprite en la textura (evita sangrar
        // a los sprites vecinos de la texture page)
        vec2 minUV = vec2(0.5) * uTexel;
        vec2 maxUV = vec2(1.0) - vec2(0.5) * uTexel;

        vec2 uv = clamp(v_vTexcoord + vec2(shift * uTexel.x, 0.0), minUV, maxUV);

        // ---- 2) SPLIT RGB ----
        float sp = uSplit * uTexel.x;
        vec3 rgb;
        rgb.r = texture2D(gm_BaseTexture, clamp(uv - vec2(sp, 0.0), minUV, maxUV)).r;
        rgb.g = texture2D(gm_BaseTexture, uv).g;
        rgb.b = texture2D(gm_BaseTexture, clamp(uv + vec2(sp, 0.0), minUV, maxUV)).b;

        vec4 colour = vec4(rgb, texture2D(gm_BaseTexture, uv).a);

        // ---- 3) PALETTE SWAP (identico a shd_colour) ----
        for(int i = 0; i < u_ColourCount; i++)
        {
                vec4 cmp = vec4(u_Pattern[i*4], u_Pattern[i*4+1], u_Pattern[i*4+2], u_Pattern[i*4+3]);

                if(abs(colour.r - cmp.r) < 0.01 && abs(colour.g - cmp.g) < 0.01
                && abs(colour.b - cmp.b) < 0.01 && abs(colour.a - cmp.a) < 0.01)
                {
                        colour = vec4(u_Replacements[i*4], u_Replacements[i*4+1], u_Replacements[i*4+2], u_Replacements[i*4+3]);
                        break;
                }
        }

        // ---- 4) SCANLINES: cada 2 px de pantalla ----
        float scan = 1.0 - uScan * mod(row, 2.0);

        // ---- 5) BARRIDO: barra clara que baja cada 2.5 s ----
        float sweep = fract(uTime * 0.4);
        float bar   = fract((gl_FragCoord.y / 270.0) - sweep);
        float sd    = (bar - 0.5) * 14.0;
        float sweepGlow = exp(-sd * sd) * 0.35;

        // ---- 6) NIEVE DIGITAL: chispas de 1 px (~12 Hz) ----
        float t12   = floor(uTime * 12.0);
        float spark = step(0.972, hash(floor(gl_FragCoord.xy) + vec2(t12 * 13.7, t12 * 7.3)));

        // ---- 7) PARPADEO global suave ----
        float flick = 1.0 + (hash(vec2(t12, 3.7)) - 0.5) * uFlicker * 0.6;

        // ---- componer ----
        float lum = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
        vec3  c   = colour.rgb * scan * flick + sweepGlow * uFlicker * colour.a;
        c = mix(c, vec3(0.80, 1.00, 1.00), spark * uFlicker * colour.a);
        c += vec3(0.35, 0.85, 1.00) * uTint * (1.0 - lum) * colour.a;  // cian en sombras
        c = min(c, vec3(1.0));

        gl_FragColor = vec4(c, colour.a * uAlpha) * v_vColour;
}
