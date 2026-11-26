precision highp float;
precision highp int;

// =====================================================================
//  shd_amy_cyber - AMY CYBER HOLOGRAM (v82)
//
//  Es el shd_colour (palette swap) de siempre + el overlay holograma
//  cyber ENCIMA, en un solo shader (GM solo permite un fragment shader
//  a la vez, asi que el palette swap va aqui dentro para no romper las
//  paletas del juego):
//   1. BANDAS DE GLITCH: franjas horizontales que se desplazan a los
//      lados al azar (~30% de las bandas, salta ~7 veces por segundo).
//   2. SPLIT RGB: separacion rojo/cian de los bordes (fringing).
//   3. PALETTE SWAP: identico al shd_colour (u_Pattern/u_Replacements).
//   4. SCANLINES: cada 2 px de pantalla se oscurece una linea.
//   5. BARRIDO: una barra clara que recorre la pantalla cada 2.5 s.
//   6. NIEVE DIGITAL: chispas blancas/cian de 1 px (pantalla).
//   7. PARPADEO: variacion suave del brillo global.
//   ---- nuevo en v82 ----
//   8. CONTORNO LUMINOSO: la linea de pixeles del borde del cuerpo se
//      pinta cian claro (mira los 4 vecinos).
//   9. DISOLUCION DE LOS PIES: de abajo hacia arriba el cuerpo se
//      deshace en bloques de 2x2 px (unos son huecos, otros DATOS).
//  10. REJILLA HOLOGRAFICA + LINEAS DE DATOS que suben por el cuerpo.
//  MODO SILUETA (uSolid = 1): color plano con la alpha del sprite. Lo
//  usa scr_amy_cyber_halo para el glow exterior.
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

// ---- v82 ----
uniform float uSolid;     // 1 = modo SILUETA (glow exterior)
uniform vec3  uHaloCol;   // color de la silueta
uniform float uGlow;      // contorno luminoso del borde (0..1)
uniform float uDissolve;  // los pies se deshacen en bloques de 2x2 px (0..1)
uniform float uGrid;      // rejilla holografica (0..1)
uniform float uStream;    // lineas de datos que suben (0..1)
uniform vec4  uBody;      // (ancho, alto, bbox_top, bbox_bottom) del sprite en px
uniform float uRectOK;   // 1 = uRect es valido (mismo valor que en el vertex shader)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vLocal;    // 0..1 dentro de la caja del sprite (y = 1 en los pies)

float hash(vec2 p)
{
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main()
{
        // ---- MODO SILUETA (glow exterior, v82) ----
        if(uSolid > 0.5)
        {
                float ha = texture2D(gm_BaseTexture, v_vTexcoord).a;
                gl_FragColor = vec4(uHaloCol, ha * uAlpha) * v_vColour;
                return;
        }

        float row  = floor(gl_FragCoord.y);
        float tick = floor(uTime * 7.0);          // las bandas saltan ~7 veces/s
        float t12  = floor(uTime * 12.0);         // chispas / parpadeo
        float t3   = floor(uTime * 3.0);          // bloques de la disolucion

        // ---- 1) BANDAS DE GLITCH ----
        float band = floor(row / 8.0);
        float seed = hash(vec2(band * 0.317, tick));
        float shift = 0.0;

        if(seed > 0.70)                            // ~30% de las bandas activas
                shift = (hash(vec2(band, tick + 11.0)) - 0.5) * 2.0 * uGlitch;

        // clamp para no salirse de la texture page
        vec2 minUV = vec2(0.5) * uTexel;
        vec2 maxUV = vec2(1.0) - vec2(0.5) * uTexel;

        vec2 uv = clamp(v_vTexcoord + vec2(shift * uTexel.x, 0.0), minUV, maxUV);

        // ---- 2) SPLIT RGB ----
        float sp = uSplit * uTexel.x;
        vec4 base = texture2D(gm_BaseTexture, uv);
        vec3 rgb;
        rgb.r = texture2D(gm_BaseTexture, clamp(uv - vec2(sp, 0.0), minUV, maxUV)).r;
        rgb.g = base.g;
        rgb.b = texture2D(gm_BaseTexture, clamp(uv + vec2(sp, 0.0), minUV, maxUV)).b;

        vec4 colour = vec4(rgb, base.a);

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
        float spark = step(0.972, hash(floor(gl_FragCoord.xy) + vec2(t12 * 13.7, t12 * 7.3)));

        // ---- 7) PARPADEO global suave ----
        float flick = 1.0 + (hash(vec2(t12, 3.7)) - 0.5) * uFlicker * 0.6;

        // ---- 8) CONTORNO LUMINOSO (v82) ----
        // Pixel opaco con algun vecino transparente = borde del cuerpo.
        // Solo ilumina pixeles que YA son del sprite: nunca dibuja fuera.
        float solid = step(0.35, colour.a);
        float aL = texture2D(gm_BaseTexture, uv - vec2(uTexel.x, 0.0)).a;
        float aR = texture2D(gm_BaseTexture, uv + vec2(uTexel.x, 0.0)).a;
        float aU = texture2D(gm_BaseTexture, uv - vec2(0.0, uTexel.y)).a;
        float aD = texture2D(gm_BaseTexture, uv + vec2(0.0, uTexel.y)).a;
        float nbMin = min(min(aL, aR), min(aU, aD));
        float rim   = solid * (1.0 - step(0.35, nbMin));

        // ---- 9) DISOLUCION DE LOS PIES (v82) ----
        // v_vLocal solo es fiable si el vertex shader recibio la caja del
        // sprite (uRectOK); si no, estos efectos quedan en 0.
        // La zona es el 45% inferior del CUERPO (bbox), no de la caja: los
        // sprites del juego traen margenes transparentes por debajo de los
        // pies. Los bloques cortados son huecos salvo la franja baja, que
        // son pixeles de DATOS (cian claro) dentro de la silueta.
        float ok  = uRectOK;
        vec2  spx = v_vLocal * uBody.xy;                 // px dentro del sprite
        float bh = max(uBody.w - uBody.z, 1.0);          // alto visible (bbox)
        float fy = (spx.y - (uBody.w - bh * 0.45)) / (bh * 0.45);
        float foot = clamp(fy, 0.0, 1.0);
        foot = foot * foot * ok;

        float dn   = hash(floor(spx / 2.0) * 0.173 + vec2(t3 * 0.37, t3 * 0.91));
        float dAmt = foot * uDissolve * (0.75 + 0.25 * flick);

        if(dAmt > 0.001)
        {
                float cut = step(dn, dAmt);

                if(cut > 0.5)
                {
                        if(dn < dAmt * 0.45 && solid > 0.5)
                                colour = vec4(0.70, 1.00, 1.00, 1.0);
                        else
                                discard;
                }
        }

        // ---- 10) REJILLA + LINEAS DE DATOS (v82) ----
        vec2  g8    = fract(spx / 8.0);
        float grid  = (step(g8.x, 0.14) + step(g8.y, 0.14)) * ok;
        float colId = floor(spx.x / 4.0);
        float sOn   = step(0.55, hash(vec2(colId, floor(uTime * 0.5))));
        float sPos  = fract(uTime * (0.20 + 0.35 * hash(vec2(colId, 5.0))) + hash(vec2(colId, 9.0)));
        float sD    = (1.0 - v_vLocal.y) - sPos;         // sube desde los pies
        float stream = exp(-sD * sD * 700.0) * sOn * ok;

        // ---- componer ----
        float lum = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
        vec3  c   = colour.rgb * scan * flick + sweepGlow * uFlicker * colour.a;
        c = mix(c, vec3(0.80, 1.00, 1.00), spark * uFlicker * colour.a);
        c += vec3(0.35, 0.85, 1.00) * uTint * (1.0 - lum) * colour.a;  // cian en sombras
        c = mix(c, vec3(0.72, 1.00, 1.00), rim * uGlow);                // contorno (v82)
        c += vec3(0.40, 0.90, 1.00) * rim * uGlow * 0.35;               // brillo anadido: el borde se lee como neon
        c += vec3(0.35, 0.85, 1.00) * (grid * uGrid * 0.5 + stream * uStream * 0.6) * colour.a;
        c = min(c, vec3(1.0));

        gl_FragColor = vec4(c, colour.a * uAlpha) * v_vColour;
}
